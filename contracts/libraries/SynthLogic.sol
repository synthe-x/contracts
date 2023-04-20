// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PriceConvertor.sol";
import "../pool/IPool.sol";
import "../synth/IERC20X.sol";
import "../synthex/ISyntheX.sol";
import "../libraries/Errors.sol";

import "hardhat/console.sol";

library SynthLogic {
    using PriceConvertor for uint256;
    event Liquidate(address indexed liquidator, address indexed account, address indexed outAsset, uint256 outAmount, uint256 outPenalty, uint256 outRefund);
    uint constant BASIS_POINTS = 10000;

    struct MintVars {
        address to;
        uint amountIn; 
        IPriceOracle priceOracle; 
        address synthIn; 
        address feeToken; 
        uint balance;
        uint totalSupply;
        uint totalDebt;
        DataTypes.AccountLiquidity liq;
        DataTypes.Synth synth;
        uint issuerAlloc;
        ISyntheX synthex;
    }

    function commitMint(
        MintVars memory vars
    ) public returns(uint mintAmount) {
        require(vars.synth.isActive, Errors.ASSET_NOT_ACTIVE);

        address[] memory tokens = new address[](2);
        tokens[0] = vars.synthIn;
        tokens[1] = vars.feeToken;
        uint[] memory prices = vars.priceOracle.getAssetsPrices(tokens);

        // 10 cETH * 1000 = 10000 USD
        // +10% fee = 11 cETH debt to issue (11000 USD)
        // 10 cETH minted to user (10000 USD)
        // 1 cETH fee (1000 USD) = 0.5 cETH minted to vault (1-issuerAlloc) + 0.5 cETH not minted (burned) 
        // This would result in net -0.5 cETH ($500) worth of debt issued; i.e. $500 of debt is reduced from pool (for all users)
        
        // Amount of debt to issue (in usd, including mintFee)
        uint amountUSD = vars.amountIn.toUSD(prices[0]);
        uint amountPlusFeeUSD = amountUSD + (amountUSD * vars.synth.mintFee / (BASIS_POINTS));
        if(vars.liq.liquidity < int(amountPlusFeeUSD)){
            amountPlusFeeUSD = uint(vars.liq.liquidity);
        }

        // call for reward distribution before minting
        vars.synthex.distribute(msg.sender, vars.totalSupply, vars.balance);

        // Amount of debt to issue (in usd, including mintFee)
        mintAmount = amountPlusFeeUSD;
        if(vars.totalSupply > 0){
            // Calculate the amount of debt tokens to mint
            // debtSharePrice = totalDebt / totalSupply
            // mintAmount = amountUSD / debtSharePrice 
            mintAmount = amountPlusFeeUSD * vars.totalSupply / vars.totalDebt;
        }

        // Amount * (fee * issuerAlloc) is burned from global debt
        // Amount * (fee * (1 - issuerAlloc)) to vault
        // Fee amount of feeToken: amountUSD * fee * (1 - issuerAlloc) / feeTokenPrice
        amountUSD = amountPlusFeeUSD * (BASIS_POINTS) / (BASIS_POINTS + vars.synth.mintFee);
        vars.amountIn = amountUSD.toToken(prices[0]);

        uint feeAmount = (
            (amountPlusFeeUSD - amountUSD)      // total fee amount in USD
            * (BASIS_POINTS - vars.issuerAlloc)      // multiplying (1 - issuerAlloc)
            / (BASIS_POINTS))                   // for multiplying issuerAlloc
            .toToken(prices[1]             // to feeToken amount
        );

        // Mint FEE tokens to vault
        address vault = vars.synthex.vault();
        if(vault != address(0)) {
            IERC20X(vars.feeToken).mint(
                vault,
                feeAmount
            );
        }

        // return the amount of synths to issue
        IERC20X(vars.synthIn).mint(vars.to, vars.amountIn);
    }

    struct BurnVars {
        uint amountIn; 
        IPriceOracle priceOracle; 
        address synthIn; 
        address feeToken; 
        uint balance;
        uint totalSupply;
        uint userDebtUSD;
        uint totalDebt;
        DataTypes.Synth synth;
        uint issuerAlloc;
        ISyntheX synthex;
    }

    function commitBurn(
        BurnVars memory vars
    ) internal returns(uint mintAmount) {
        // check if synth is valid
        if(!vars.synth.isActive) require(vars.synth.isDisabled, Errors.ASSET_NOT_ENABLED);

        address[] memory tokens = new address[](2);
        tokens[0] = vars.synthIn;
        tokens[1] = vars.feeToken;
        uint[] memory prices = vars.priceOracle.getAssetsPrices(tokens);

        // amount of debt to burn (in usd, including burnFee)
        // amountUSD = amount * price / (1 + burnFee)
        uint amountUSD = vars.amountIn.toUSD(prices[0]) * (BASIS_POINTS) / (BASIS_POINTS + vars.synth.burnFee);
        // ensure user has enough debt to burn
        if(vars.userDebtUSD < amountUSD){
            // amount = debt + debt * burnFee / BASIS_POINTS
            vars.amountIn = (vars.userDebtUSD + (vars.userDebtUSD * (vars.synth.burnFee) / (BASIS_POINTS))).toToken(prices[0]);
            amountUSD = vars.userDebtUSD;
        }
        // ensure user has enough debt to burn
        if(amountUSD == 0) return 0;

        // call for reward distribution
        vars.synthex.distribute(msg.sender, vars.totalSupply, vars.balance);


        // Mint fee * (1 - issuerAlloc) to vault
        uint feeAmount = (
            (amountUSD * vars.synth.burnFee * (BASIS_POINTS - vars.issuerAlloc) / (BASIS_POINTS)) 
            / BASIS_POINTS          // for multiplying burnFee
        ).toToken(prices[1]);  // to feeToken amount

        address vault = vars.synthex.vault();
        if(vault != address(0)) {
            IERC20X(vars.feeToken).mint(
                vault,
                feeAmount
            );
        }

        IERC20X(vars.synthIn).burn(msg.sender, vars.amountIn);

        return vars.totalSupply * amountUSD / vars.totalDebt;
    }

     struct SwapVars {
        address to;
        address synthIn;
        address synthOut;
        uint amount; 
        DataTypes.SwapKind kind;
        IPriceOracle priceOracle;
        address feeToken;
        DataTypes.Synth synthInData;
        DataTypes.Synth synthOutData;
        uint issuerAlloc;
        ISyntheX synthex;
    }

    function commitSwap(
        SwapVars memory vars
    ) internal returns(uint[2] memory) {
        // check if enabled synth is calling
        // should be able to swap out of disabled (inactive) synths
        if(!vars.synthInData.isActive) require(vars.synthInData.isDisabled, Errors.ASSET_NOT_ENABLED);
        // ensure exchange is not to same synth
        require(vars.synthIn != vars.synthOut, Errors.INVALID_ARGUMENT);

        address[] memory t = new address[](3);
        t[0] = vars.synthIn;
        t[1] = vars.synthOut;
        t[2] = vars.feeToken;
        uint[] memory prices = vars.priceOracle.getAssetsPrices(t);

        uint amountUSD = 0;
        uint fee = 0;
        uint amountOut = 0;
        uint amountIn = 0;
        if(vars.kind == DataTypes.SwapKind.GIVEN_IN) {
            amountIn = vars.amount;
            amountUSD = vars.amount.toUSD(prices[0]);
            fee = amountUSD * (vars.synthOutData.mintFee + vars.synthInData.burnFee) / BASIS_POINTS;
            amountOut = (amountUSD - fee).toToken(prices[1]);
        } else {
            amountOut = vars.amount;
            amountUSD = vars.amount.toUSD(prices[1]);
            fee = amountUSD - amountUSD * BASIS_POINTS / (BASIS_POINTS + vars.synthOutData.mintFee + vars.synthInData.burnFee);
            amountIn = (amountUSD + fee).toToken(prices[0]);
        }

        // 1. Mint (amount - fee) toSynth to recipient
        IERC20X(vars.synthOut).mint(vars.to, amountOut);
        // 2. Mint fee * (1 - issuerAlloc) (in feeToken) to vault
        address vault = vars.synthex.vault();
        if(vault != address(0)) {
            IERC20X(vars.feeToken).mint(
                vault,
                (fee * (BASIS_POINTS - vars.issuerAlloc)        // multiplying (1 - issuerAlloc)
                / (BASIS_POINTS))                           // for multiplying issuerAlloc
                .toToken(prices[2])
            );
        }
        // 3. Burn all fromSynth
        IERC20X(vars.synthIn).burn(msg.sender, amountIn);

        return [amountIn, amountOut];
    }

    uint constant SCALER = 1e18;
    
    struct LiquidateVars {
        uint amountIn; 
        address account;
        IPriceOracle priceOracle; 
        address synthIn; 
        address collateralOut;
        address feeToken;
        uint totalSupply;
        uint totalDebt;
        DataTypes.AccountLiquidity liq;
        DataTypes.Synth synth;
        DataTypes.Collateral collateral;
        uint issuerAlloc;
        ISyntheX synthex;
    }

    function commitLiquidate(
        LiquidateVars memory vars,
        mapping(address => mapping(address => uint)) storage accountCollateralBalance
    ) external returns(uint refundOut, uint burnAmount) {
        DataTypes.Vars_Liquidate memory iv;
        // check if synth is enabled
        if(!vars.synth.isActive) require(vars.synth.isDisabled, Errors.ASSET_NOT_ENABLED);

        // Check account liquidity
        require(vars.liq.debt > 0, Errors.INSUFFICIENT_DEBT);
        require(vars.liq.collateral > 0, Errors.INSUFFICIENT_COLLATERAL);
        iv.ltv = vars.liq.debt * (SCALER) / (vars.liq.collateral);
        require(iv.ltv > vars.collateral.liqThreshold * SCALER / BASIS_POINTS, Errors.ACCOUNT_BELOW_LIQ_THRESHOLD);
        // Ensure user has entered the collateral market

        iv.tokens = new address[](3);
        iv.tokens[0] = vars.synthIn;
        iv.tokens[1] = vars.collateralOut;
        iv.tokens[2] = vars.feeToken;
        iv.prices = vars.priceOracle.getAssetsPrices(iv.tokens);

        // Amount of debt to burn (in usd, excluding burnFee)
        iv.amountUSD = vars.amountIn.toUSD(iv.prices[0]) * (BASIS_POINTS)/(BASIS_POINTS + vars.synth.burnFee);
        if(vars.liq.debt < iv.amountUSD) {
            iv.amountUSD = vars.liq.debt;
        }

        // Amount of debt to burn (in terms of collateral)
        iv.amountOut = iv.amountUSD.toToken(iv.prices[1]);
        iv.penalty = 0;
        refundOut = 0;

        // Sieze collateral
        uint balanceOut = accountCollateralBalance[vars.account][vars.collateralOut];
        if(iv.ltv > SCALER){
            // if ltv > 100%, take all collateral, no penalty
            if(iv.amountOut > balanceOut){
                iv.amountOut = balanceOut;
            }
        } else {
            // take collateral based on ltv, and apply penalty
            balanceOut = balanceOut * iv.ltv / SCALER;
            if(iv.amountOut > balanceOut){
                iv.amountOut = balanceOut;
            }
            // penalty = amountOut * liqBonus
            iv.penalty = iv.amountOut * (vars.collateral.liqBonus - BASIS_POINTS) / (BASIS_POINTS);

            // if we don't have enough for [complete] bonus, take partial bonus
            if(iv.ltv * vars.collateral.liqBonus / BASIS_POINTS > SCALER){
                // penalty = amountOut * (1 - ltv)/ltv 
                iv.penalty = iv.amountOut * (SCALER - iv.ltv) / (iv.ltv);
            }
            // calculate refund if we have enough for bonus + extra
            else {
                // refundOut = amountOut * (1 - ltv * liqBonus)
                refundOut = iv.amountOut * (SCALER - (iv.ltv * vars.collateral.liqBonus / BASIS_POINTS)) / SCALER;
            }
        }

        accountCollateralBalance[vars.account][vars.collateralOut] -= (iv.amountOut + iv.penalty + refundOut);

        // Add collateral to liquidator
        accountCollateralBalance[msg.sender][vars.collateralOut]+= (iv.amountOut + iv.penalty);

        iv.amountUSD = iv.amountOut.toUSD(iv.prices[1]);
        // Amount of debt to burn
        burnAmount = vars.totalSupply * iv.amountUSD / vars.totalDebt;

        // send (burn fee - issuerAlloc) in feeToken to vault
        uint fee = iv.amountUSD * (vars.synth.burnFee) / (BASIS_POINTS);
        address vault = vars.synthex.vault();
        if(vault != address(0)) {
            IERC20X(vars.feeToken).mint(
                vault,
                (fee * (BASIS_POINTS - vars.issuerAlloc)        // multiplying (1 - issuerAlloc)
                / BASIS_POINTS)                            // for multiplying issuerAlloc
                .toToken(iv.prices[2])
            );
        }

        emit Liquidate(msg.sender, vars.account, vars.collateralOut, iv.amountOut, iv.penalty, refundOut);

        // amount (in synth) plus burn fee
        IERC20X(vars.synthIn).burn(msg.sender, iv.amountUSD.toToken(iv.prices[0]) * (BASIS_POINTS + vars.synth.burnFee) / (BASIS_POINTS));
    }
}