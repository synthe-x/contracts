// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/System.sol";
import "../debtpool/DebtPool.sol";

contract ERC20XStorage {
    // TradingPool that owns this token
    DebtPool public pool;
    // System contract
    System public system;
    /// @notice Fee charged for flash loan % in BASIS_POINTS
    uint public flashLoanFee;
    /// @notice Basis points: 1e4 * 1e18 = 100%
    uint public constant BASIS_POINTS = 10000e18;
}