// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/dependencies/chainlink/AggregatorInterface.sol";

/**
 * @title Secondary oracle 
 * @notice This contract is used to get the price of a token (in usd) derived from the price of another token (in usd)
 * @notice Eg. COMP/USD, from COMP/ETH (18) and ETH/USD (8)
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
        return int(AggregatorInterface(PRIMARY_ORACLE).latestAnswer() * AggregatorInterface(SECONDARY_ORACLE).latestAnswer()) / 10**18;
    }

    function decimals() external view returns (uint8) {
        return 8;
    }
}