// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../utils/oracle/IPriceOracle.sol";
import "../token/SyntheXToken.sol";

/**
 * @title SyntheX Storage Contract
 * @notice Stores all the data for SyntheX main contract
 * @dev This contract is used to store all the data for SyntheX main contract
 * @dev SyntheX is upgradable
 */
abstract contract SyntheXStorage {

    mapping(address => address[]) public rewardTokens;

    /// @notice RewardToken initial index
    uint256 public constant rewardInitialIndex = 1e36;

    /// @notice Reward state for each pool
    struct PoolRewardState {
        // The market's last updated rewardIndex
        uint224 index;

        // The timestamp the index was last updated at
        uint32 timestamp;
    }

    /// @notice The speed at which reward token is distributed to the corresponding market (per second)
    mapping(address => mapping(address => uint)) public rewardSpeeds;

    /// @notice The reward market borrow state for each market
    mapping(address => mapping(address => PoolRewardState)) public rewardState;
    
    /// @notice The reward borrow index for each market for each borrower as of the last time they accrued COMP
    mapping(address => mapping(address => mapping(address => uint))) public rewardIndex;
    
    /// @notice The reward accrued but not yet transferred to each user
    mapping(address => mapping(address => uint)) public rewardAccrued;

    uint256[100] private __gap;
}