// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// import "./lending/LendingMarket.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

abstract contract ExchangeStorage {
    mapping(address => uint) public minTokenAmount;

    mapping(bytes32 => uint) public orderFills;
    mapping(bytes32 => uint) public loopFills;
    mapping(bytes32 => uint) public loops;

    mapping(address => IPool) public assetToMarket;

    uint public makerFee;
    uint public takerFee;
}