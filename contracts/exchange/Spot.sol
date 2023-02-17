// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "../system/System.sol";

// Safemath
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
// IERC20Upgradeable
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract Spot is EIP712Upgradeable {
    using SafeMath for uint;
    using Math for uint;

    System public system;
    mapping (bytes32 => uint) public orderFills;

    uint constant public PRICE_UNIT_DECIMALS = 10**18;

    function initialize(address _system) public initializer {
        __EIP712_init("zexe", "1");
        system = System(_system);
    }

    struct Order {
        address maker;
        address token0;
        address token1;
        uint256 amount;
        uint128 price;
        uint64 expiry;
        uint48 nonce;
    }
    
    function executeLimitOrder(
        bytes memory signature,
        Order memory order,
        uint256 amountToFill
    ) external returns (uint) {
        // require(order.leverage <= 1, "leverage must be <= 1");
        // check signature
        bytes32 orderId = verifyOrderHash(signature, order);
        require(validateOrder(order));

        /**
            LIMIT: SELL 0.1 BTC for USDC (0.0001)
            token0: USDC
            token1: BTC
            amount: 1000 USDC
         */
        /**
            LIMIT: BUY 0.1 BTC for USDC (10000)
            token0: BTC
            token1: USDC
            amount: 0.1 BTC
         */

        amountToFill = amountToFill.min(order.amount.sub(orderFills[orderId]));
        if (amountToFill == 0) {
            return 0;
        }

        // transfer [amountToFill] token0 from taker to maker
        IERC20Upgradeable(order.token0).transferFrom(msg.sender, order.maker, amountToFill);

        // transfer [amountToFill * price] token1 from maker to taker
        IERC20Upgradeable(order.token1).transferFrom(order.maker, msg.sender, amountToFill.mul(uint256(order.price)).div(PRICE_UNIT_DECIMALS));


        orderFills[orderId] = orderFills[orderId].add(amountToFill);
        // emit OrderExecuted(orderId, msg.sender, amountToFill);
        return amountToFill;
    }


    /* -------------------------------------------------------------------------- */
    /*                               View Functionş                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Verify the order
     * @param signature Signature of the order
     * @param order Order struct
     */
    function verifyOrderHash(
        bytes memory signature,
        Order memory order
    ) public view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Order(address maker,address token0,address token1,uint256 amount,uint128 price,uint64 expiry,uint48 nonce)"
                    ),
                    order.maker,
                    order.token0,
                    order.token1,
                    order.amount,
                    order.price,
                    order.expiry,
                    order.nonce
                )
            )
        );

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                order.maker,
                digest,
                signature
            ),
            "invalid signature"
        );

        return digest;
    }

    function validateOrder(Order memory order) public view returns (bool) {
        require(order.amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");

        require(order.token0 != address(0), "Invalid token0 address");
        require(order.token1 != address(0), "Invalid token1 address");
        require(
            order.token0 != order.token1,
            "token0 and token1 must be different"
        );

        // order is not cancelled
        return true;
    }
}