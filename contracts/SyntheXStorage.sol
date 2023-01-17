// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceOracle.sol";
import "./token/SyntheXToken.sol";
import "./utils/AddressStorage.sol";

/**
 * @title SyntheX Storage Contract
 * @notice Stores all the data for SyntheX main contract
 * @dev This contract is used to store all the data for SyntheX main contract
 * @dev SyntheX is upgradable
 */
contract SyntheXStorage {
    /// @notice Reward token contract address
    SyntheXToken public syn;

    /// @notice Safe-Minimum collateral ratio. Debt cannot be issued if collateral ratio is below this value
    uint256 public safeCRatio;

    /// @notice RewardToken initial index
    uint256 public constant rewardInitialIndex = 1e36;

    /// @notice System contract address
    System public system;

    /// @notice Pools the user has entered into
    mapping(address => address[]) public accountPools;

    /// @notice Collaterals the user has deposited
    mapping(address => address[]) public accountCollaterals;

    /// @notice Collateral asset addresses. User => Collateral => Balance
    mapping(address => mapping(address => uint256)) public accountCollateralBalance;

    /// @notice Market data structure. Compatible with both collateral market and trading pool
    struct Market {
        bool isEnabled;
        uint256 volatilityRatio;
        mapping(address => bool) accountMembership;
    }

    struct CollateralSupply {
        uint256 maxDeposits;
        uint256 totalDeposits;
    }

    /// @notice Mapping from pool address to pool data
    mapping(address => Market) public tradingPools;

    /// @notice Mapping from collateral asset address to collateral data
    mapping(address => Market) public collaterals;

    /// @notice Mapping from collateral asset address to collateral supply and cap data
    mapping(address => CollateralSupply) public collateralSupplies;

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

    uint256[49] private __gap;
}