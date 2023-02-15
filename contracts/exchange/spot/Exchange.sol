// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./BaseExchange.sol";
// import "./lending/interfaces/ILever.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "hardhat/console.sol";

contract Exchange is
    BaseExchange,
    EIP712Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    // IPool public immutable pool;
    // address payable owner;
    // constructor (address _addressProvider) {
    //     ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
    //     pool = IPool(ADDRESSES_PROVIDER.getPool());
    //     owner = payable(msg.sender);
    // }

    /**
     * @dev Initialize the contract
     * @param __name Name of the contract
     * @param __version Version of the contract
     */
    function initialize(
        string memory __name,
        string memory __version,
        address _admin,
        address _pauser
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __EIP712_init(__name, __version);
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, _admin);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(PAUSER_ROLE, _pauser);

        // TEMP grant deployer role to initiate the contract
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(ADMIN_ROLE) {}

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Execute a limit order
     * @param signature Signature of the order
     * @param order Order struct
     * @param amountToFill Amount of token0 to fill
     * @return Amount of token0 filled
     */
    function _executeLimitOrder(
        bytes memory signature,
        Order memory order,
        uint256 amountToFill
    ) internal returns (uint) {
        // check signature
        bytes32 orderId = verifyOrderHash(signature, order);
        require(validateOrder(order));

        // Fill Amount
        uint alreadyFilledAmount = orderFills[orderId];
        amountToFill = amountToFill.min(order.amount.sub(alreadyFilledAmount));
        if (amountToFill == 0) {
            return 0;
        }

        // set buyer and seller as if order is BUY
        address buyer = order.maker;
        address seller = msg.sender;

        // if SELL, swap buyer and seller
        if (order.orderType == OrderType.SELL) {
            seller = order.maker;
            buyer = msg.sender;
        }

        // IERC20Upgradeable(order.token0).transferFrom(seller, buyer, amountToFill);
        // IERC20Upgradeable(order.token1).transferFrom(buyer, seller, amountToFill.mul(uint256(order.exchangeRate)).div(10**18));

        // calulate token1 amount based on fillamount and exchange rate

        exchangeInternal(order, msg.sender, amountToFill);

        orderFills[orderId] = alreadyFilledAmount.add(amountToFill);
        emit OrderExecuted(orderId, msg.sender, amountToFill);
        return amountToFill;
    }

    /**
     * @dev Execute multiple limit orders as per token0 amount
     * @param signatures Signatures of the orders
     * @param orders Order structs
     * @param token0AmountToFill Amount of token0 to fill
     */
    function executeT0LimitOrders(
        bytes[] memory signatures,
        Order[] memory orders,
        uint256 token0AmountToFill
    ) external {
        require(
            signatures.length == orders.length,
            "signatures and orders must have same length"
        );
        for (uint i = 0; i < orders.length; i++) {
            uint amount = 0;
            if (
                orders[i].orderType == OrderType.BUY ||
                orders[i].orderType == OrderType.SELL
            ) {
                amount = _executeLimitOrder(
                    signatures[i],
                    orders[i],
                    token0AmountToFill
                );
            } else if (
                orders[i].orderType == OrderType.LONG ||
                orders[i].orderType == OrderType.SHORT
            ) {
                amount = _executeT0LeverageOrder(
                    signatures[i],
                    orders[i],
                    token0AmountToFill
                );
            } else {
                revert("Order type not supported");
            }
            token0AmountToFill -= amount;
            if (token0AmountToFill == 0) {
                break;
            }
        }
    }

    /**
     * @dev Execute multiple limit orders as per token1 amount
     * @param signatures Signatures of the orders
     * @param orders Order structs
     * @param token1AmountToFill Amount of token1 to fill
     */
    function executeT1LimitOrders(
        bytes[] memory signatures,
        Order[] memory orders,
        uint256 token1AmountToFill
    ) external {
        require(
            signatures.length == orders.length,
            "signatures and orders must have same length"
        );
        for (uint i = 0; i < orders.length; i++) {
            uint token0AmountToFill = token1AmountToFill.mul(1e18).div(
                orders[i].exchangeRate
            );
            uint amount = 0;
            if (
                orders[i].orderType == OrderType.BUY ||
                orders[i].orderType == OrderType.SELL
            ) {
                amount = _executeLimitOrder(
                    signatures[i],
                    orders[i],
                    token0AmountToFill
                );
            } else if (
                orders[i].orderType == OrderType.LONG ||
                orders[i].orderType == OrderType.SHORT
            ) {
                amount = _executeT0LeverageOrder(
                    signatures[i],
                    orders[i],
                    token0AmountToFill
                );
            } else {
                revert("Order type not supported");
            }
            token0AmountToFill -= amount;
            token1AmountToFill = token0AmountToFill
                .mul(orders[i].exchangeRate)
                .div(1e18);
            if (token0AmountToFill == 0) {
                break;
            }
        }
    }

    struct vars_Leverage {
        address supplyToken;
        address borrowToken;
        uint supplyAmount;
        uint borrowAmount;
        uint amount;
    }

    struct vars_LoopParams {
        uint thisLoopLimitFill;
        uint thisLoopFill;
        uint amountToFillInThisLoop;
        uint _executedAmount;
    }

    /**
     * @dev Execute a leverage order as per token0 amount
     * @param signature Signature of the order
     * @param order Order struct
     * @param amountToFill Amount of token0 to fill
     * @return Amount of token0 filled
     */
    function _executeT0LeverageOrder(
        bytes memory signature,
        Order memory order,
        uint amountToFill
    ) internal returns (uint) {
        IPool pool = assetToMarket[order.token0];
        require(assetToMarket[order.token1] == pool);

        // verify order signature
        bytes32 digest = verifyOrderHash(signature, order);
        require(validateOrder(order));

        vars_Leverage memory vars;
        vars_LoopParams memory loop_vars;
        for (uint i = loops[digest]; i < order.loops; i++) {
            loop_vars.thisLoopLimitFill = scaledByBorrowLimit(
                order.amount,
                order.borrowLimit,
                i + 1
            );
            // already fill amount in this loop
            loop_vars.thisLoopFill = loopFills[digest];
            // taking minimum of amount to fill and remaining amount of the current loop.
            loop_vars.amountToFillInThisLoop = amountToFill.min(
                loop_vars.thisLoopLimitFill - loop_vars.thisLoopFill
            );

            vars.supplyToken = order.token0;
            vars.supplyAmount = loop_vars.amountToFillInThisLoop;
            vars.borrowToken = order.token1;
            vars.borrowAmount = loop_vars
                .amountToFillInThisLoop
                .mul(order.exchangeRate)
                .div(10 ** 18);
            if (order.orderType == OrderType.SHORT) {
                vars.supplyToken = order.token1;
                vars.supplyAmount = loop_vars
                    .amountToFillInThisLoop
                    .mul(order.exchangeRate)
                    .div(10 ** 18);
                vars.borrowToken = order.token0;
                vars.borrowAmount = loop_vars.amountToFillInThisLoop;
            }

            if (i == 0) {
                vars.amount = order.amount;
                if (order.orderType == OrderType.SHORT) {
                    vars.amount = order.amount.mul(order.exchangeRate).div(
                        10 ** 18
                    );
                }
                console.log("Inside exchange leverage1",vars.supplyToken,vars.amount, order.maker);
                pool.supply(vars.supplyToken, vars.amount, order.maker, 0);
                console.log("Inside leverage 2");
            }
            // token, amount, 2, 0, msg.sender

            pool.borrow(vars.borrowToken, vars.borrowAmount, 2, 0, order.maker);

            // Tokens to transfer in this loop
            loop_vars._executedAmount += loop_vars.amountToFillInThisLoop;
            exchangeInternal(
                order,
                msg.sender,
                loop_vars.amountToFillInThisLoop
            );
            // console.log(i, vars.supplyAmount, vars.borrowAmount);
            // supply token got from exchange to market
            pool.supply(vars.supplyToken, vars.supplyAmount, order.maker, 0);

            loopFills[digest] += loop_vars.amountToFillInThisLoop;
            amountToFill = amountToFill.sub(loop_vars.amountToFillInThisLoop);

            if (
                loop_vars.thisLoopFill + loop_vars.amountToFillInThisLoop ==
                loop_vars.thisLoopLimitFill
            ) {
                loops[digest] += 1;
                loopFills[digest] = 0;
            }

            // If no/min fill amount left
            if (amountToFill <= minTokenAmount[order.token0]) {
                break;
            }
        }
        if (loop_vars._executedAmount > 0) {
            emit OrderExecuted(digest, msg.sender, loop_vars._executedAmount);
        }

        return amountToFill;
    }

    struct vars_LeverageClose {
        uint thisLoopLimitFill;
        uint thisLoopFill;
        uint amountToWithdrawInThisLoop;
        uint _executedAmount;
        uint leverageAmount;
        uint percentageAmountToWithdraw;
        address supplyToken;
        uint withdrawAmount;
        address borrowToken;
        uint repayAmount;
        uint amount;
    }

    function closeLeveragePosition(
        bytes memory signature,
        Order memory order,
        uint amountToWithdraw
    ) external returns (uint) {
        IPool pool = assetToMarket[order.token0];
        require(assetToMarket[order.token1] == pool);

        // verify order signature
        bytes32 digest = verifyOrderHash(signature, order);
        require(validateOrder(order));
        vars_LeverageClose memory loop_vars;
        // uint leverage = (1-(0.001/order.amount)) / (1-(order.borrowLimit/10**6));
        // loop_vars.leverageAmount =
        //     (1 - ((0.001 * uint256(1e18).div(1e3)) / order.amount)) /
        //     (1 - order.borrowLimit);

        // loop_vars.leverageAmount = (1 - ((0.001e18)/order.amount))/(1- order.borrowLimit) * order.amount;
        // loop_vars.leverageAmount = (uint256(1).sub((uint256(0.001e18)).div(order.amount))).div(uint256(1).sub(uint256(order.borrowLimit).div(1e6))); //.mul(order.amount)
        loop_vars.leverageAmount = (
            (uint256(1).mul(1e18))
                .sub((uint256(0.001e18).mul(1e18).div(order.amount)))
                .mul(1e18)
                .div(
                    uint256(1).mul(1e18).sub(
                        uint256(order.borrowLimit).mul(1e18).div(1e6)
                    )
                )
        ).mul(order.amount).div(1e18);
        // (1 - (minAmount / amount)) / (1 - borrowLimit)
        loop_vars.percentageAmountToWithdraw = amountToWithdraw.mul(1e18).div(
            loop_vars.leverageAmount
        );
        // console.log(order.amount);
        console.log("leverageAmount", loop_vars.leverageAmount);
        console.log("%", loop_vars.percentageAmountToWithdraw);

        for (uint i = order.loops; i > 0; i--) {
            console.log("i", i);
            loop_vars.thisLoopLimitFill = scaledByBorrowLimit(
                order.amount,
                order.borrowLimit,
                i
            );
            // already fill amount in this loop
            // loop_vars.thisLoopFill = loopFills[digest];
            // taking minimum of amount to fill and remaining amount of the current loop.
            loop_vars.amountToWithdrawInThisLoop = loop_vars
                .thisLoopLimitFill
                .mul(loop_vars.percentageAmountToWithdraw)
                .div(1e18);

            console.log("loopLimit", loop_vars.thisLoopLimitFill);
            console.log(
                "amiuntToWithdraw",
                loop_vars.amountToWithdrawInThisLoop
            );
            loop_vars.supplyToken = order.token0;
            loop_vars.withdrawAmount = loop_vars.amountToWithdrawInThisLoop;
            loop_vars.borrowToken = order.token1;
            loop_vars.repayAmount = loop_vars
                .amountToWithdrawInThisLoop
                .mul(order.exchangeRate)
                .div(10 ** 18);
            if (order.orderType == OrderType.SHORT) {
                loop_vars.supplyToken = order.token1;
                loop_vars.withdrawAmount = loop_vars
                    .amountToWithdrawInThisLoop
                    .mul(order.exchangeRate)
                    .div(10 ** 18);
                loop_vars.borrowToken = order.token0;
                loop_vars.repayAmount = loop_vars.amountToWithdrawInThisLoop;
            }
            console.log(loop_vars.withdrawAmount, loop_vars.repayAmount);
            // if (i == 0) {
            //     loop_vars.amount = order.amount;
            //     if (order.orderType == OrderType.SHORT) {
            //         loop_vars.amount = order.amount.mul(order.exchangeRate).div(
            //             10 ** 18
            //         );
            //     }
            //     loop_vars.supplyToken.mint(order.maker, loop_vars.amount);
            // }

            // loop_vars.supplyToken.redeemUnderlying(
            //     order.maker,
            //     loop_vars.withdrawAmount
            // );

            pool.withdraw(
                loop_vars.supplyToken,
                loop_vars.withdrawAmount,
                order.maker
            );
            // break;
            // if(i == 1) {
            //     break;
            // }
            // Tokens to transfer in this loop
            loop_vars._executedAmount += loop_vars.amountToWithdrawInThisLoop;
            exchangeInternalClose(
                order,
                msg.sender,
                loop_vars.amountToWithdrawInThisLoop
            );
            // console.log(i, vars.supplyAmount, vars.borrowAmount);
            // supply token got from exchange to market

            // loop_vars.borrowToken.repayBorrow(
            //     order.maker,
            //     loop_vars.repayAmount
            // );

            pool.repay(
                loop_vars.borrowToken,
                loop_vars.repayAmount,
                2,
                order.maker
            );

            if (i == 1) {
                // loop_vars.borrowToken.repayBorrow(
                //     order.maker,
                //     65255718754356//loop_vars.repayAmount
                // );
                // loop_vars.supplyToken.redeemUnderlying(
                //     order.maker,
                //     999999992481245701 // 0.8e18
                // );
                pool.withdraw(
                    loop_vars.supplyToken,
                    999999992481245701, //loop_vars.withdrawAmount,
                    order.maker
                );
            }
            // loopFills[digest] += loop_vars.amountToWithdrawInThisLoop;
            // amountToWithdraw = amountToWithdraw.sub(
            //     loop_vars.amountToWithdrawInThisLoop
            // );
        }

        if (loop_vars._executedAmount > 0) {
            emit OrderExecuted(digest, msg.sender, loop_vars._executedAmount);
        }

        return amountToWithdraw;
    }

    /**
     * @notice Executed leverage order with limit orders
     */
    function executeLeverageWithLimitOrders(
        bytes[] memory limitOrderSignatures,
        Order[] memory limitOrders,
        bytes memory signature,
        Order memory order
    ) external {
        // TODO
        // require(limitOrderSignatures.length == limitOrders.length, "Invalid limit order signatures");
        // require(limitOrders.length > 0, "No limit orders");
        // bytes32 orderId = verifyOrderHash(signature, order);
        // require(validateOrder(order), "Invalid order");
        // uint limitOrderExecIndex = 0;
        // uint limitOrdersLength = limitOrders.length;
        // for(uint i = loops[orderId]; i < order.loops; i++){
        //     uint thisLoopLimitFill = scaledByBorrowLimit(order.amount, order.borrowLimit, i+1);
        //     uint thisLoopFill = loopFills[orderId];
        //     if(thisLoopFill == 0){
        //         leverageInternal(assetToMarket[order.token0], assetToMarket[order.token1], thisLoopLimitFill, order);
        //     }
        //     uint amountToFillInThisLoop = thisLoopLimitFill - thisLoopFill;
        //     // Tokens to transfer in this loop
        //     for(uint j = limitOrderExecIndex; j < limitOrdersLength; j++){
        //     }
        //     uint amount = _executeLimitOrder(limitOrderSignatures, limitOrders, amountToFillInThisLoop);
        //     loopFills[orderId] += amount;
        //     amountToFillInThisLoop = amountToFillInThisLoop.sub(amount);
        //     if(thisLoopFill + amountToFillInThisLoop == thisLoopLimitFill){
        //         loops[orderId] += 1;
        //         loopFills[orderId] = 0;
        //     }
        //     // If no/min fill amount left
        //     if(amountToFillInThisLoop <= minTokenAmount[order.token0]){
        //         break;
        //     }
        // }
    }

    /**
     * @dev Cancel an order
     * @param signature Signature of the order
     * @param order Order struct
     */
    function cancelOrder(bytes memory signature, Order memory order) external {
        bytes32 orderId = verifyOrderHash(signature, order);

        require(order.maker == msg.sender, "Only maker can cancel order");

        if (
            order.orderType == OrderType.BUY ||
            order.orderType == OrderType.SELL
        ) {
            orderFills[orderId] = order.amount;
        } else if (
            order.orderType == OrderType.LONG ||
            order.orderType == OrderType.SHORT
        ) {
            loopFills[orderId] = order.amount;
            loops[orderId] = order.loops;
        } else {
            revert("Order type not supported");
        }
        emit OrderCancelled(orderId);
    }

    /**
     * @dev Deposit tokens to lever
     * @param token Token to deposit
     * @param amount Amount of token to deposit
     */
    function mint(address token, uint amount) public {
        IPool pool = assetToMarket[token];
        require(address(pool) != address(0), "Margin trading not enabled");
        require(amount >= minTokenAmount[token], "Amount too small");
        pool.supply(token, amount, msg.sender, 0);
    }

    /**
     * @dev Withdraw tokens from lever
     * @param token Token to withdraw
     * @param amount Amount of token to withdraw
     */
    function redeem(address token, uint amount) public {
        IPool pool = assetToMarket[token];
        require(address(pool) != address(0), "Margin trading not enabled");
        require(amount >= minTokenAmount[token], "Amount too small");
        pool.withdraw(token, amount, msg.sender);
    }

    /**
     * @dev Borrow tokens from lever
     * @param token Token to borrow
     * @param amount Amount of token to borrow
     */
    function borrow(address token, uint amount) public {
        IPool pool = assetToMarket[token];
        require(address(pool) != address(0), "Margin trading not enabled");
        require(amount >= minTokenAmount[token], "Amount too small");
        pool.borrow(token, amount, 2, 0, msg.sender);
    }

    /**
     * @dev Repay tokens to lever
     * @param token Token to repay
     * @param amount Amount of token to repay
     */
    function repay(address token, uint amount) public {
        IPool pool = assetToMarket[token];
        require(address(pool) != address(0), "Margin trading not enabled");
        require(amount >= minTokenAmount[token], "Amount too small");
        pool.repay(token, amount, 2, msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Enable margin trading for a token
     * @param token Token to enable
     * @param poolAddress cToken of the token
     */
    function enableMarginTrading(
        address token,
        address poolAddress
    ) external onlyRole(ADMIN_ROLE) {
        assetToMarket[token] = IPool(poolAddress);
        // require(LendingMarket(cToken).underlying() == token, "Invalid cToken");
        emit MarginEnabled(token, poolAddress);
    }

    /**
     * @dev Set minimum token amount
     * @param token Token to set
     * @param amount Minimum amount of token
     */
    function setMinTokenAmount(
        address token,
        uint256 amount
    ) external onlyRole(ADMIN_ROLE) {
        minTokenAmount[token] = amount;
        emit MinTokenAmountSet(token, amount);
    }

    /**
     * @dev Set fees
     * @param _makerFee Maker fee
     * @param _takerFee Taker fee
     */
    function setFees(
        uint256 _makerFee,
        uint256 _takerFee
    ) external onlyRole(ADMIN_ROLE) {
        makerFee = _makerFee;
        takerFee = _takerFee;
        emit FeesSet(_makerFee, _takerFee);
    }

    function withdrawFunds(
        address _tokenAddress
    ) external onlyRole(ADMIN_ROLE) {
        IERC20Upgradeable(_tokenAddress).transfer(
            msg.sender,
            IERC20Upgradeable(_tokenAddress).balanceOf(address(this))
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
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
        // console.log("chianId---", block.chainid);
        // console.log("order1", order.amount, uint256(order.orderType), order.salt);
        // console.log("order2", order.exchangeRate, uint256(order.borrowLimit), order.loops);
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Order(address maker,address token0,address token1,uint256 amount,uint8 orderType,uint32 salt,uint176 exchangeRate,uint32 borrowLimit,uint8 loops)"
                    ),
                    order.maker,
                    order.token0,
                    order.token1,
                    order.amount,
                    uint8(order.orderType),
                    order.salt,
                    order.exchangeRate,
                    order.borrowLimit,
                    order.loops
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

    function dummy() public pure returns (uint) {
        return 112233;
    }
}