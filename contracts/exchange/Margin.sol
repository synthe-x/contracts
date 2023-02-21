// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

import "../system/System.sol";
import "./position/CrossPosition.sol";
import "./position/IsolatedPosition.sol";
import "../storage/MarginStorage.sol";
import "../libraries/PriceConvertor.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "hardhat/console.sol";

contract Margin is
    MarginStorage,
    IFlashLoanSimpleReceiver,
    EIP712,
    Multicall,
    ReentrancyGuard
{
    using SafeMathUpgradeable for uint;
    using MathUpgradeable for uint;
    using PriceConvertor for uint;
    using SafeERC20 for IERC20;

    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    IPool public immutable override POOL;

    constructor(address poolAddressProvider) EIP712("zexe", "1") {
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

    function createIsolatedPosition(address token0, address token1) external {
        require(
            isolatedPosition[
                keccak256(abi.encodePacked(msg.sender, token0, token1))
            ] == address(0),
            "Already created"
        );
        isolatedPosition[
            keccak256(abi.encodePacked(msg.sender, token0, token1))
        ] = Create2.deploy(
            0,
            keccak256(abi.encodePacked(msg.sender)),
            abi.encodePacked(
                type(IsolatedPosition).creationCode,
                abi.encode(msg.sender, address(this), token0, token1)
            )
        );
    }

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

            if (orders[i].action == ActionType.OPEN) {
                if (
                    orders[i].token0 != tokenFrom || orders[i].token1 != tokenTo
                ) {
                    continue;
                }
                amountFilled = openPosition(orders[i], signatures[i], amount);
                amount = amount.sub(amountFilled);
            } else {
                if (
                    orders[i].token1 != tokenFrom || orders[i].token0 != tokenTo
                ) {
                    continue;
                }
                amountFilled = closePosition(orders[i], signatures[i], amount);
                amount = amount.sub(amountFilled);
                console.log(amountFilled, i);
            }
        }
    }

    function openPosition(
        Order memory order,
        bytes memory signature,
        uint amountToFill // leveraged amount in token0
    ) internal returns (uint) {
        Vars_Position memory vars;
        vars.orderId = verifyOrderHash(order, signature);
        validateOpenOrder(order);
        OrderData storage _orderData = orderData[vars.orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        amountToFill = amountToFill.min(
            order.token0Amount.mul(order.leverage - 1).sub(
                orderFills[vars.orderId]
            )
        );

        // calc percentage of order to execute
        vars.perc = amountToFill.mul(1e18).div(
            order.token0Amount.mul(order.leverage - 1)
        );

        // position
        if (order.position == PositionType.ISOLATED) {
            vars.position = isolatedPosition[
                keccak256(
                    abi.encodePacked(order.maker, order.token0, order.token1)
                )
            ];
        } else if (order.position == PositionType.CROSS) {
            vars.position = crossPosition[order.maker];
        } else {
            revert("Invalid position type");
        }
        require(vars.position != address(0), "Position not created");

        // supply 1 * perc ETH to Aave
        IERC20(order.token0).safeTransferFrom(
            order.maker,
            address(this),
            order.token0Amount.mul(vars.perc).div(1e18)
        );
        IERC20(order.token0).safeApprove(
            address(POOL),
            order.token0Amount.mul(vars.perc).div(1e18)
        );
        POOL.supply(
            order.token0,
            order.token0Amount.mul(vars.perc).div(1e18),
            vars.position,
            0
        );

        // flash borrow 9000 * perc USDC from Aave
        POOL.flashLoanSimple(
            address(this),
            order.token0,
            order.token0Amount.mul(order.leverage - 1).mul(vars.perc).div(1e18),
            abi.encode(
                ActionType.OPEN,
                vars.position,
                msg.sender,
                order.token1,
                order.price,
                0
            ),
            0
        );

        orderFills[vars.orderId] = orderFills[vars.orderId].add(amountToFill);

        emit OpenPosition(
            vars.position,
            msg.sender,
            order.token0,
            order.token1,
            order.price,
            amountToFill
        );

        return amountToFill;
    }

    function closePosition(
        Order memory order,
        bytes memory signature,
        uint amountToFill // token1 amount to fill
    ) internal returns (uint) {
        Vars_Position memory vars;
        vars.orderId = verifyOrderHash(order, signature);
        validateCloseOrder(order);
        OrderData storage _orderData = orderData[vars.orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        amountToFill = amountToFill.min(
            order.token1Amount.sub(orderFills[vars.orderId])
        );

        // calc percentage of order to execute
        vars.perc = amountToFill.mul(1e18).div(order.token1Amount);

        // position

        if (order.position == PositionType.ISOLATED) {
            vars.position = isolatedPosition[
                keccak256(
                    abi.encodePacked(order.maker, order.token0, order.token1)
                )
            ];
        } else if (order.position == PositionType.CROSS) {
            vars.position = crossPosition[order.maker];
        } else {
            revert("Invalid position type");
        }
        require(vars.position != address(0), "Position not created");

        // flash borrow 9000 * perc USDC from Aave
        POOL.flashLoanSimple(
            address(this),
            order.token1,
            order.token1Amount.mul(vars.perc).div(1e18),
            abi.encode(
                ActionType.CLOSE,
                vars.position,
                msg.sender,
                order.token0,
                order.price,
                order.token0Amount
            ),
            0
        );

        orderFills[vars.orderId] = orderFills[vars.orderId].add(amountToFill);

        emit ClosePosition(
            order.maker,
            msg.sender,
            order.token0,
            order.token1,
            order.price,
            amountToFill
        );

        return amountToFill;
    }

    function executeOperation(
        address token,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(initiator == address(this), "Unauthorized");
        require(msg.sender == address(POOL), "Unauthorized");

        VarsHandler memory vars;
        address _token;
        uint _amount;
        ActionType action;
        (action, vars.position, vars.taker, _token, vars.price, _amount) = abi
            .decode(
                params,
                (ActionType, address, address, address, uint, uint)
            );
        vars.premium = premium;

        if (action == ActionType.OPEN) {
            // Get price of token0 and token1
            address[] memory tokens = new address[](2);
            tokens[0] = _token;
            tokens[1] = token;
            vars.prices = IPriceOracle(ADDRESSES_PROVIDER.getPriceOracle())
                .getAssetsPrices(tokens);

            // Set vars
            vars.token0 = token;
            vars.token1 = _token;
            vars.token0Amount = amount;
            vars.token1Amount = amount.t1t2(vars.prices[1], vars.prices[0]);

            // Handle open position
            return openHandler(vars);
        } else if (action == ActionType.CLOSE) {
            // Set vars
            address[] memory tokens = new address[](2);
            tokens[0] = _token; // token0
            tokens[1] = token; // token1
            vars.prices = IPriceOracle(ADDRESSES_PROVIDER.getPriceOracle())
                .getAssetsPrices(tokens);

            vars.token0 = _token;
            vars.token1 = token;
            vars.token0Amount = amount.t1t2(vars.prices[1], vars.prices[0]); //_amount;
            vars.token1Amount = amount;

            // Handle close position
            return closeHandler(vars);
        } else {
            return false;
        }
    }

    function openHandler(VarsHandler memory vars) internal returns (bool) {
        // supply to aave
        IERC20(vars.token0).safeApprove(
            address(POOL),
            vars.token0Amount.sub(vars.premium)
        );
        POOL.supply(
            vars.token0,
            vars.token0Amount.sub(vars.premium),
            vars.position,
            0
        );

        // borrow from aave
        CrossPosition(vars.position).borrowAndTransfer(
            POOL,
            vars.token1,
            vars.token1Amount,
            address(this)
        );

        // exchange
        // token1 from this to taker
        IERC20(vars.token1).safeTransfer(vars.taker, vars.token1Amount);
        // token0 from taker to this
        IERC20(vars.token0).safeTransferFrom(
            vars.taker,
            address(this),
            vars.token0Amount
        );

        // repay flashloan
        IERC20(vars.token0).safeApprove(
            address(POOL),
            vars.token0Amount.add(vars.premium)
        );

        return true;
    }

    function closeHandler(VarsHandler memory vars) internal returns (bool) {
        // repay borrowed amount
        IERC20(vars.token1).safeApprove(address(POOL), vars.token1Amount);
        require(
            POOL.repay(
                vars.token1,
                vars.token1Amount.sub(vars.premium),
                2,
                vars.position
            ) == vars.token1Amount.sub(vars.premium),
            "Repay failed"
        );
        console.log("premium", vars.premium);
        // withdraw collateral
        require(
            CrossPosition(vars.position).withdrawAndTransfer(
                POOL,
                vars.token0,
                vars.token0Amount,
                address(this)
            ) == vars.token0Amount,
            "Withdraw failed"
        );

        // exchange
        // token0 from this to taker
        IERC20(vars.token0).safeTransfer(vars.taker, vars.token0Amount);
        // token1 from taker to this
        IERC20(vars.token1).safeTransferFrom(
            vars.taker,
            address(this),
            vars.token1Amount
        );

        // repay token1 flashloan
        IERC20(vars.token1).safeIncreaseAllowance(
            address(POOL),
            vars.token1Amount.add(vars.premium) //1000+10
        );

        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Cancel Order                                 */
    /* -------------------------------------------------------------------------- */
    function cancelOrder(Order memory order, bytes memory signature) external {
        // check signature
        bytes32 orderId = verifyOrderHash(order, signature);
        require(validateCancelOrder(order));

        OrderData storage _orderData = orderData[orderId];
        _orderData.cancelled = true;
        emit OrderCancelled(orderId);
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */

    function verifyOrderHash(
        Order memory order,
        bytes memory signature
    ) public view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ORDER_HASH,
                    order.maker,
                    order.token0,
                    order.token1,
                    order.token0Amount,
                    order.token1Amount,
                    order.leverage,
                    order.price,
                    order.expiry,
                    uint32(order.nonce),
                    uint8(order.action),
                    uint8(order.position)
                )
            )
        );

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                order.maker,
                digest,
                signature
            ),
            "Invalid signature"
        );

        return digest;
    }

    function validateOpenOrder(
        Order memory order
    ) internal pure returns (bool) {
        // require(crossPosition[order.maker] != address(0), "CrossPosition already exists");
        require(order.token0Amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");
        require(order.leverage > 1, "Leverage must be greater than 1");
        return true;
    }

    function validateCloseOrder(
        Order memory order
    ) internal pure returns (bool) {
        // require(crossPosition[order.maker] != address(0), "CrossPosition does not exist");
        require(order.token1Amount > 0, "OrderAmount must be greater than 0");
        require(order.token0Amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");
        return true;
    }

    function validateCancelOrder(
        Order memory order
    ) internal pure returns (bool) {
        // require(crossPosition[order.maker] != address(0), "CrossPosition does not exist");
        require(order.token1Amount > 0, "OrderAmount must be greater than 0");
        require(order.token0Amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");
        return true;
    }
}
