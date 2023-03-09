// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// votes
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../synthex/SyntheX.sol";
import "../utils/interfaces/IStaking.sol";
import "./redeem/BaseTokenRedeemer.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

/**
 * @title Escrowed SYX
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice esSYX can only be transferred by authorized senders
 * @notice SNX tokens can be converted to esSYX for earning protocol fees/rewards (in WETH) and governance (ERC20Votes)
 * @notice Protocol rewards are distributed in esSYX tokens
 * @notice esSNX tokens can be redeemed for SYX tokens, with a lock period, unlock period and percentage unlock at release
 */
contract EscrowedSYX is ERC20Votes, ERC20Burnable, IStaking, BaseTokenRedeemer, AccessControl, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice System contract
    SyntheX public synthex;
    /// @notice Address of the rewards token
    address public REWARD_TOKEN;
    /// @notice Timestamp when the rewards period ends
    uint256 public periodFinish;
    /// @notice Reward rate per second
    uint256 public rewardRate; 
    /// @notice Rewards duration in seconds
    uint256 public rewardsDuration;
    /// @notice Last time reward was updated 
    uint256 public lastUpdateTime;
    /// @notice Reward per token
    uint256 public rewardPerTokenStored;
    /// @notice User reward per token paid
    mapping(address => uint256) public userRewardPerTokenPaid;
    /// @notice Rewards that are not yet claimed
    mapping(address => uint256) public rewards;
    // This role can transfer tokens
    bytes32 public constant AUTHORIZED_SENDER = keccak256("AUTHORIZED_SENDER");

    constructor(
        address _synthex, 
        address _TOKEN, 
        address _REWARD_TOKEN, 
        uint initialRewardsDuration,
        uint _lockPeriod,
        uint _unlockPeriod,
        uint _percUnlockAtRelease
    ) 
        ERC20("Escrowed SYX", "esSYX") 
        ERC20Permit("Escrowed SYX") 
        BaseTokenRedeemer(_TOKEN, _lockPeriod, _unlockPeriod, _percUnlockAtRelease)
    {
        synthex = SyntheX(_synthex);
        REWARD_TOKEN = _REWARD_TOKEN;
        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = initialRewardsDuration;
    }
    
    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns the last timestamp when reward distribution occured
     * @dev Returns current timestamp if its less than PeriodFinish value otherwise PeriodFinish value
     */
    function lastTimeRewardApplicable() public override view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /**
     * @notice Returns the reward per token
     */
    function rewardPerToken() public override view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    /**
     * @notice Returns the earned rewards for the given account
     */
    function earned(address account) public override view returns (uint256) {
        return balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /**
     * @notice Returns rewards for the reward duration
     */
    function getRewardForDuration() external override view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */

    function lock(uint _amount, address _receiver) external whenNotPaused {
        // transfer tokens from user to contract
        TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        // mint escrowed tokens
        _mint(_receiver, _amount);
    }

    /**
     * @notice Start unlocking of SYN tokens
     * @param _amount Amount of SYN to unlock
     */
    function startUnlock(uint _amount) external whenNotPaused {
        // burn escrowed tokens from user
        _burn(msg.sender, _amount);
        // start unlock
        _startUnlock(msg.sender, _amount);
    }

    /**
     * @notice Claim all unlocked SYN tokens
     * @param _requestIds Request IDs of unlock requests
     */
    function claimUnlocked(bytes32[] calldata _requestIds) external whenNotPaused {
        for(uint i = 0; i < _requestIds.length; i++){
            _unlockInternal(_requestIds[i]);
        }
    }

    /**
     * @notice Withdraws reward tokens
     * @dev Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
     */
    function getReward() public whenNotPaused override updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(REWARD_TOKEN).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);       
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Adds rewards to staking contract
     */
    function notifyReward(uint256 reward) external onlyL1Admin updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
          rewardRate = reward.div(rewardsDuration);
        }
        else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }
    
    /**
     * @notice Adds reward duration once previous duration is completed
     */
    function setRewardsDuration(uint256 _rewardsDuration) onlyL1Admin external {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @notice L1_ADMIN can grant MINTER_ROLE to any address
     */
    function grantRole(bytes32 role, address account) onlyL1Admin public override {
        _grantRole(role, account);
    }

    /**
     * @notice L1_ADMIN can revoke MINTER_ROLE from any address
     */
    function revokeRole(bytes32 role, address account) onlyL1Admin public override {
        _revokeRole(role, account);
    }

    /**
     * @notice Admin can update the lock period
     * @notice Lock period is the time that user must wait before they can claim their unlocked SYN
     * @notice Default lock period is 30 days. This function can be used to change the lock period in case delay/early is needed
     * @param _lockPeriod New lock period
     */
    function setLockPeriod(uint _lockPeriod) onlyL1Admin external {
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(_lockPeriod);
    }

    function pause() external onlyL2Admin {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev This function is used to unpause the contract in case of emergency
     */
    function unpause() external onlyL2Admin {
        _unpause();
    }

    /**
     * @notice Withdraw SYN from the contract
     * @param _amount Amount of SYN to withdraw
     * @dev This function is only used to withdraw extra SYN from the contract
     * @dev Reserved amount for unlock will not be withdrawn
     */
    function withdraw(uint _amount) external onlyL1Admin {
        require(_amount <= remainingQuota(), "Not enough SYN to withdraw");
        TOKEN.safeTransfer(msg.sender, _amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Modifiers                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyL2Admin() {
        require(synthex.isL2Admin(msg.sender), "Caller is not an admin");
        _;
    }

    modifier onlyL1Admin() {
        require(synthex.isL1Admin(msg.sender), "Caller is not an admin");
        _;
    }

    // ERC20 overrides
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    /**
     * @notice Sealed tokens can be transferred only by authorized senders
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override updateReward(from) updateReward(to) {
        require(
            hasRole(AUTHORIZED_SENDER, msg.sender), 
            "Not authorized to transfer"
        );
        super._transfer(from, to, amount);
    }
}