// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "../system/System.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Spot2 is EIP712Upgradeable {
    using SafeMath for uint;
    using Math for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event OrderFilled(
        bytes32 indexed orderId,
        uint256 amountFilled,
        address taker
    );
    event OrderCancelled(bytes32 indexed orderId);

    struct OrderData {
        uint248 fill;
        bool cancelled;
    }
    mapping(bytes32 => OrderData) public orderData;
    uint public constant PRICE_UNIT_DECIMALS = 10 ** 18;

    function initialize() public initializer {
        __EIP712_init("zexe", "1");
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

    function execute(
        Order[] memory orders,
        bytes[] memory signatures,
        address tokenFrom,
        uint amount, // amount of tokenFrom
        address tokenTo
    ) external {
        for (uint i = 0; i < orders.length; i++) {
            // TODO: check order and call open/close
            uint amountFilled;
            if (amount <= 0) {
                break;
            }

            if (orders[i].token0 != tokenFrom || orders[i].token1 != tokenTo) {
                continue;
            }
            amountFilled = executeLimitOrder( signatures[i],orders[i], amount);
            amount = amount.sub(amountFilled);
        }
    }

    function executeLimitOrder(
        bytes memory signature,
        Order memory order,
        uint256 amountToFill
    ) internal returns (uint) {
        // check signature
        bytes32 orderId = verifyOrderHash(signature, order);
        require(validateOrder(order));

        OrderData storage _orderData = orderData[orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        amountToFill = amountToFill.min(order.amount.sub(_orderData.fill));
        if (amountToFill == 0) {
            return 0;
        }

        // transfer [amountToFill] token0 from taker to maker
        IERC20Upgradeable(order.token0).safeTransferFrom(
            msg.sender,
            order.maker,
            amountToFill
        );

        // transfer [amountToFill * price] token1 from maker to taker
        IERC20Upgradeable(order.token1).safeTransferFrom(
            order.maker,
            msg.sender,
            amountToFill.mul(uint256(order.price)).div(PRICE_UNIT_DECIMALS)
        );

        _orderData.fill = uint248(uint(_orderData.fill).add(amountToFill));

        emit OrderFilled(orderId, amountToFill, msg.sender);

        return amountToFill;
    }

    function cancelOrder(Order memory order, bytes memory signature) external {
        // check signature
        bytes32 orderId = verifyOrderHash(signature, order);
        require(validateOrder(order));

        OrderData storage _orderData = orderData[orderId];
        _orderData.cancelled = true;

        emit OrderCancelled(orderId);
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

    function validateOrder(Order memory order) internal pure returns (bool) {
        require(order.amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");

        require(order.token0 != address(0), "Invalid token0 address");
        require(order.token1 != address(0), "Invalid token1 address");
        require(
            order.token0 != order.token1,
            "token0 and token1 must be different"
        );
        return true;
    }
}
