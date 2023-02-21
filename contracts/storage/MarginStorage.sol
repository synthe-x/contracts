// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "../interfaces/IMargin.sol";

abstract contract MarginStorage is IMargin {
    enum ActionType {
        OPEN,
        CLOSE
    }

    enum PositionType {
        ISOLATED,
        CROSS
    }
   
    /**
     * @dev Order struct
     * @param action Action type
     * @param position Position type
     * @param maker Maker address
     * @param token0 Token0 address
     * @param token1 Token1 address
     * @param token0Amount Token0 amount : AmountToOpen for OPEN action, AmountToWithdrawAndExchange for CLOSE action
     * @param token1Amount Token1 amount : 0 for OPEN action, > 0 leveraged borrowed amount for CLOSE action
     * @param leverage Leverage
     * @param price Price of exchange
     * @param expiry Expiry timestamp
     * @param nonce Nonce
     */
    struct Order {
        address maker;
        address token0;
        address token1;
        uint256 token0Amount;
        uint256 token1Amount;
        uint16 leverage;
        uint128 price;
        uint64 expiry;
        uint32 nonce;
        ActionType action;
        PositionType position;
    }

    bytes32 constant ORDER_HASH =
        keccak256(
            "Order(address maker,address token0,address token1,uint256 token0Amount,uint256 token1Amount,uint16 leverage,uint128 price,uint64 expiry,uint32 nonce,uint8 action,uint8 position)"
        );

    struct VarsHandler {
        address position;
        address taker;
        address token0;
        address token1;
        uint price;
        uint[] prices;
        uint premium;
        uint token0Amount;
        uint token1Amount;
    }

    struct Vars_Position {
        uint256 perc;
        bytes32 orderId;
        address position;
    }
    mapping(bytes32 => OrderData) public orderData;
    mapping(address => address) public crossPosition;
    mapping(bytes32 => address) public isolatedPosition;
    mapping(bytes32 => uint) public orderFills;

    uint public constant PRICE_UNIT_DECIMALS = 1e18;
    uint public constant BASIS_POINTS = 10000e18;

    struct OrderData {
        uint248 fill;
        bool cancelled;
    }
}
