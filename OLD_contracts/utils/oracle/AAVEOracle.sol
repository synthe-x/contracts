// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IAToken.sol";
import "@aave/core-v3/contracts/interfaces/IPriceOracle.sol";

import {ATokenWrapper, SafeMath} from "../ATokenWrapper.sol";

contract AAVEOracle {
    using SafeMath for uint256;

    // underlying token address
    address underlying;
    address wrapper;

    uint underlyingDecimals;

    // lending pool address
    IPoolAddressesProvider public lendingPoolAddressesProvider;

    constructor(address _wrapper, address _underlying, address _lendingPoolAddressesProvider, uint _underlyingDecimals) {
        wrapper = _wrapper;
        underlying = _underlying;
        lendingPoolAddressesProvider = IPoolAddressesProvider(_lendingPoolAddressesProvider);
        underlyingDecimals = _underlyingDecimals;
    }

    function latestAnswer() external view returns (int256) {
        return int(IPriceOracle(lendingPoolAddressesProvider.getPriceOracle()).getAssetPrice(underlying).mul(ATokenWrapper(wrapper).exchangeRate()).div(1e18));
    }

    function decimals() external view returns (uint8) {
        return 8;
    }
}