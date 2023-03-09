// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author SyntheX
 * @notice Defines the error messages emitted by the different contracts of SyntheX
 */
library Errors {
  string public constant CALLER_NOT_L0_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_L1_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_L2_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant COLLATERAL_NOT_ENABLED = '4'; // 'The collateral is not enabled
  string public constant ACCOUNT_ALREADY_ENTERED = '5'; // 'The account has already entered the collateral
  string public constant INSUFFICIENT_COLLATERAL = '6'; // 'The account has insufficient collateral
  string public constant ZERO_AMOUNT = '7'; // 'The amount is zero
  string public constant EXCEEDED_MAX_CAPACITY = '8'; // 'The amount exceeds the maximum capacity
  string public constant INSUFFICIENT_BALANCE = '9'; // 'The account has insufficient balance
  string public constant SYNTH_NOT_ACTIVE = '10'; // 'The synth is not enabled
  string public constant SYNTH_NOT_FOUND = '11'; // 'The synth is not enabled
  string public constant INSUFFICIENT_DEBT = '12'; // 'The account has insufficient debt'
}