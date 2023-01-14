// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceOracle.sol";
import "./token/SyntheXToken.sol";
import "./utils/AddressStorage.sol";

contract SyntheXStorage {
    SyntheXToken public syn;

    uint256 public safeCRatio;
    uint256 public compInitialIndex;

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
     */
    mapping(address => mapping(address => uint)) public accountCollateralBalance;

    /**
     * @dev Market data structure
     * Compatible with both collateral market and trading pool
     */
    struct Market {
        bool isEnabled;
        uint volatilityRatio;
        mapping(address => bool) accountMembership;
    }

    /**
     * @dev Mapping from pool address to pool data
     */
    mapping(address => Market) public tradingPools;

    /**
     * @dev Mapping from collateral asset address to collateral data
     */
    mapping(address => Market) public collaterals;

    struct SynMarketState {
        // The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;

        // The block number the index was last updated at
        uint32 timestamp;
    }
    
    /// @notice The speed at which SYN is distributed to the corresponding market (per second)
    mapping(address => uint) public synRewardSpeeds;

    /// @notice The SYN market borrow state for each market
    mapping(address => SynMarketState) public synRewardState;
    
    /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
    mapping(address => mapping(address => uint)) public synBorrowerIndex;
    
    /// @notice The COMP accrued but not yet transferred to each user
    mapping(address => uint) public synAccrued;

    /// @notice Address manager contract address
    AddressStorage public addressStorage;

    uint256[99] private __gap;
}