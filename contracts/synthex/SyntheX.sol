// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./AddressStorage.sol";
import "./AccessControlList.sol";

import "../pool/Pool.sol";
import "./ISyntheX.sol";
import "../libraries/Errors.sol";

/**
 * @title SyntheX
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice This contract connects with debt pools to allows users to mint synthetic assets backed by collateral assets.
 * @dev Handles Reward Distribution: setPoolSpeed, claimReward
 * @dev Handle collateral: deposit/withdraw, enable/disable collateral, set collateral cap, volatility ratio
 * @dev Enable/disale trading pool, volatility ratio 
 */
contract SyntheX is ISyntheX, AccessControlList, UUPSUpgradeable, AddressStorage, PausableUpgradeable {
    /// @notice Using SafeMath for uint256 to avoid overflow/underflow
    using SafeMathUpgradeable for uint256;
    /// @notice Using SafeERC20 for ERC20 to avoid reverts
    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @notice Initialize the contract
     * @param _l0Admin The address of the L0 admin
     * @param _l1Admin The address of the L1 admin
     * @param _l2Admin The address of the L2 admin
     */
    function initialize(
        address _l0Admin, address _l1Admin, address _l2Admin
    ) public initializer {
        __AccessControl_init();
        __AccessControlList_init(_l0Admin, _l1Admin, _l2Admin);
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    ///@notice required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyL1Admin {}

    /**
     * @notice Pause the contract
     * @dev Only callable by L2 admin
     */
    function pause() public onlyL2Admin {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only callable by L2 admin
     */
    function unpause() public onlyL2Admin {
        _unpause();
    }

    function setAddress(bytes32 _key, address _value) external onlyL1Admin {
        _setAddress(_key, _value);

        emit AddressUpdated(_key, _value);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Reward Distribution                            */
    /* -------------------------------------------------------------------------- */

    function distribute(address _account, uint _totalSupply, uint _balance) external override whenNotPaused {
        address[] memory _rewardTokens = rewardTokens[msg.sender];
        _updatePoolRewardIndex(_rewardTokens, msg.sender, _totalSupply);
        _distributeAccountReward(_rewardTokens, msg.sender,  _account, _balance);
    }

    function distribute(uint _totalSupply) external override whenNotPaused {
        address[] memory _rewardTokens = rewardTokens[msg.sender];
        _updatePoolRewardIndex(_rewardTokens, msg.sender, _totalSupply);
    }

    /**
     * @dev Set the reward speed for a trading pool
     * @param _rewardToken The reward token
     * @param _pool The address of the trading pool
     * @param _speed The reward speed
     */
    function setPoolSpeed(address _rewardToken, address _pool, uint _speed, bool _addToList) virtual public onlyL2Admin {
        // update existing rewards
        address[] memory _rewardTokens = new address[](1);
        _rewardTokens[0] = _rewardToken;
        _updatePoolRewardIndex(_rewardTokens, _pool, Pool(payable(_pool)).totalSupply());
        // set speed
        rewardSpeeds[_rewardToken][_pool] = _speed;
        // add to list
        if(_addToList) {
            // override existing list
            address[] memory _rewardTokens = rewardTokens[_pool];
            // make sure it doesn't already exist
            for(uint i = 0; i < _rewardTokens.length; i++) {
                require(_rewardTokens[i] != _rewardToken, Errors.ASSET_ALREADY_ADDED);
            }
            rewardTokens[_pool].push(_rewardToken);
        }
        // emit successful event
        emit SetPoolRewardSpeed(_rewardToken, _pool, _speed); 
    }

    function removeRewardToken(address _rewardToken, address _pool) external onlyL2Admin {
        address[] memory _rewardTokens = rewardTokens[_pool];
        for(uint i = 0; i < _rewardTokens.length; i++) {
            if(_rewardTokens[i] == _rewardToken) {
                _rewardTokens[i] = _rewardTokens[_rewardTokens.length - 1];
                rewardTokens[_pool].pop();
                break;
            }
        }
    }
    
    /**
     * @notice Accrue rewards to the market
     * @param _rewardTokens The reward token
     */
    function _updatePoolRewardIndex(address[] memory _rewardTokens, address _pool, uint _totalSupply) internal {
        for(uint i = 0; i < _rewardTokens.length; i++) {
            address _rewardToken = _rewardTokens[i];
            if(_rewardToken == address(0)) return;
            PoolRewardState storage poolRewardState = rewardState[_rewardToken][_pool];
            uint rewardSpeed = rewardSpeeds[_rewardToken][_pool];
            uint deltaTimestamp = block.timestamp - poolRewardState.timestamp;
            if (deltaTimestamp > 0 && rewardSpeed > 0) {
                uint synAccrued = deltaTimestamp * rewardSpeed;
                uint ratio = _totalSupply > 0 ? synAccrued * rewardInitialIndex / _totalSupply : 0;
                poolRewardState.index = uint224(poolRewardState.index + ratio);
                poolRewardState.timestamp = uint32(block.timestamp);
            }
            else if (deltaTimestamp > 0) {
                poolRewardState.timestamp = uint32(block.timestamp);
            }
        }
    }

    /**
     * @notice Calculate reward accrued by a supplier and possibly transfer it to them
     * @param _rewardTokens The reward token
     * @param _account The address of the supplier to distribute reward to
     */
    function _distributeAccountReward(address[] memory _rewardTokens, address _pool, address _account, uint _balance) internal {
        uint[] memory accountDeltas = new uint[](_rewardTokens.length);
        uint[] memory borrowIndexes = new uint[](_rewardTokens.length);
        for(uint i = 0; i < _rewardTokens.length; i++) {
            address _rewardToken = _rewardTokens[i];
            if(_rewardToken == address(0)) return;
            // This check should be as gas efficient as possible as distributeAccountReward is called in many places.
            // - We really don't want to call an external contract as that's quite expensive.

            PoolRewardState storage poolRewardState = rewardState[_rewardToken][_pool];
            uint borrowIndex = poolRewardState.index;
            uint accountIndex = rewardIndex[_rewardToken][_pool][_account];

            // Update supplier's index to the current index since we are distributing accrued esSYX
            rewardIndex[_rewardToken][_pool][_account] = borrowIndex;

            if (accountIndex == 0 && borrowIndex >= rewardInitialIndex) {
                // Covers the case where users supplied tokens before the market's supply state index was set.
                // Rewards the user with reward accrued from the start of when supplier rewards were first
                // set for the market.
                accountIndex = rewardInitialIndex; // 1e36
            }

            // Calculate change in the cumulative sum of the esSYX per debt token accrued
            uint deltaIndex = borrowIndex.sub(accountIndex);

            // Calculate reward accrued: cTokenAmount * accruedPerCToken
            uint accountDelta = _balance * deltaIndex / 1e36;

            uint accountAccrued = rewardAccrued[_rewardToken][_account].add(accountDelta);
            rewardAccrued[_rewardToken][_account] = accountAccrued;

            accountDeltas[i] = accountDelta;
            borrowIndexes[i] = borrowIndex;
        }

        emit DistributedReward(_rewardTokens, _pool, _account, accountDeltas, borrowIndexes);
    }

    /**
     * @notice Claim all SYN accrued by the holders
     * @param _rewardTokens The address of the reward token
     * @param holder The addresses to claim esSYX for
     * @param _pools The list of markets to claim esSYX in
     */
    function claimReward(address[] memory _rewardTokens, address holder, address[] memory _pools) virtual override public {
        // Iterate through all holders and trading pools
        for (uint i = 0; i < _pools.length; i++) {
            // Iterate thru all reward tokens
            _updatePoolRewardIndex(_rewardTokens, _pools[i], Pool(payable(_pools[i])).totalSupply());
            _distributeAccountReward(_rewardTokens, _pools[i], holder, Pool(payable(_pools[i])).balanceOf(holder));
        } 
        for (uint i = 0; i < _rewardTokens.length; i++) {
            uint amount = rewardAccrued[_rewardTokens[i]][holder];
            rewardAccrued[_rewardTokens[i]][holder] = amount.sub(transferOut(_rewardTokens[i], holder, amount));
        }
    }

    /**
     * @dev Get total $SYN accrued by an account
     * @dev Only for getting dynamic reward amount in frontend. To be statically called
     */
    function getRewardsAccrued(address[] memory _rewardTokens, address holder, address[] memory _pools) virtual override public returns(uint[] memory) {
        // Iterate over all the trading pools and update the reward index and account's reward amount
        for (uint i = 0; i < _pools.length; i++) {
            // Iterate thru all reward tokens
            _updatePoolRewardIndex(_rewardTokens, _pools[i], Pool(payable(_pools[i])).totalSupply());
            _distributeAccountReward(_rewardTokens, _pools[i], holder, Pool(payable(_pools[i])).balanceOf(holder));
        }
        // Get the rewards accrued
        uint[] memory rewardsAccrued = new uint[](_rewardTokens.length); 
        for (uint i = 0; i < _rewardTokens.length; i++) {
            rewardsAccrued[i] = rewardAccrued[_rewardTokens[i]][holder];
        }
        return rewardsAccrued;
    }

    /**
     * @notice Transfer asset out to address
     * @param _asset The address of the asset
     * @param recipient The address of the recipient
     * @param _amount Amount
     * @return The amount transferred
     */
    function transferOut(address _asset, address recipient, uint _amount) internal returns(uint) {
        if(ERC20Upgradeable(_asset).balanceOf(address(this)) < _amount){
            _amount = ERC20Upgradeable(_asset).balanceOf(address(this));
        }
        ERC20Upgradeable(_asset).safeTransfer(recipient, _amount);

        return _amount;
    }
}