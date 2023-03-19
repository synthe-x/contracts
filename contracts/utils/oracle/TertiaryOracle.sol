// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/dependencies/chainlink/AggregatorInterface.sol";
// Safemath int
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title TertiaryOracle
 * @notice This contract is used to get the price of a token (in usd) derived from the price of another token (in usd)
 * @notice Eg. wstETH/USD, from wstETH/stETH (18), stETH/ETH (18), ETH/USD (8)
 */
contract TertiaryOracle {
    using SignedSafeMath for int;
    // wstETH/stETH oracle
    address PRIMARY_ORACLE;
    // stETH/ETH oracle
    address SECONDARY_ORACLE;
    // stETH/ETH oracle
    address TERTIARY_ORACLE;

    constructor(address _primaryOracle, address _secondaryOracle, address _tertiaryOracle) {
        PRIMARY_ORACLE = _primaryOracle;
        SECONDARY_ORACLE = _secondaryOracle;
        TERTIARY_ORACLE = _tertiaryOracle;
    }

    function latestAnswer() external view returns (int256) {
        return AggregatorInterface(PRIMARY_ORACLE).latestAnswer().mul(AggregatorInterface(SECONDARY_ORACLE).latestAnswer()).div(10**18).mul(AggregatorInterface(TERTIARY_ORACLE).latestAnswer()).div(10**18);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}