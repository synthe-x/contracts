// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ExchangeStorage.sol"; 
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// contract PoolInterface
// {
//     function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) returns uint;
//     function withdraw(address asset, uint256 amount, address to) returns uint;
//     function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) returns uint;
//     function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) returns uint;
// }

abstract contract BaseExchange is ExchangeStorage {
    using SafeMathUpgradeable for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */
    event MarginEnabled(address token, address cToken);

    event OrderExecuted(bytes32 orderId, address taker, uint fillAmount);

    event OrderCancelled(bytes32 orderId);

    event MinTokenAmountSet(address token, uint amount);

    event FeesSet(uint makerFee, uint takerFee);

    // IPool pool = IPool(0x5F6470D65d82C4fCFd5b7245D76A9011158ad142);
    // PoolInterface pool = PoolInterface(0x5F6470D65d82C4fCFd5b7245D76A9011158ad142);

    /* -------------------------------------------------------------------------- */
    /*                                 Data types                                 */
    /* -------------------------------------------------------------------------- */
    enum OrderType {
        BUY,
        SELL,
        LONG,
        SHORT
    }

    struct Order {
        address maker;
        address token0;
        address token1;
        uint256 amount;
        OrderType orderType;
        uint32 salt;
        uint176 exchangeRate;
        uint32 borrowLimit;
        uint8 loops;
    }

    /* -------------------------------------------------------------------------- */
    /*                             Internal Functions                             */
    /* -------------------------------------------------------------------------- */
    function exchangeInternal(
        Order memory order,
        address taker,
        uint token0amount
    ) internal {
        // set buyer and seller as if order is BUY
        address buyer = order.maker;
        address seller = taker;

        // if SELL, swap buyer and seller
        if (
            order.orderType == OrderType.SELL ||
            order.orderType == OrderType.SHORT
        ) {
            seller = order.maker;
            buyer = taker;
        }

        // CASE : 1 BTC -> 10000 USDC
        // maker: 0.9 BTC // 10% maker fee
        // taket: 8000 USDC // 20% taker fee
        uint256 calculatedMakerFee = token0amount.mul(makerFee).div(10 ** 18); // 0.1 BTC
        uint256 exchangeT0Amount = token0amount.sub(calculatedMakerFee); // 0.9 BTC

        uint256 token1Amount = token0amount
            .mul(uint256(order.exchangeRate))
            .div(10 ** 18); // 10000 USDC
        uint256 calculatedTakerFee = token1Amount.mul(takerFee).div(1e18); // 2000 USDC
        uint256 exchangeT1Amount = token1Amount.sub(calculatedTakerFee); // 8000 USDC

        IERC20Upgradeable(order.token0).transferFrom(
            seller,
            buyer,
            exchangeT0Amount
        );
        IERC20Upgradeable(order.token0).transferFrom(
            seller,
            address(this),
            calculatedMakerFee
        );
        IERC20Upgradeable(order.token1).transferFrom(
            buyer,
            seller,
            exchangeT1Amount
        );
        IERC20Upgradeable(order.token1).transferFrom(
            buyer,
            address(this),
            calculatedTakerFee
        );

        // actual transfer
        // IERC20Upgradeable(order.token0).transferFrom(seller, buyer, token0amount);
        // IERC20Upgradeable(order.token1).transferFrom(buyer, seller, token0amount.mul(order.exchangeRate).div(10**18));
    }

    function exchangeInternalClose(
        Order memory order,
        address taker,
        uint token0amount
    ) internal {
        // set buyer and seller as if order is BUY
        address buyer = order.maker;
        address seller = taker;

        // if SELL, swap buyer and seller
        if (
            order.orderType == OrderType.BUY ||
            order.orderType == OrderType.LONG
        ) {
            seller = order.maker;
            buyer = taker;
        }

        // CASE : 1 BTC -> 10000 USDC
        // maker: 0.9 BTC // 10% maker fee
        // taket: 8000 USDC // 20% taker fee
        uint256 calculatedMakerFee = token0amount.mul(makerFee).div(10 ** 18); // 0.1 BTC
        uint256 exchangeT0Amount = token0amount.sub(calculatedMakerFee); // 0.9 BTC

        uint256 token1Amount = token0amount
            .mul(uint256(order.exchangeRate))
            .div(10 ** 18); // 10000 USDC
        uint256 calculatedTakerFee = token1Amount.mul(takerFee).div(1e18); // 2000 USDC
        uint256 exchangeT1Amount = token1Amount.sub(calculatedTakerFee); // 8000 USDC
        console.log("token0Amount", token0amount);
        IERC20Upgradeable(order.token0).transferFrom(
            seller,
            buyer,
            exchangeT0Amount
        );
        IERC20Upgradeable(order.token0).transferFrom(
            seller,
            address(this),
            calculatedMakerFee
        );
        IERC20Upgradeable(order.token1).transferFrom(
            buyer,
            seller,
            exchangeT1Amount
        );
        IERC20Upgradeable(order.token1).transferFrom(
            buyer,
            address(this),
            calculatedTakerFee
        );

        // actual transfer
        // IERC20Upgradeable(order.token0).transferFrom(seller, buyer, token0amount);
        // IERC20Upgradeable(order.token1).transferFrom(buyer, seller, token0amount.mul(order.exchangeRate).div(10**18));
    }

    // function leverageInternal(
    //     LendingMarket ctoken0,
    //     LendingMarket ctoken1,
    //     uint amount0,
    //     Order memory order
    // ) internal {
    //     // token 0: supply token0 -> borrow token1 -> swap token1 to token0 -> repeat
    //     // SHORT token 0: supply token1 -> borrow token0 -> swap token0 to token1 -> repeat
    //     LendingMarket supplyToken = ctoken0;
    //     uint supplyAmount = amount0;
    //     LendingMarket borrowToken = ctoken1;
    //     uint borrowAmount = amount0.mul(order.exchangeRate).div(10 ** 18);
    //     if (order.orderType == OrderType.SHORT) {
    //         supplyToken = ctoken1;
    //         supplyAmount = amount0.mul(order.exchangeRate).div(10 ** 18);
    //         borrowToken = ctoken0;
    //         borrowAmount = amount0;
    //     }
    //     supplyAmount = supplyAmount.mul(1e6).div(order.borrowLimit);
    //     // supply
    //     supplyToken.mint(order.maker, supplyAmount);
    //     // borrow
    //     borrowToken.borrow(order.maker, borrowAmount);
    //     console.log("supplyAmount", supplyAmount);
    //     console.log("borrowAmount", borrowAmount);
    // }

    /* -------------------------------------------------------------------------- */
    /*                                  Utilities                                 */
    /* -------------------------------------------------------------------------- */
    function validateOrder(Order memory order) public view returns (bool) {
        require(order.amount > 0, "OrderAmount must be greater than 0");
        require(order.exchangeRate > 0, "ExchangeRate must be greater than 0");

        if (
            order.orderType == OrderType.LONG ||
            order.orderType == OrderType.SHORT
        ) {
            require(
                order.borrowLimit > 0,
                "BorrowLimit must be greater than 0"
            );
            require(
                order.borrowLimit < 1e6,
                "borrowLimit must be less than 1e6"
            );
            require(order.loops > 0, "leverage must be greater than 0");
            require(
                address(assetToMarket[order.token0]) != address(0),
                "Margin trading not enabled"
            );
            require(
                address(assetToMarket[order.token1]) != address(0),
                "Margin trading not enabled"
            );
        }

        require(order.token0 != address(0), "Invalid token0 address");
        require(order.token1 != address(0), "Invalid token1 address");
        require(
            order.token0 != order.token1,
            "token0 and token1 must be different"
        );

        // order is not cancelled
        return true;
    }

    function scaledByBorrowLimit(
        uint amount,
        uint borrowLimit,
        uint loop
    ) public pure returns (uint) {
        for (uint i = 0; i < loop; i++) {
            amount = amount.mul(borrowLimit).div(1e6);
        }
        return amount;
    }
}