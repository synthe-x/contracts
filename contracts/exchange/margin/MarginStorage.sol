// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "./IMargin.sol";
import "./IMarginPosition.sol";

abstract contract MarginStorage is IMargin {
    enum ActionType {
        OPEN,
        CLOSE,
        LIMIT
    }

    struct Order {
        address maker;
        address token0;
        address token1;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 leverage;
        uint256 price;
        uint256 expiry;
        uint256 nonce;
        ActionType action;
        uint256 position;
    }

    bytes32 constant ORDER_HASH =
        keccak256(
            "Order(address maker,address token0,address token1,uint256 token0Amount,uint256 token1Amount,uint256 leverage,uint256 price,uint256 expiry,uint256 nonce,uint256 action,uint256 position)"
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

    struct OrderData {
        uint248 fill;
        bool cancelled;
    }
    mapping(bytes32 => OrderData) public orderData;

    mapping(address => mapping(uint => address)) public position;
    mapping(address => uint) public totalPositions;

    uint public constant PRICE_UNIT_DECIMALS = 1e18;
    uint public constant BASIS_POINTS = 10000e18;
}
