// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/oracle/IPriceOracle.sol";
import "../token/SyntheXToken.sol";

/**
 * @title SyntheX Storage Contract
 * @notice Stores all the data for SyntheX main contract
 * @dev This contract is used to store all the data for SyntheX main contract
 * @dev SyntheX is upgradable
 */
abstract contract SyntheXStorage {
    /// @notice System contract address
    System public system;

    /// @notice Price oracle contract address
    IPriceOracle public priceOracle;

    /// @notice Reward token contract address
    IERC20 public rewardToken;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Safe-Minimum collateral ratio. Debt cannot be issued if collateral ratio is below this value. 1e18 = 100%
    uint256 public safeCRatio;

    uint256 public constant BASIS_POINTS = 10000e18;
    uint256 public constant MIN_C_RATIO = 10000e18;

    /// @notice RewardToken initial index
    uint256 public constant rewardInitialIndex = 1e36;

    /// @notice Pools the user has entered into
    mapping(address => address[]) public accountPools;

    /// @notice Collaterals the user has deposited
    mapping(address => address[]) public accountCollaterals;

    /// @notice Collateral asset addresses. User => Collateral => Balance
    mapping(address => mapping(address => uint256)) public accountCollateralBalance;

    /// @notice Market data structure. Compatible with both collateral market and trading pool
    struct Market {
        // If market is enabled
        bool isEnabled;
        // Market's volatility index, in basis points 
        uint256 volatilityRatio;
        // Checks in account has entered the market
        mapping(address => bool) accountMembership;
    }

    /// @notice Mapping from pool address to pool data
    mapping(address => Market) public tradingPools;

    /// @notice Mapping from collateral asset address to collateral data
    mapping(address => Market) public collaterals;

    struct CollateralSupply {
        uint256 maxDeposits;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 maxWithdraw;
        uint256 totalDeposits;
    }

    /// @notice Mapping from collateral asset address to collateral supply and cap data
    mapping(address => CollateralSupply) public collateralSupplies;

    struct AccountLiquidity {
        uint totalCollateral;
        uint totalDebt;
    }

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

    uint256[50] private __gap;
}