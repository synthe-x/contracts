// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}