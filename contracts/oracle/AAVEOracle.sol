// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IAToken.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracle.sol";

contract AAVEOracle {
    // underlying token address
    address underlying;

    uint underlyingDecimals;

    // lending pool address
    IPoolAddressesProvider public lendingPoolAddressesProvider;

    constructor(address _underlying, address _lendingPoolAddressesProvider, uint _underlyingDecimals) {
        underlying = _underlying;
        lendingPoolAddressesProvider = IPoolAddressesProvider(_lendingPoolAddressesProvider);
        underlyingDecimals = _underlyingDecimals;
    }

    function latestAnswer() external view returns (int256) {
        return int(IPriceOracle(lendingPoolAddressesProvider.getPriceOracle()).getAssetPrice(underlying));
    }

    function decimals() external view returns (uint8) {
        return 8;
    }
}