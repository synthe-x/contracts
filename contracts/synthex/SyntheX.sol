// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./AddressStorage.sol";
import "./AccessControlList.sol";

import "../pool/Pool.sol";
import "../token/SyntheXToken.sol";
import "../utils/oracle/IPriceOracle.sol";
import "../utils/vault/FeeVault.sol";
import "./ISyntheX.sol";
import "../libraries/PriceConvertor.sol";

/**
 * @title SyntheX
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice This contract connects with debt pools to allows users to mint synthetic assets backed by collateral assets.
 * @dev Handles Reward Distribution: setPoolSpeed, claimReward
 * @dev Handle collateral: deposit/withdraw, enable/disable collateral, set collateral cap, volatility ratio
 * @dev Enable/disale trading pool, volatility ratio 
 */
contract SyntheX is ISyntheX, AccessControlList, UUPSUpgradeable, AddressStorage, ReentrancyGuardUpgradeable, PausableUpgradeable {
    /// @notice Using SafeMath for uint256 to avoid overflow/underflow
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256; 
    /// @notice for converting token prices
    using PriceConvertor for uint256; 
    /// @notice Using Math for uint256 to use min/max
    using MathUpgradeable for uint256;
    /// @notice Using SafeERC20 for ERC20 to avoid reverts
    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @notice Contract name and version
     */
    string public constant NAME = "SyntheX";
    uint public constant VERSION = 0;

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
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /* -------------------------------------------------------------------------- */
    /*                             External Functions                             */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Issue a synthetic asset
     * @param _account The address of the user
     * @param _synth The address of the synthetic asset
     * @param _amount Amount
     */
    function commitMint(address _account, address _synth, uint _amount) external override whenNotPaused {
        _synth;
        _amount;

        // update reward index for the pool
        updatePoolRewardIndex(address(rewardToken), msg.sender);
        // distribute pending reward tokens to user
        distributeAccountReward(address(rewardToken), msg.sender, _account);
    }

    /**
     * @notice Redeem a synthetic asset
     * @param _account The address of the user
     * @param _synth The address of the synthetic asset
     * @param _amount Amount
     */
    function commitBurn(address _account, address _synth, uint _amount) external override whenNotPaused {
        _synth;
        _amount;

        // update reward index for the pool 
        updatePoolRewardIndex(address(rewardToken), msg.sender);
        // distribute pending reward tokens to user
        distributeAccountReward(address(rewardToken), msg.sender, _account);
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
    function pause() public {
        require(isL2Admin(msg.sender), "SyntheX: Not authorized");
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only callable by L2 admin
     */
    function unpause() public {
        require(isL2Admin(msg.sender), "SyntheX: Not authorized");
        _unpause();
    }

    function setAddress(bytes32 _key, address _value) external onlyL1Admin {
        _setAddress(_key, _value);

        emit AddressUpdated(_key, _value);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Reward Distribution                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Update the reward token
     */
    function updateRewardToken(address _rewardToken) virtual public onlyL2Admin {
        // update reward token
        rewardToken = SyntheXToken(_rewardToken);
        // emit successful event
        emit RewardTokenAdded(_rewardToken);
    }
    
    /**
     * @dev Set the reward speed for a trading pool
     * @param _rewardToken The reward token
     * @param _tradingPool The address of the trading pool
     * @param _speed The reward speed
     */
    function setPoolSpeed(address _rewardToken, address _tradingPool, uint _speed) virtual override public onlyL2Admin {
        // update existing rewards
        updatePoolRewardIndex(_rewardToken, _tradingPool);
        // set speed
        rewardSpeeds[_rewardToken][_tradingPool] = _speed;
        // emit successful event
        emit SetPoolRewardSpeed(_rewardToken, _tradingPool, _speed);
    }
    
    /**
     * @notice Accrue rewards to the market
     * @param _rewardToken The reward token
     * @param _tradingPool The market whose reward index to update
     */
    function updatePoolRewardIndex(address _rewardToken, address _tradingPool) internal {
        if(_rewardToken == address(0)) return;
        PoolRewardState storage poolRewardState = rewardState[_rewardToken][_tradingPool];
        uint rewardSpeed = rewardSpeeds[_rewardToken][_tradingPool];
        uint deltaTimestamp = block.timestamp - poolRewardState.timestamp;
        if(deltaTimestamp == 0) return;
        if (rewardSpeed > 0) {
            uint borrowAmount = Pool(payable(_tradingPool)).totalSupply();
            uint synAccrued = deltaTimestamp * rewardSpeed;
            uint ratio = borrowAmount > 0 ? synAccrued * 1e36 / borrowAmount : 0;
            poolRewardState.index = uint224(poolRewardState.index + ratio);
            poolRewardState.timestamp = uint32(block.timestamp);
        } else {
            poolRewardState.timestamp = uint32(block.timestamp);
        }
    }

    /**
     * @notice Calculate reward accrued by a supplier and possibly transfer it to them
     * @param _rewardToken The reward token
     * @param _debtPool The market in which the supplier is interacting
     * @param _account The address of the supplier to distribute reward to
     */
    function distributeAccountReward(address _rewardToken, address _debtPool, address _account) internal {
        if(_rewardToken == address(0)) return;
        // This check should be as gas efficient as possible as distributeAccountReward is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        PoolRewardState storage poolRewardState = rewardState[_rewardToken][_debtPool];
        uint borrowIndex = poolRewardState.index;
        uint accountIndex = rewardIndex[_rewardToken][_debtPool][_account];

        // Update supplier's index to the current index since we are distributing accrued COMP
        rewardIndex[_rewardToken][_debtPool][_account] = borrowIndex;

        if (accountIndex == 0 && borrowIndex >= rewardInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with reward accrued from the start of when supplier rewards were first
            // set for the market.
            accountIndex = rewardInitialIndex; // 1e36
        }

        // Calculate change in the cumulative sum of the SYN per debt token accrued
        uint deltaIndex = borrowIndex - accountIndex;

        uint accountDebtTokens = Pool(payable(_debtPool)).balanceOf(_account);

        // Calculate reward accrued: cTokenAmount * accruedPerCToken
        uint accountDelta = accountDebtTokens * deltaIndex / 1e36;

        uint accountAccrued = rewardAccrued[_rewardToken][_account].add(accountDelta);
        rewardAccrued[_rewardToken][_account] = accountAccrued;

        emit DistributedReward(_rewardToken, _debtPool, _account, accountDelta, borrowIndex);
    }

    /**
     * @dev Claim all the SYN accrued by holder in the specified markets
     * @param _rewardToken The address of the reward token
     * @param holder The address to claim SYN for
     * @param tradingPoolsList The list of markets to claim SYN in
     * @dev We're taking a list of markets as input instead of a storing a list of them in contract
     */
    function claimReward(address _rewardToken, address holder, address[] memory tradingPoolsList) virtual override public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimReward(_rewardToken, holders, tradingPoolsList);
    }

    /**
     * @notice Claim all SYN accrued by the holders
     * @param _rewardToken The address of the reward token
     * @param holders The addresses to claim COMP for
     * @param _tradingPools The list of markets to claim COMP in
     */
    function claimReward(address _rewardToken, address[] memory holders, address[] memory _tradingPools) virtual override public {
        // Iterate through all holders and trading pools
        for (uint i = 0; i < _tradingPools.length; i++) {
            // Iterate thru all reward tokens
            updatePoolRewardIndex(_rewardToken, _tradingPools[i]);
            for (uint k = 0; k < holders.length; k++) {
                distributeAccountReward(_rewardToken, _tradingPools[i], holders[k]);
            }
        }
        for (uint j = 0; j < holders.length; j++) {
            rewardAccrued[_rewardToken][holders[j]] = rewardAccrued[_rewardToken][holders[j]].sub(transferOut(_rewardToken, holders[j], rewardAccrued[_rewardToken][holders[j]]));
        }
    }

    /**
     * @dev Get total $SYN accrued by an account
     * @dev Only for getting dynamic reward amount in frontend. To be statically called
     */
    function getRewardsAccrued(address _rewardToken, address _account, address[] memory _tradingPoolsList) virtual override public returns(uint) {
        // Iterate over all the trading pools and update the reward index and account's reward amount
        for (uint i = 0; i < _tradingPoolsList.length; i++) {
            // Iterate thru all reward tokens
            updatePoolRewardIndex(_rewardToken, _tradingPoolsList[i]);
            distributeAccountReward(_rewardToken, _tradingPoolsList[i], _account);
        }
        // Get the rewards accrued
        return rewardAccrued[_rewardToken][_account];
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