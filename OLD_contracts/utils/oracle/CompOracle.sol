// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/dependencies/chainlink/AggregatorInterface.sol";
import "../interfaces/compound/CTokenInterface.sol";
import "../interfaces/compound/CTokenInterface.sol";
import "../interfaces/compound/ComptrollerInterface.sol";

contract CompoundOracle is AggregatorInterface {
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

    function latestAnswer() public view override returns (int256) {
        // decimals = 18 + 10; so we divide by 10 ** 20 so final answer is in 8 decimals
        return
            int(
                comptroller.oracle().getUnderlyingPrice(cToken) *
                    cToken.exchangeRateStored()
            ) / (10 ** 20);
    }

    function decimals() external pure returns (uint8) {
        // 18 decimals for underlying + 10 decimals for exchange rate
        return 8;
    }

    function latestTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function latestRound() external pure override returns (uint256) {
        return 0;
    }

    function getAnswer(
        uint256 roundId
    ) external view override returns (int256) {
        return latestAnswer();
    }

    function getTimestamp(
        uint256 roundId
    ) external view override returns (uint256) {
        return latestTimestamp();
    }
}