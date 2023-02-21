// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

import "../system/System.sol";
import {MarginPosition, IMarginPosition} from "./position/MarginPosition.sol";
import {BaseMargin} from "./BaseMargin.sol";
import "../libraries/PriceConvertor.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "hardhat/console.sol";

/**
 * @title Spot
 * @author Prasad <prasad@chainscore.finance>
 * @notice Spot trading contract. Allows users to open/close positions and limit orders for any erc20 token pairs
 */
contract Spot is
    BaseMargin,
    IFlashLoanSimpleReceiver,
    EIP712,
    Multicall,
    ReentrancyGuard
{
    using SafeMathUpgradeable for uint256;
    using PriceConvertor for uint256;
    using SafeERC20 for IERC20;

    /// @dev Order action type
    enum ActionType {
        OPEN,   // Open a leveraged position
        CLOSE,  // Close a leveraged position
        LIMIT   // Limit order
    }
    /// @dev Order struct
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
    /// @dev Order hash. Used for EIP712
    bytes32 constant ORDER_HASH =
        keccak256(
            "Order(address maker,address token0,address token1,uint256 token0Amount,uint256 token1Amount,uint256 leverage,uint256 price,uint256 expiry,uint256 nonce,uint256 action,uint256 position)"
        );

    /// @dev Emitted when a leveraged position is opened
    event OpenPosition(
        bytes32 indexed orderId,
        address taker,
        uint256 amountToFill
    );
    /// @dev Emitted when a leveraged position is closed
    event ClosePosition(
        bytes32 indexed orderId,
        address taker,
        uint256 amountToFill
    );
    /// @dev Emitted when a limit order is filled
    event LimitOrderFilled(
        bytes32 indexed orderId,
        uint256 amountFilled,
        address taker
    );
    /// @dev Emitted when a limit order is cancelled
    event OrderCancelled(bytes32 indexed orderId);

    /// @dev Order data struct. Used to store order data
    struct OrderData {
        uint248 fill;
        bool cancelled;
    }
    /// @dev Order data mapping
    mapping(bytes32 => OrderData) public orderData;

    uint256 public constant PRICE_UNIT_DECIMALS = 1e18;
    uint256 public constant BASIS_POINTS = 10000e18;

    struct VarsHandler {
        address position;
        address taker;
        address token0;
        address token1;
        uint256 price;
        uint256[] prices;
        uint256 premium;
        uint256 token0Amount;
        uint256 token1Amount;
    }

    struct VarsPosition {
        bytes32 orderId;
        address position;

    }

    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    IPool public immutable override POOL;

    address public immutable router;

    constructor(address poolAddressProvider, address _router)
        EIP712("zexe", "1")
    {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(poolAddressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        router = _router;
    }

    /**
     * Execute orders
     * @param orders Array of order structs
     * @param signatures Array of order signatures
     * @param tokenFrom Token to sell
     * @param amount Amount of tokenFrom
     * @param tokenTo Token to buy
     * @param data Data to pass to the function
     */
    function execute(
        Order[] memory orders,
        bytes[] memory signatures,
        address tokenFrom,
        uint256 amount, // amount of tokenFrom
        address tokenTo,
        bytes memory data
    ) external returns (uint256) {
        require(orders.length == signatures.length, "Invalid input");
        require(orders.length > 0, "Invalid input");

        address taker = msg.sender;

        if (msg.sender == address(router)) {
            (taker) = abi.decode(data, (address));
            require(taker != address(0), "Invalid input");
        }

        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].action == ActionType.LIMIT) {
                amount = amount.sub(
                    executeLimitOrder(orders[i], signatures[i], amount)
                );
            } else if (
                orders[i].action == ActionType.OPEN &&
                tokenFrom == orders[i].token0 &&
                tokenTo == orders[i].token1
            ) {
                amount = amount.sub(
                    openPosition(orders[i], signatures[i], taker, amount)
                );
            } else if (
                orders[i].action == ActionType.CLOSE &&
                tokenFrom == orders[i].token1 &&
                tokenTo == orders[i].token0
            ) {
                amount = amount.sub(
                    closePosition(orders[i], signatures[i], taker, amount)
                );
            }

            if (amount == 0) {
                break;
            }
        }

        return amount;
    }

    /**
     * Execute limit order
     * @param order Order struct
     * @param signature Order signature
     * @param token0AmountToFill Amount of token0 to fill
     */
    function executeLimitOrder(
        Order memory order,
        bytes memory signature,
        uint256 token0AmountToFill
    ) internal returns (uint256) {
        // check signature
        bytes32 orderId = verifyOrderHash(order, signature);
        validateOrder(order);

        // check if order is cancelled
        OrderData storage _orderData = orderData[orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        // check if order is fillable
        token0AmountToFill = fillableAmount(token0AmountToFill, order.token0Amount, _orderData.fill);
        if(token0AmountToFill == 0) return 0;

        // transfer [amountToFill] token0 from taker to maker
        IERC20(order.token0).safeTransferFrom(
            msg.sender,
            order.maker,
            token0AmountToFill
        );

        // transfer [amountToFill * price] token1 from maker to taker
        IERC20(order.token1).safeTransferFrom(
            order.maker,
            msg.sender,
            token0AmountToFill.mul(uint256(order.price)).div(
                PRICE_UNIT_DECIMALS
            )
        );

        _orderData.fill = uint248(
            uint256(_orderData.fill).add(token0AmountToFill)
        );

        emit LimitOrderFilled(orderId, token0AmountToFill, msg.sender);

        return token0AmountToFill;
    }

    function openPosition(
        Order memory order,
        bytes memory signature,
        address taker,
        uint256 token0AmountToFill // leveraged amount in token0
    ) internal returns (uint256) {
        VarsPosition memory vars;
        vars.orderId = verifyOrderHash(order, signature);
        validateOrder(order);

        OrderData storage _orderData = orderData[vars.orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        token0AmountToFill = fillableAmount(token0AmountToFill, order.token0Amount.mul(order.leverage - 1), _orderData.fill);
        if (token0AmountToFill == 0) return 0;

        // position
        vars.position = position[order.maker][order.position];
        require(vars.position != address(0), "Position not found");

        // supply intital amount of token0 to pool
        IERC20(order.token0).safeTransferFrom(
            order.maker,
            address(this),
            token0AmountToFill.div(order.leverage - 1)
        );
        IERC20(order.token0).safeApprove(
            address(POOL),
            token0AmountToFill.div(order.leverage - 1)
        );
        POOL.supply(
            order.token0,
            token0AmountToFill.div(order.leverage - 1),
            vars.position,
            0
        );

        // flash borrow leveraged amount of token1 from pool
        POOL.flashLoanSimple(
            address(this),
            order.token0,
            token0AmountToFill,
            abi.encode(
                ActionType.OPEN,
                vars.position,
                taker,
                order.token1,
                order.price
            ),
            0
        );

        _orderData.fill = uint248(
            uint256(_orderData.fill).add(token0AmountToFill)
        );

        emit OpenPosition(
            vars.orderId,
            taker,
            token0AmountToFill
        );

        return token0AmountToFill;
    }

    function closePosition(
        Order memory order,
        bytes memory signature,
        address taker,
        uint256 token1AmountToFill // token1 amount to fill
    ) internal returns (uint256) {
        VarsPosition memory vars;

        vars.orderId = verifyOrderHash(order, signature);
        validateOrder(order);

        OrderData storage _orderData = orderData[vars.orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        token1AmountToFill = fillableAmount(token1AmountToFill, order.token1Amount, _orderData.fill);

        // position
        vars.position = position[order.maker][order.position];
        require(vars.position != address(0), "Position not created");

        // flash borrow 9000 * perc USDC from Aave
        POOL.flashLoanSimple(
            address(this),
            order.token1,
            token1AmountToFill,
            abi.encode(
                ActionType.CLOSE,
                vars.position,
                taker,
                order.token0,
                order.price
            ),
            0
        );

        _orderData.fill = uint248(
            uint256(_orderData.fill).add(token1AmountToFill)
        );

        emit ClosePosition(
            vars.orderId,
            taker,
            token1AmountToFill
        );

        return token1AmountToFill;
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
        ActionType action;
        (action, vars.position, vars.taker, _token, vars.price) = abi.decode(
            params,
            (ActionType, address, address, address, uint256)
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
            vars.token0 = _token;
            vars.token1 = token;
            vars.token0Amount = amount.div(vars.price).mul(PRICE_UNIT_DECIMALS);
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
        IMarginPosition(vars.position).borrowAndTransfer(
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
        // withdraw collateral
        require(
            IMarginPosition(vars.position).withdrawAndTransfer(
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
            vars.token1Amount.add(vars.premium)
        );

        return true;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Cancel Order                                 */
    /* -------------------------------------------------------------------------- */
    function cancelOrder(Order memory order, bytes memory signature) external {
        // check signature
        bytes32 orderId = verifyOrderHash(order, signature);

        OrderData storage _orderData = orderData[orderId];
        _orderData.cancelled = true;
        emit OrderCancelled(orderId);
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */

    function verifyOrderHash(Order memory order, bytes memory signature)
        public
        view
        returns (bytes32)
    {
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
                    uint256(order.nonce),
                    uint256(order.action),
                    order.position
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

    function validateOrder(Order memory order) internal view {
        require(order.token0Amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");
        require(
            order.leverage >= 1,
            "Leverage must be greater than or equal 1"
        );
        require(
            order.expiry == 0 || order.expiry >= block.timestamp,
            "Order expired"
        );
    }

    function fillableAmount(uint amountToFill, uint totalAmount, uint alreadyFilled) internal pure returns (uint) {
        int availableAmount = int(totalAmount) - int(alreadyFilled);
        if(availableAmount < 0){
            return 0;
        }
        if(amountToFill > uint(availableAmount)){
            return uint(availableAmount);   
        }
        return amountToFill;
    }
}
