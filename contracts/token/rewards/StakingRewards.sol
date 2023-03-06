// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../utils/interfaces/IStaking.sol";
import "../../synthex/SyntheX.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Staking Rewards contract
 * @notice Staking Rewards contract for Sealed-SYN token
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 */
contract StakingRewards is IStaking, ReentrancyGuard, Pausable {
    /// @notice SafeMath library for uint256 to avoid overflow and underflow
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // System contract
    SyntheX public synthex;
    /// @notice Address of the rewards token
    address public rewardsToken;
    /// @notice Address of the staking token
    address public stakingToken;
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
    /// @notice Total token supply (staked tokens)
    uint256 public totalSupply;
    /// @notice Staked token balance of account
    mapping(address => uint256) public balanceOf;
    
    /**
     * @notice Initializes the contract
     * @param _rewardsToken Address of the rewards token
     * @param _stakingToken Address of the staking token
     */
    constructor(
        address _rewardsToken, 
        address _stakingToken, 
        address _system,
        uint initialRewardsDuration
    ) {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = initialRewardsDuration;
        
        // Store the system contract
        synthex = SyntheX(_system);
    }

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
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply)
            );
    }

    /**
     * @notice Returns the earned rewards for the given account
     */
    function earned(address account) public override view returns (uint256) {
        return balanceOf[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
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
    /**
     * @notice Stakes tokens and updates balances of msg.sender
     * @dev Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
     */
    function stake(uint256 amount) external override nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalSupply = totalSupply.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Withdraws tokens and updates balances of msg.sender
     * @dev Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
     */
    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        totalSupply = totalSupply.sub(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        IERC20(stakingToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    /**
     * @notice Withdraws reward tokens
     * @dev Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
     */
    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
    
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(rewardsToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);       
        }
    }

    /**
     * @notice Withdraws staked token and reward tokens
     */
    function exit() override external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Adds rewards to staking contract
     */
    function notifyReward(uint256 reward) external updateReward(address(0)) {
        require(synthex.isL2Admin(msg.sender), "Caller is not an admin");
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
    function setRewardsDuration(uint256 _rewardsDuration) external {
        require(synthex.isL2Admin(msg.sender), "Caller is not an admin");
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }
}