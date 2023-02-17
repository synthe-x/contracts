// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract Margin is EIP712Upgradeable {

    // function initialize() public initializer {
    //     __EIP712_init("zexe", "1");
    // }

    // struct Order {
    //     address maker;
    //     address token0;
    //     address token1;
    //     uint256 amount;
    //     uint16 leverage; // <=1 : limit, > 1 : leverage
    //     uint128 price;
    //     uint64 expiry;
    //     uint48 nonce;
    // }
    
    // function _executeLimitOrder(
    //     bytes memory signature,
    //     Order memory order,
    //     uint256 amountToFill
    // ) internal returns (uint) {
    //     // require(order.leverage <= 1, "leverage must be <= 1");
    //     // check signature
    //     bytes32 orderId = verifyOrderHash(signature, order);
    //     require(validateOrder(order));

    //     // Fill Amount
    //     uint alreadyFilledAmount = orderFills[orderId];
    //     amountToFill = amountToFill.min(order.amount.sub(alreadyFilledAmount));
    //     if (amountToFill == 0) {
    //         return 0;
    //     }

    //     // set buyer and seller as if order is BUY
    //     address buyer = order.maker;
    //     address seller = msg.sender;

    //     // if SELL, swap buyer and seller
    //     if (order.orderType == OrderType.SELL) {
    //         seller = order.maker;
    //         buyer = msg.sender;
    //     }

    //     // IERC20Upgradeable(order.token0).transferFrom(seller, buyer, amountToFill);
    //     // IERC20Upgradeable(order.token1).transferFrom(buyer, seller, amountToFill.mul(uint256(order.exchangeRate)).div(10**18));

    //     // calulate token1 amount based on fillamount and exchange rate

    //     exchangeInternal(order, msg.sender, amountToFill);

    //     orderFills[orderId] = alreadyFilledAmount.add(amountToFill);
    //     emit OrderExecuted(orderId, msg.sender, amountToFill);
    //     return amountToFill;
    // }


    // /* -------------------------------------------------------------------------- */
    // /*                               View Functionş                              */
    // /* -------------------------------------------------------------------------- */
    // /**
    //  * @dev Verify the order
    //  * @param signature Signature of the order
    //  * @param order Order struct
    //  */
    // function verifyOrderHash(
    //     bytes memory signature,
    //     Order memory order
    // ) public view returns (bytes32) {
    //     bytes32 digest = _hashTypedDataV4(
    //         keccak256(
    //             abi.encode(
    //                 keccak256(
    //                     "Order(address maker,address token0,address token1,uint256 amount,uint16 leverage,uint128 price,uint64 expiry,uint48 nonce)"
    //                 ),
    //                 order.maker,
    //                 order.token0,
    //                 order.token1,
    //                 order.amount,
    //                 order.leverage,
    //                 order.price,
    //                 order.expiry,
    //                 order.nonce
    //             )
    //         )
    //     );

    //     require(
    //         SignatureCheckerUpgradeable.isValidSignatureNow(
    //             order.maker,
    //             digest,
    //             signature
    //         ),
    //         "invalid signature"
    //     );

    //     return digest;
    // }

    // function validateOrder(Order memory order) public view returns (bool) {
    //     require(order.amount > 0, "OrderAmount must be greater than 0");
    //     require(order.exchangeRate > 0, "ExchangeRate must be greater than 0");

    //     if (
    //         order.leverage > 1
    //     ) {
            
    //         require(
    //             address(assetToMarket[order.token0]) != address(0),
    //             "Margin trading not enabled"
    //         );
    //         require(
    //             address(assetToMarket[order.token1]) != address(0),
    //             "Margin trading not enabled"
    //         );
    //     }

    //     require(order.token0 != address(0), "Invalid token0 address");
    //     require(order.token1 != address(0), "Invalid token1 address");
    //     require(
    //         order.token0 != order.token1,
    //         "token0 and token1 must be different"
    //     );

    //     // order is not cancelled
    //     return true;
    // }
}