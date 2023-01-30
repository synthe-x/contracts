// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IChainlinkAggregator.sol";
import "../interfaces/compound/CTokenInterface.sol";
import "../interfaces/compound/CTokenInterface.sol";
import "../interfaces/compound/ComptrollerInterface.sol";

contract CompoundOracle is IChainlinkAggregator {
    ComptrollerInterface public comptroller;
    CTokenInterface public cToken;

    constructor(ComptrollerInterface _comptroller, CTokenInterface _cToken) {
        comptroller = _comptroller;
        cToken = _cToken;
    }

    function latestAnswer() external view override returns (int256) {
        return int(comptroller.oracle().getUnderlyingPrice(cToken) * cToken.exchangeRateStored());
    }

    function decimals() external view override returns (uint8) {
        // 18 decimals for underlying + 2 decimals for exchange rate
        return 20;
    }

    function latestTimestamp() external view returns (uint256){
        return block.timestamp;
    }
}