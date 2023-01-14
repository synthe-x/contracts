// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'hardhat/console.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IStaking.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract StakingRewards is IStaking, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {

    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    address public rewardsToken;
    address public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate; 
    uint256 public rewardsDuration; 
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    mapping(address => uint256) private _balances;
    uint256 public constant VERSION = 1;
    
    /* ========== CONSTRUCTOR ========== */

    // constructor(address _rewardsToken, address _stakingToken) {
    //     rewardsToken = _rewardsToken;
    //     stakingToken = _stakingToken;
    // }
      constructor() {}

     function initialize(address _rewardsToken, address _stakingToken) public initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
      
         rewardsToken = _rewardsToken;
         stakingToken = _stakingToken;
         periodFinish = 0;
         rewardRate = 0;
         rewardsDuration = 7 days;
    }
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* ========== VIEWS ========== */
    // Returs total token supply
    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    //Returns staked token balance of account
    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    // returns block.timestamp if its less than PeriodFinish value otherwise PeriodFinish value
    function lastTimeRewardApplicable() public override view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // Returns Reward per token
    function rewardPerToken() public override view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    //Returns earned rewards
    function earned(address account) public override view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    // Returns rewards for the reward duration
    function getRewardForDuration() external override view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Stakes tokens and updates balances of msg.sender 
     //Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
    function stake(uint256 amount) external override nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20Upgradeable(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    //withdraws tokens and updates balances of msg.sender
    //Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20Upgradeable(stakingToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    //Withdraws reward tokens 
    //Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
      
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20Upgradeable(rewardsToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);       
        }
    }

    //Withdraws staked token and reward tokens 
    function exit() override external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Add rewards to staking contract
    function addReward(uint256 reward) external onlyOwner updateReward(address(0)) {
        IERC20Upgradeable(rewardsToken).safeTransferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= periodFinish) {
          rewardRate = reward.div(rewardsDuration);
        }
        else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = IERC20Upgradeable(rewardsToken).balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20Upgradeable(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
    
    // Adds reward duration once previous duration is completed
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    //Updates reward Per Token Stored and store reward amount AND userRewardPerTokenPaid for msg.sender
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}