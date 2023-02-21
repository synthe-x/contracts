// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

import "../system/System.sol";
import "./IMarginPosition.sol";
import "./MarginPosition.sol";
import "./SpotStorage.sol";
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

contract Spot is
    SpotStorage,
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

    address public immutable router;

    constructor(address poolAddressProvider, address _router) EIP712("zexe", "1") {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(poolAddressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        router = _router;
    }

    function createPosition(address[] memory markets) external {
        position[msg.sender][totalPositions[msg.sender]] = Create2.deploy(
                0,
                keccak256(abi.encodePacked(msg.sender)),
                abi.encodePacked(
                    type(MarginPosition).creationCode,
                    abi.encode(msg.sender, address(this), markets)
                )
            );

        totalPositions[msg.sender] = totalPositions[msg.sender].add(1);
    }

    function addMarketToPosition(uint positionId, address[] memory markets) external {
        MarginPosition(position[msg.sender][positionId]).supportTokens(markets);
    }

    function execute(
        Order[] memory orders,
        bytes[] memory signatures,
        address tokenFrom,
        uint amount, // amount of tokenFrom
        address tokenTo,
        bytes memory data
    ) external returns(uint) {
        require(orders.length == signatures.length, "Invalid input");
        require(orders.length > 0, "Invalid input");

        address taker = msg.sender;

        if(msg.sender == address(router)) {
            (taker) = abi.decode(data, (address));
            require(taker != address(0), "Invalid input");
        }

        for (uint i = 0; i < orders.length; i++) {
            if(orders[i].action == ActionType.LIMIT){
                amount = amount.sub(
                    executeLimitOrder(orders[i], signatures[i], amount)
                );
            }
            else if (
                orders[i].action == ActionType.OPEN && 
                tokenFrom == orders[i].token0 && 
                tokenTo == orders[i].token1
            ){
                amount = amount.sub(
                    openPosition(orders[i], signatures[i], taker, amount)
                );
            }
            else if (
                orders[i].action == ActionType.CLOSE && 
                tokenFrom == orders[i].token1 && 
                tokenTo == orders[i].token0
            ){
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

    function executeLimitOrder(
        Order memory order,
        bytes memory signature,
        uint256 token0AmountToFill
    ) internal returns (uint) {
        // check signature
        bytes32 orderId = verifyOrderHash(order, signature);
        validateOrder(order);

        OrderData storage _orderData = orderData[orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        token0AmountToFill = token0AmountToFill.min(order.token0Amount.sub(_orderData.fill));
        if (token0AmountToFill == 0) {
            return 0;
        }

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
            token0AmountToFill.mul(uint256(order.price)).div(PRICE_UNIT_DECIMALS)
        );

        _orderData.fill = uint248(uint(_orderData.fill).add(token0AmountToFill));

        emit LimitOrderFilled(orderId, token0AmountToFill, msg.sender);

        return token0AmountToFill;
    }

    function openPosition(
        Order memory order,
        bytes memory signature,
        address taker,
        uint token0AmountToFill // leveraged amount in token0
    ) internal returns (uint) {
        Vars_Position memory vars;

        vars.orderId = verifyOrderHash(order, signature);
        validateOrder(order);

        OrderData storage _orderData = orderData[vars.orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        token0AmountToFill = token0AmountToFill.min(
            order.token0Amount.mul(order.leverage - 1).sub(
                _orderData.fill
            )
        );

        // calc percentage of order to execute
        vars.perc = token0AmountToFill.mul(1e18).div(
            order.token0Amount.mul(order.leverage - 1)
        );

        // position
        vars.position = position[taker][order.position];
        require(vars.position != address(0), "Position not found");

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

        _orderData.fill = uint248(uint(_orderData.fill).add(token0AmountToFill));

        emit OpenPosition(
            vars.position,
            taker,
            order.token0,
            order.token1,
            order.price,
            token0AmountToFill
        );

        return token0AmountToFill;
    }

    function closePosition(
        Order memory order,
        bytes memory signature,
        address taker,
        uint token1AmountToFill // token1 amount to fill
    ) internal returns (uint) {
        Vars_Position memory vars;
        
        vars.orderId = verifyOrderHash(order, signature);
        validateOrder(order);

        OrderData storage _orderData = orderData[vars.orderId];
        require(_orderData.cancelled == false, "Order cancelled");

        token1AmountToFill = token1AmountToFill.min(
            order.token1Amount.sub(_orderData.fill)
        );

        // calc percentage of order to execute
        vars.perc = token1AmountToFill.mul(1e18).div(order.token1Amount);

        // position
        vars.position = position[taker][order.position];
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

        _orderData.fill = uint248(uint(_orderData.fill).add(token1AmountToFill));

        emit ClosePosition(
            order.maker,
            taker,
            order.token0,
            order.token1,
            order.price,
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
        (action, vars.position, vars.taker, _token, vars.price) = abi
            .decode( 
                params,
                (ActionType, address, address, address, uint)
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
            vars.token0Amount = amount.div(vars.price).mul(1e18); 
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
        validateOrder(order);

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
                    uint(order.nonce),
                    uint(order.action),
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

    function validateOrder(
        Order memory order
    ) internal view {
        require(totalPositions[order.maker] >= order.position, "Positions not found");
        require(order.token0Amount > 0, "OrderAmount must be greater than 0");
        require(order.price > 0, "ExchangeRate must be greater than 0");
        require(order.leverage >= 1, "Leverage must be greater than or equal 1");
    }
}