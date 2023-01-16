// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceOracle.sol";
import "./token/SyntheXToken.sol";
import "./utils/AddressStorage.sol";

contract SyntheXStorage {
    SyntheXToken public syn;

    uint256 public safeCRatio;
    uint256 public compInitialIndex;

    /// @notice Address manager contract address
    AddressStorage public addressStorage;

    /**
     * @dev Pools the user has entered into
     */
    mapping(address => address[]) public accountPools;

    /**
     * @dev Collaterals the user has deposited
     */
    mapping(address => address[]) public accountCollaterals;

    /**
     * @dev Collateral asset addresses
     * User => Collateral => Balance
     */
    mapping(address => mapping(address => uint256)) public accountCollateralBalance;

    /**
     * @dev Market data structure
     * Compatible with both collateral market and trading pool
     */
    struct Market {
        bool isEnabled;
        uint256 volatilityRatio;
        mapping(address => bool) accountMembership;
    }

    struct CollateralSupply {
        uint256 maxDeposits;
        uint256 totalDeposits;
    }

    /**
     * @dev Mapping from pool address to pool data
     */
    mapping(address => Market) public tradingPools;

    /**
     * @dev Mapping from collateral asset address to collateral data
     */
    mapping(address => Market) public collaterals;

    /**
     * @dev Mapping from collateral asset address to collateral supply and cap data
     */
    mapping(address => CollateralSupply) public collateralSupplies;

    struct PoolRewardState {
        // The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;

        // The block number the index was last updated at
        uint32 timestamp;
    }
    
    /// @notice The reward tokens
    address[] public rewardTokens;

    /// @notice The speed at which SYN is distributed to the corresponding market (per second)
    mapping(address => mapping(address => uint)) public rewardSpeeds;

    /// @notice The reward market borrow state for each market
    mapping(address => mapping(address => PoolRewardState)) public rewardState;
    
    /// @notice The reward borrow index for each market for each borrower as of the last time they accrued COMP
    mapping(address => mapping(address => mapping(address => uint))) public rewardIndex;
    
    /// @notice The reward accrued but not yet transferred to each user
    mapping(address => mapping(address => uint)) public rewardAccrued;

    uint256[99] private __gap;
}