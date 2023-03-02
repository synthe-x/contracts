// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";


import "../synth/ERC20X.sol";
import { IPool } from "./IPool.sol";
import "../libraries/PriceConvertor.sol";

// debug
import "hardhat/console.sol";

/**
 * @title Pool
 * @notice Pool contract to manage collaterals and debt
 * @author Prasad <prasad@chainscore.finance>
 */
contract Pool is IPool, ERC20Upgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Using SafeMath for uint256 to prevent overflows and underflows
    using SafeMathUpgradeable for uint256;
    /// @notice Using Math for uint256 to calculate minimum and maximum
    using MathUpgradeable for uint256; 
    /// @notice for converting token prices
    using PriceConvertor for uint256;
    /// @notice Using SafeERC20 for IERC20 to prevent reverts
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The address of the address storage contract
    SyntheX public synthex;
    
    /// @dev Initialize the contract
    function initialize(string memory _name, string memory _symbol, address _synthex) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __ReentrancyGuard_init(); 

        // set addresses
        synthex = SyntheX(_synthex);
        // paused till (1) collaterals are added, (2) synths are added and (3) feeToken is set
        pause();
    }

    /// @dev Override to disable transfer
    function _transfer(address, address, uint256) internal virtual override {
        revert("DebtPool: Cannot transfer debt");
    }

    /* -------------------------------------------------------------------------- */
    /*                              External Functions                            */
    /* -------------------------------------------------------------------------- */

    receive() external payable { 
        depositETH();
    }

    fallback() external payable {
        depositETH();
    }

    /**
     * @notice Enable a collateral
     * @param _collateral The address of the collateral
     */
    function enterCollateral(address _collateral) virtual override public {
        // get collateral pool
        Collateral storage collateral = collaterals[_collateral];

        require(collateral.isEnabled, "SyntheX: Collateral not enabled");

        // ensure that the user is not already in the pool
        require(!accountMembership[_collateral][msg.sender], "SyntheX: Already in collateral");
        // enable account's collateral membership
        accountMembership[_collateral][msg.sender] = true;
        // add to account's collateral list
        accountCollaterals[msg.sender].push(_collateral);

        emit CollateralEntered(msg.sender, _collateral);
    }

    /**
     * @notice Exit a collateral
     * @param _collateral The address of the collateral
     */
    function exitCollateral(address _collateral) virtual override public {
        accountMembership[_collateral][msg.sender] = false;
        // remove from list
        for (uint i = 0; i < accountCollaterals[msg.sender].length; i++) {
            if (accountCollaterals[msg.sender][i] == _collateral) {
                accountCollaterals[msg.sender][i] = accountCollaterals[msg.sender][accountCollaterals[msg.sender].length - 1];
                accountCollaterals[msg.sender].pop();

                emit CollateralExited(msg.sender, _collateral); 
                break;
            }
        }
    }

    /**
     * @notice Deposit ETH
     */
    function depositETH() virtual override public payable {
        // check if param _amount == msg.value sent with tx
        require(msg.value > 0, "Zero ETH amount");
        depositInternal(msg.sender, ETH_ADDRESS, msg.value);
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     */
    function deposit(address _collateral, uint _amount) virtual override public {
        // check if param _amount == msg.value sent with tx
        IERC20Upgradeable(_collateral).safeTransferFrom(msg.sender, address(this), _amount);
        depositInternal(msg.sender, _collateral, _amount);
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     */
    function depositWithPermit(
        address _collateral, 
        uint _amount,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) virtual override public {
        // permit approval
        IERC20Permit(_collateral).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        // transfer
        IERC20Upgradeable(_collateral).safeTransferFrom(msg.sender, address(this), _amount);
        depositInternal(msg.sender, _collateral, _amount);
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     */
    function depositInternal(address _account, address _collateral, uint _amount) internal whenNotPaused {
        // get collateral market
        Collateral storage collateral = collaterals[_collateral];
        // ensure collateral is globally enabled
        require(collateral.isEnabled, "Collateral not enabled");

        // ensure user has entered the market
        if(!accountMembership[_collateral][_account]){
            enterCollateral(_collateral);
        }
        
        Collateral storage supply = collaterals[_collateral];

        // Update balance
        accountCollateralBalance[_account][_collateral] = accountCollateralBalance[_account][_collateral].add(_amount);

        // Update collateral supply
        supply.totalDeposits = supply.totalDeposits.add(_amount);
        require(supply.totalDeposits <= supply.cap, "Collateral supply exceeded");

        // emit event
        emit Deposit(_account, _collateral, _amount);
    }

    /**
     * @notice Withdraw collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to withdraw
     */
    function withdraw(address _collateral, uint _amount) virtual override public {
        // Transfer collateral to user
        _amount = transferOut(_collateral, msg.sender, _amount);
        // Process withdraw
        withdrawInternal(msg.sender, _collateral, _amount);
    }

    /**
     * @notice Withdraw eth collateral
     * @param _amount The amount of eth to withdraw
     */
    function withdrawETH(uint _amount) virtual override public {
        // Transfer ETH to user
        _amount = transferETH(msg.sender, _amount);
        // Process withdraw
        withdrawInternal(msg.sender, ETH_ADDRESS, _amount);
    }

    function withdrawInternal(address _account, address _collateral, uint _amount) internal whenNotPaused {
        // check deposit balance
        uint depositBalance = accountCollateralBalance[msg.sender][_collateral];
        // ensure user has enough deposit balance
        require(depositBalance >= _amount, "Insufficient balance");

        // Update balance
        accountCollateralBalance[_account][_collateral] = depositBalance.sub(_amount);

        Collateral storage supply = collaterals[_collateral];
        require(supply.isEnabled, "Collateral not enabled");
        // Update collateral supply
        supply.totalDeposits = supply.totalDeposits.sub(_amount);

        // Check health after withdrawal
        require(getAccountLiquidity(_account).liquidity >= 0, "Withdrawing more than allowed");

        // Emit successful event
        emit Withdraw(_account, _collateral, _amount);
    }

    /**
     * @notice Transfer asset out to address
     * @param _asset The address of the asset
     * @param recipient The address of the recipient
     * @param _amount Amount
     * @return The amount transferred
     */
    function transferOut(address _asset, address recipient, uint _amount) internal returns(uint) {
        if(ERC20Upgradeable(_asset).balanceOf(address(this)) < _amount){
            _amount = ERC20Upgradeable(_asset).balanceOf(address(this));
        }
        IERC20Upgradeable(_asset).safeTransfer(recipient, _amount);

        return _amount;
    }

    function transferETH(address recipient, uint _amount) internal nonReentrant returns(uint) {
        if(address(this).balance < _amount){
            _amount = address(this).balance;
        }
        payable(recipient).transfer(_amount);

        return _amount;
    }

    struct Vars_Mint {
        uint amountPlusFeeUSD;
        uint _borrowCapacity;
        address[] tokens;
        uint[] prices;
    }

    /**
     * @notice Issue synths to the user
     * @param _account The address of the user to issue synths to
     * @param _amount Amount of synth
     * @notice Only SyntheX can call this function
     */
    function commitMint(address _account, uint _amount) virtual override whenNotPaused external returns(uint) {
        Vars_Mint memory vars;
        // check if synth is enabled
        require(synths[msg.sender].isEnabled, "SyntheXPool: Synth not enabled");

        vars.tokens = new address[](2);
        vars.tokens[0] = msg.sender;
        vars.tokens[1] = feeToken;
        vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        int _borrowCapacity = getAccountLiquidity(_account).liquidity;
        
        require(_borrowCapacity > 0, "SyntheXPool: Insufficient liquidity");

        // amount of debt to issue (in usd, including mintFee)
        uint amountUSD = _amount.toUSD(vars.prices[0]);
        uint amountPlusFeeUSD = amountUSD.add(amountUSD.mul(synths[msg.sender].mintFee).div(BASIS_POINTS));
        if(_borrowCapacity < int(amountPlusFeeUSD)){
            amountPlusFeeUSD = uint(_borrowCapacity);
        }

        if(totalSupply() == 0){
            // Mint initial debt tokens
            _mint(_account, amountPlusFeeUSD);
        } else {
            // Calculate the amount of debt tokens to mint
            // debtSharePrice = totalDebt / totalSupply
            // mintAmount = amountUSD / debtSharePrice 
            uint mintAmount = amountPlusFeeUSD.mul(totalSupply()).div(getTotalDebtUSD());
            // Mint the debt tokens
            _mint(_account, mintAmount);
        }

        // Amount * (fee * issuerAlloc) is burned from global debt
        // Amount * (fee * (1 - issuerAlloc)) to vault
        // Fee amount of feeToken: amountUSD * fee * (1 - issuerAlloc) / feeTokenPrice
        amountUSD = amountPlusFeeUSD.mul(BASIS_POINTS).div(BASIS_POINTS.add(synths[msg.sender].mintFee));
        _amount = amountUSD.toToken(vars.prices[0]);

        uint feeAmount = amountPlusFeeUSD.sub(amountUSD) // total fee amount in USD
            .mul(uint(BASIS_POINTS).sub(issuerAlloc))           // multiplying (1 - issuerAlloc)
            .div(BASIS_POINTS)                                  // for multiplying issuerAlloc
            .toToken(vars.prices[1]);                                // to feeToken amount
        
        // Mint FEE tokens to vault
        ERC20X(feeToken).mintInternal(
            synthex.vault(),
            feeAmount
        );

        // call for reward distribution
        synthex.distribute(_account, totalSupply(), balanceOf(_account));

        // return the amount of synths to issue
        return _amount;
    }


    struct Vars_Burn {
        uint amountUSD;
        uint debt;
        address[] tokens;
        uint[] prices;
    }

    /**
     * @notice Burn synths from the user
     * @param _account User whose debt is being burned
     * @param _amount The amount of synths to burn
     * @return The amount of synth burned
     * @notice The amount of synths to burn is calculated based on the amount of debt tokens burned
     */
    function commitBurn(address _account, uint _amount) virtual override whenNotPaused external returns(uint) {
        Vars_Burn memory vars;
        // check if synth is valid
        for(uint i = 0; i < synthsList.length; i++){
            if(synthsList[i] == msg.sender){
                break;
            } else if(i == synthsList.length - 1){
                revert("SyntheXPool: Synth not found");
            }
        }

        vars.tokens = new address[](2);
        vars.tokens[0] = msg.sender;
        vars.tokens[1] = feeToken;
        vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        // amount of debt to burn (in usd, including burnFee)
        uint amountUSD = _amount.toUSD(vars.prices[0]).mul(BASIS_POINTS).div(BASIS_POINTS.add(synths[msg.sender].burnFee));
        // ensure user has enough debt to burn
        uint debt = getUserDebtUSD(_account);
        if(debt < amountUSD){
            _amount = debt.add(debt.mul(synths[msg.sender].burnFee).div(BASIS_POINTS)).toToken(vars.prices[0]);
            amountUSD = debt;
        }

        // ensure user has enough debt to burn
        if(amountUSD == 0) return 0;

        _burn(_account, totalSupply().mul(amountUSD).div(getTotalDebtUSD()));

        // Mint fee * (1 - issuerAlloc) to vault
        ERC20X(feeToken).mintInternal(
            synthex.vault(),
            amountUSD.mul(synths[msg.sender].burnFee).mul(uint(BASIS_POINTS).sub(issuerAlloc)).div(BASIS_POINTS).div(BASIS_POINTS).toToken(vars.prices[1])
        );

        // call for reward distribution
        synthex.distribute(_account, totalSupply(), balanceOf(_account));

        return _amount;
    }

    /**
     * @notice Exchange a synthetic asset for another
     * @param _amount The amount of synthetic asset to exchange
     * @param _synthTo The address of the synthetic asset to receive
     */
    function commitSwap(address _account, uint _amount, address _synthTo) virtual override whenNotPaused external returns(uint) {
        // check if enabled synth is calling
        require(synths[msg.sender].isEnabled, "DebtPool: SynthFrom not enabled");
        require(synths[_synthTo].isEnabled, "DebtPool: SynthTo not enabled");
        // ensure exchange is not to same synth
        require(msg.sender != _synthTo, "DebtPool: Synths are the same");

        address[] memory t = new address[](3);
        t[0] = msg.sender;
        t[1] = _synthTo;
        t[2] = feeToken;
        uint[] memory prices = priceOracle.getAssetsPrices(t);

        uint amountUSD = _amount.toUSD(prices[0]);
        uint fee = amountUSD.mul(synths[_synthTo].mintFee.add(synths[msg.sender].burnFee)).div(BASIS_POINTS);

        // 1. Mint (amount - fee) toSynth to user
        ERC20X(_synthTo).mintInternal(_account, amountUSD.sub(fee).toToken(prices[1]));
        // 2. Mint fee * (1 - issuerAlloc) (in feeToken) to vault
        ERC20X(feeToken).mintInternal(
            synthex.vault(),
            fee.mul(uint(BASIS_POINTS).sub(issuerAlloc))        // multiplying (1 - issuerAlloc)
            .div(BASIS_POINTS)                                  // for multiplying issuerAlloc
            .toToken(prices[2])
        );
        // 3. Burn all fromSynth
        return _amount;
    }

    struct Vars_Liquidate {
        AccountLiquidity liq;
        Collateral collateral;
        uint ltv;

        address[] tokens;
        uint[] prices;
        uint amountUSD;
        uint debtUSD;

        uint amountOut;
        uint penalty;
        uint fee;
        uint refundOut;

    }

    /**
     * @notice Liquidate a user's debt
     */
    function commitLiquidate(address _liquidator, address _account, uint _amount, address _outAsset) virtual override whenNotPaused external returns(uint) {
        require(_amount > 0);

        Vars_Liquidate memory vars;
        // check if synth is enabled
        require(synths[msg.sender].isEnabled, "DebtPool: SynthFrom not enabled");

        // Get account liquidity
        vars.liq = getAccountLiquidity(_account);
        vars.collateral = collaterals[_outAsset];
        require(vars.liq.debt > 0, "Account has no debt");
        require(vars.liq.collateral > 0, "Account has no collateral");
        vars.ltv = vars.liq.collateral.mul(SCALER).div(vars.liq.debt);
        require(vars.ltv > vars.collateral.liqThreshold, "Account health factor below liquidation threshold");
        require(vars.liq.liquidity < 0, "Account has no shortfall");
        // Ensure user has entered the collateral market
        require(accountMembership[_outAsset][_account], "Account not in collateral");

        vars.tokens = new address[](2);
        vars.tokens[0] = msg.sender;
        vars.tokens[1] = _outAsset;
        vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        vars.amountUSD = _amount.toUSD(vars.prices[0]);
        uint debtUSD = getUserDebtUSD(_account);
        // burn only the amount of debt that the user has
        if(debtUSD < vars.amountUSD) {
            _amount = debtUSD.toToken(vars.prices[0]);
        }

        // amount in terms of collateral
        vars.amountOut = _amount.t1t2(vars.prices[0], vars.prices[1]); 
        vars.penalty = 0;
        vars.fee = 0;
        vars.refundOut = 0;

        // Sieze collateral
        uint balanceOut = accountCollateralBalance[_account][_outAsset];
        if(vars.ltv > SCALER){
            // if ltv > 100%, take all collateral, no penalty
            if(vars.amountOut > balanceOut){
                vars.amountOut = balanceOut;
            }
        } else {
            // take collateral based on ltv, and apply penalty
            balanceOut = balanceOut.mul(vars.ltv).div(SCALER);
            if(vars.amountOut > balanceOut){
                vars.amountOut = balanceOut;
            }
            vars.penalty = vars.amountOut.mul(vars.collateral.liqBonus).div(BASIS_POINTS);
            // if we don't have enough for [complete] bonus, take partial bonus
            if(vars.ltv.mul(vars.collateral.liqBonus).div(BASIS_POINTS) > SCALER){
                vars.penalty = vars.amountOut.mul(vars.ltv.mul(vars.collateral.liqBonus).div(BASIS_POINTS).sub(SCALER)).div(SCALER);
            } else {
                vars.refundOut = vars.amountOut.mul(SCALER.sub(vars.ltv.mul(vars.collateral.liqBonus).div(BASIS_POINTS))).div(SCALER);
            }
            vars.fee = vars.penalty.mul(vars.collateral.liqProtocolFee).div(BASIS_POINTS);
        }

        accountCollateralBalance[_account][_outAsset] = accountCollateralBalance[_account][_outAsset].sub(vars.amountOut.add(vars.penalty));

        // Add collateral to liquidator
        accountCollateralBalance[_liquidator][_outAsset] = accountCollateralBalance[_liquidator][_outAsset].add(vars.amountOut.add(vars.penalty).sub(vars.fee));

        // Transfer fee to vault
        if(vars.fee > 0){
            require(transferOut(_outAsset, synthex.vault(), vars.fee) == vars.fee, "fee transfer failed");
        }
        // Transfer refund to user
        if(vars.refundOut > 0){
            require(transferOut(_outAsset, _account, vars.refundOut) == vars.refundOut, "refund transfer failed");
        }

        vars.amountUSD = vars.amountOut.toUSD(vars.prices[1]);
        _burn(_account, totalSupply().mul(vars.amountUSD).div(getTotalDebtUSD()));

        return vars.amountUSD.toToken(vars.prices[0]);
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns the list of synths in the pool
     */
    function getSynths() virtual override public view returns (address[] memory) {
        return synthsList;
    }

    /**
     * @dev Get the total adjusted position of an account: E(amount of an asset)*(volatility ratio of the asset)
     * @param _account The address of the account
     * @return liq liquidity The total debt of the account
     */
    function getAccountLiquidity(address _account) virtual override public view returns(AccountLiquidity memory liq) {
        VarsLiquidity memory vars;
        // Read and cache the price oracle
        vars.oracle = IPriceOracle(priceOracle);

        // Iterate over all the collaterals of the account
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            vars.collateral = accountCollaterals[_account][i];
            vars.price = vars.oracle.getAssetPrice(vars.collateral);
            // Add the collateral amount
            // AdjustedCollateralAmountUSD = CollateralAmount * Price * volatilityRatio
            liq.liquidity += int(accountCollateralBalance[_account][vars.collateral]
                .mul(collaterals[vars.collateral].baseLTV)
                .div(BASIS_POINTS)                      // adjust for volatility ratio
                .toUSD(vars.price));
            // collateralAmountUSD = CollateralAmount * Price 
            liq.collateral = liq.collateral.add(
                accountCollateralBalance[_account][vars.collateral]
                .toUSD(vars.price)
            );
        }

        liq.debt = getUserDebtUSD(_account);
        liq.liquidity -= int(liq.debt);
    }

    /**
     * @dev Get the total debt of a trading pool
     * @return totalDebt The total debt of the trading pool
     */
    function getTotalDebtUSD() virtual override public view returns(uint totalDebt) {
        // Get the list of synths in this trading pool
        address[] memory _synths = getSynths();

        totalDebt = 0;
        // Fetch and cache oracle address
        IPriceOracle _oracle = priceOracle;
        // Iterate through the list of synths and add each synth's total supply in USD to the total debt
        for(uint i = 0; i < _synths.length; i++){
            address synth = _synths[i];
            // synthDebt = synthSupply * price
            totalDebt = totalDebt.add(
                ERC20X(synth).totalSupply().toUSD(_oracle.getAssetPrice(synth))
            );
        }
    }

    /**
     * @dev Get the debt of an account in this trading pool
     * @param _account The address of the account
     * @return The debt of the account in this trading pool
     */
    function getUserDebtUSD(address _account) virtual override public view returns(uint){
        // If totalShares == 0, there's zero pool debt
        if(totalSupply() == 0){
            return 0;
        }
        // Get the debt of the account in the trading pool, based on its debt share balance
        return balanceOf(_account).mul(getTotalDebtUSD()).div(totalSupply()); 
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    modifier onlyL1Admin() {
        require(synthex.isL1Admin(msg.sender), "Only callable by L1 admin");
        _;
    }

    modifier onlyL2Admin() {
        require(synthex.isL2Admin(msg.sender), "Only callable by L2 admin");
        _;
    }
    /**
     * @notice Set the price oracle
     * @param _priceOracle The address of the price oracle
     * @dev Only callable by L1 admin
     */
    function setPriceOracle(address _priceOracle) external onlyL1Admin {
        priceOracle = IPriceOracle(_priceOracle);
        emit PriceOracleUpdated(_priceOracle);
    }

    function setIssuerAlloc(uint _issuerAlloc) external onlyL1Admin {
        issuerAlloc = _issuerAlloc;
        emit IssuerAllocUpdated(_issuerAlloc);
    }

    function setFeeToken(address _feeToken) external onlyL1Admin {
        feeToken = _feeToken;
        emit FeeTokenUpdated(_feeToken);
    }
    /**
     * @notice Pause the contract 
     * @dev Only callable by L2 admin
     */
    function pause() public onlyL2Admin {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only callable by L2 admin
     */
    function unpause() public onlyL2Admin {
        _unpause();
    }

    
    /**
     * @notice Update collateral params
     * @notice Only governance module or l2Admin (in case of emergency) can update collateral params
     */
    function updateCollateral(address _collateral, Collateral memory _params) virtual override public onlyL1Admin {
        Collateral storage collateral = collaterals[_collateral];
        // if max deposit is less than total deposits, set max deposit to total deposits
        if(_params.cap < collateral.totalDeposits){
            _params.cap = collateral.totalDeposits;
        }
        // update collateral params
        collateral.cap = _params.cap;
        require(_params.baseLTV >= 0 && _params.baseLTV <= BASIS_POINTS, "SyntheX: Invalid baseLTV");
        collateral.baseLTV = _params.baseLTV;
        require(_params.liqThreshold >= _params.baseLTV && _params.liqThreshold <= BASIS_POINTS, "SyntheX: Invalid liquidationThreshold");
        collateral.liqThreshold = _params.liqThreshold;
        require(_params.liqBonus >= BASIS_POINTS && _params.liqBonus <= BASIS_POINTS.add(BASIS_POINTS.sub(_params.liqThreshold)), "SyntheX: Invalid liquidationBonus");
        collateral.liqBonus = _params.liqBonus;
        require(_params.liqProtocolFee < BASIS_POINTS, "SyntheX: Invalid liqProtocolFee");
        collateral.liqProtocolFee = _params.liqProtocolFee;

        collateral.isEnabled = _params.isEnabled;

        emit CollateralParamsUpdated(_collateral, _params.cap, _params.baseLTV, _params.liqThreshold, _params.liqBonus, _params.liqProtocolFee, _params.isEnabled);
    } 

    /**
     * @dev Add a new synth to the pool
     * @notice Only the owner can call this function
     */
    function addSynth(address _synth, uint mintFee, uint burnFee) external onlyL1Admin {
        // Add the synth to the list of synths
        synthsList.push(_synth);
        // Update synth params
        updateSynth(_synth, Synth(true, mintFee, burnFee));
    }

     /**
        * @dev Update synth params
      */
    function updateSynth(address _synth, Synth memory _params) virtual override public onlyL1Admin {
        // Update synth params
        synths[_synth].isEnabled = _params.isEnabled;
        synths[_synth].mintFee = _params.mintFee;
        synths[_synth].burnFee = _params.burnFee;

        // Emit event on synth enabled
        emit SynthUpdated(_synth, _params.isEnabled, _params.mintFee, _params.burnFee);
    }

    /**
     * @dev Removes the synth from the pool
     * @param _synth The address of the synth to remove
     * @notice Removes from synthList => would not contribute to pool debt
     */
    function removeSynth(address _synth) virtual override public onlyL1Admin {
        synths[_synth].isEnabled = false;
        for (uint i = 0; i < synthsList.length; i++) {
            if (synthsList[i] == _synth) {
                synthsList[i] = synthsList[synthsList.length - 1];
                synthsList.pop();
                emit SynthRemoved(_synth);
                break;
            } 
        }
    }
}