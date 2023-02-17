// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "../system/System.sol";

import "./CrossPosition.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

// safemath
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../libraries/PriceConvertor.sol";

contract Margin is IFlashLoanSimpleReceiver, EIP712 {
    using SafeMathUpgradeable for uint;
    using MathUpgradeable for uint;
    using PriceConvertor for uint;

    IPoolAddressesProvider public ADDRESSES_PROVIDER;
    IPool public POOL;

    System public system;

    mapping(address => address) public crossPosition;
    mapping(bytes32 => uint) public orderFills;

    struct Order {
        address maker;
        address token0;
        address token1;
        uint256 amount;
        uint16 leverage;
        uint128 price;
        uint64 expiry;
        uint48 nonce;
    }

    struct Params_OpenPosition {
        bytes32 orderId;
        address maker;
        address taker;
        address token1;
        uint price;
        uint perc;
        // address borrowAsset;
        // uint256 borrowAmount;
        // uint256 fee;
        // address supplyAsset;
        // address sender;
        // uint[] prices;
    }

    // (address maker, address taker, address token1, uint price)
    constructor(
        // address _system,
        address poolAddressProvider
    ) EIP712("zexe", "1") {
        // __EIP712_init("zexe", "1");
        // system = System(_system);

        ADDRESSES_PROVIDER = IPoolAddressesProvider(poolAddressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
    }

    function createCrossPosition() external {
        require(crossPosition[msg.sender] == address(0), "Already created");
        crossPosition[msg.sender] = Create2.deploy(
            0,
            keccak256(abi.encodePacked(msg.sender)),
            abi.encodePacked(
                type(CrossPosition).creationCode,
                abi.encode(msg.sender, address(this))
            )
        );
    }

    function openPosition(
        Order memory order,
        bytes memory signature,
        uint amountToFill // leveraged amount in token0
    ) external {
        Params_OpenPosition memory vars;
        vars.orderId = verifyOrderHash(signature, order);
        require(validateOrder(order));

        amountToFill = amountToFill.min(
            order.amount.mul(order.leverage - 1).sub(orderFills[vars.orderId])
        );

        // calc percentage of order to execute
        vars.perc = amountToFill.mul(1e18).div(
            order.amount.mul(order.leverage - 1)
        );

        // supply 1 * perc ETH to Aave
        IERC20(order.token0).transferFrom(order.maker, address(this), order.amount.mul(vars.perc).div(1e18));
        IERC20(order.token0).approve(address(POOL), order.amount.mul(vars.perc).div(1e18));
        POOL.supply(
            order.token0,
            order.amount.mul(vars.perc).div(1e18),
            crossPosition[order.maker],
            0
        );

        // flash borrow 9000 * perc USDC from Aave
        POOL.flashLoanSimple(
            address(this),
            order.token0,
            order.amount.mul(order.leverage - 1).mul(vars.perc).div(1e18),
            abi.encode(order.maker, msg.sender, order.token1, order.price),
            0
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(initiator == address(this), "Unauthroized");
        Params_OpenPosition memory vars;
        (vars.maker, vars.taker, vars.token1, vars.price) = abi.decode(
            params,
            (address, address, address, uint)
        );

        // supply to aave
        IERC20(asset).approve(address(POOL), amount.sub(premium));
        POOL.supply(asset, amount.sub(premium), crossPosition[vars.maker], 0);

        address[] memory tokens = new address[](2);
        tokens[0] = asset;
        tokens[1] = vars.token1;
        uint[] memory prices = IPriceOracle(ADDRESSES_PROVIDER.getPriceOracle())
            .getAssetsPrices(tokens);

        // borrow from aave
        uint borrowAmount = amount.t1t2(prices[0], prices[1]);
        CrossPosition(crossPosition[vars.maker]).borrowAndTransfer(
            POOL,
            vars.token1,
            borrowAmount,
            address(this)
        );

        // exchange
        // 9000 USDC from this to taker
        IERC20(vars.token1).transfer(vars.taker, borrowAmount);
        // 9 eth from taker to this
        IERC20(asset).transferFrom(vars.taker, address(this), amount);

        // repay flashloan
        IERC20(asset).approve(address(POOL), amount.add(premium));

        return true;
    }

    // /* -------------------------------------------------------------------------- */
    // /*                               View Functionş                              */
    // /* -------------------------------------------------------------------------- */
    // /**
    //  * @dev Verify the order
    //  * @param signature Signature of the order
    //  * @param order Order struct
    //  */
    function verifyOrderHash(
        bytes memory signature,
        Order memory order
    ) public view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Order(address maker,address token0,address token1,uint256 amount,uint16 leverage,uint128 price,uint64 expiry,uint48 nonce)"
                    ),
                    order.maker,
                    order.token0,
                    order.token1,
                    order.amount,
                    order.leverage,
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

        require(order.leverage > 1, "Leverage must be greater than 1");

        return true;
    }
}
