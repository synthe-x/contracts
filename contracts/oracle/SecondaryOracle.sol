// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IChainlinkAggregator.sol";

/**
 * @title Secondary oracle 
 * @notice This contract is used to get the price of a token (in usd) derived from the price of another token (in usd)
 * @notice Eg. If we want to get the price of COMP in USD, we can use the price of COMP in ETH and the price of ETH in USD
 */
contract SecondaryOracle {
    // COMP/ETH oracle
    address PRIMARY_ORACLE;
    // ETH/USD oracle
    address SECONDARY_ORACLE;

    constructor(address _primaryOracle, address _secondaryOracle) {
        PRIMARY_ORACLE = _primaryOracle;
        SECONDARY_ORACLE = _secondaryOracle;
    }

    function latestAnswer() external view returns (int256) {
        return int(IChainlinkAggregator(PRIMARY_ORACLE).latestAnswer() * IChainlinkAggregator(SECONDARY_ORACLE).latestAnswer());
    }

    function decimals() external view returns (uint8) {
        return IChainlinkAggregator(PRIMARY_ORACLE).decimals() + IChainlinkAggregator(SECONDARY_ORACLE).decimals();
    }
}