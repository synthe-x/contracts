// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../system/System.sol";
import "../interfaces/IPriceOracle.sol";

contract DebtPoolStorage {
    /// @notice The address of the address storage contract
    System public system;

    /// @notice The address of the price oracle
    IPriceOracle public priceOracle;

    /// @notice If synth is enabled
    mapping(address => bool) public synths;
    /// @notice Fee for swapping synths in the pool (in bps)
    uint public swapFee;
    /// @notice Fee for minting synths in the pool (in bps)
    uint public mintFee;
    /// @notice Fee for burning synths in the pool (in bps)
    uint public burnFee;
    /// @notice Penalty that is added to debt when liquidating (in bps)
    uint public liquidationPenalty;
    /// @notice Fee of penalty that is send to vault (in bps)
    uint public liquidationFee;
    /// @notice Issuer allocation (of fee) in basis points
    uint public issuerAlloc;
    /// @notice Basis points constant. 10000 basis points * 1e18 = 100%
    uint public constant BASIS_POINTS = 10000e18;
    /// @notice The synth token used to pass on to vault as fee
    address public feeToken;
    /// @notice The list of synths in the pool. Needed to calculate total debt
    address[] public synthsList;


    uint256[50] private __gap;
}