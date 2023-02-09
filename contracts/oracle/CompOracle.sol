// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IChainlinkAggregator.sol";
import "../interfaces/compound/CTokenInterface.sol";
import "../interfaces/compound/CTokenInterface.sol";
import "../interfaces/compound/ComptrollerInterface.sol";

contract CompoundOracle is IChainlinkAggregator {
    ComptrollerInterface public comptroller;
    CTokenInterface public cToken;

    uint private underlyingDecimals;

    constructor(
        ComptrollerInterface _comptroller, 
        CTokenInterface _cToken,
        uint _underlyingDecimals
    ) {
        comptroller = _comptroller;
        cToken = _cToken;
        underlyingDecimals = _underlyingDecimals;
    }

    function latestAnswer() external view override returns (int256) {
        return int(comptroller.oracle().getUnderlyingPrice(cToken) * cToken.exchangeRateStored()) / (10**18);
    }

    function decimals() external view override returns (uint8) {
        // 18 decimals for underlying + 10 decimals for exchange rate
        return 18 + 10;
    }

    function latestTimestamp() external view returns (uint256){
        return block.timestamp;
    }
}