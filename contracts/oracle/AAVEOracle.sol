// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracle.sol";

contract AAVEOracle {
    // underlying token address
    address reserve;

    // lending pool address
    IPoolAddressesProvider public lendingPoolAddressesProvider;

    constructor(address _reserve, address _lendingPoolAddressesProvider) {
        reserve = _reserve;
        lendingPoolAddressesProvider = IPoolAddressesProvider(_lendingPoolAddressesProvider);
    }

    function latestAnswer() external view returns (int256) {
        return int(IPriceOracle(lendingPoolAddressesProvider.getPriceOracle()).getAssetPrice(reserve));
    }

    function decimals() external view returns (uint8) {
        return 18;
    }
}