// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PriceOracle.sol";

contract SyntheXStorage {

    event NewCollateralAsset(address indexed asset, uint256 volatilityRatio);
    event NewTradingPool(address indexed pool, uint256 volatilityRatio);
    event NewPriceOracle(address indexed oracle);

    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Issue(address indexed user, address indexed tradingPool, address indexed asset, uint256 amount);
    event Burn(address indexed user, address indexed tradingPool, address indexed asset, uint256 amount);

    event Exchange(address indexed user, address indexed tradingPool, address indexed fromAsset, address toAsset, uint256 fromAmount, uint256 toAmount);

    /**
     * @dev Price oracle contract address
     */
    PriceOracle public oracle; 

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
    mapping(address => uint) public accountCollateralBalance;

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

    /**
     * @dev Array of trading pool addresses
     */
    address[] public tradingPoolsList;
    
    /**
     * @dev Array of collateral asset addresses
     */
    address[] public collateralsList;
}