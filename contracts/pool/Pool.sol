// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import "../synth/ERC20X.sol";
import "./IPool.sol";
import "../libraries/Errors.sol";
import "../libraries/PriceConvertor.sol";
import "./PoolStorage.sol";
import "../synthex/ISyntheX.sol";
import "../utils/interfaces/IWETH.sol";

import "hardhat/console.sol";

/**
 * @title Pool
 * @notice Pool contract to manage collaterals and debt 
 * @author Prasad <prasad@chainscore.finance>
 */
contract Pool is IPool, PoolStorage, ERC20Upgradeable, ERC165Upgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Using Math for uint256 to calculate minimum and maximum
    using MathUpgradeable for uint256;
    /// @notice for converting token prices
    using PriceConvertor for uint256;
    /// @notice Using SafeERC20 for IERC20 to prevent reverts
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The address of the address storage contract
    /// @notice Stored here instead of PoolStorage to avoid Definition of base has to precede definition of derived contract
    ISyntheX public synthex;
    
    /// @dev Initialize the contract
    function initialize(string memory _name, string memory _symbol, address _synthex, address weth) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __ReentrancyGuard_init();

        // check if valid address
        require(ISyntheX(_synthex).supportsInterface(type(ISyntheX).interfaceId), Errors.INVALID_ADDRESS);
        // set addresses
        synthex = ISyntheX(_synthex);

        WETH_ADDRESS = weth;
        
        // paused till (1) collaterals are added, (2) synths are added and (3) feeToken is set
        _pause();
    }

    // Support IPool interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IPool) returns (bool) {
        return interfaceId == type(IPool).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Override to disable transfer
    function _transfer(address, address, uint256) internal virtual override {
        revert(Errors.TRANSFER_FAILED);
    }

    /* -------------------------------------------------------------------------- */
    /*                              External Functions                            */
    /* -------------------------------------------------------------------------- */
    receive() external payable {}
    fallback() external payable {}

    /**
     * @notice Enable a collateral
     * @param _collateral The address of the collateral
     */
    function enterCollateral(address _collateral) virtual override public {
        // get collateral pool
        Collateral storage collateral = collaterals[_collateral];

        require(collateral.isActive, Errors.ASSET_NOT_ACTIVE);

        // ensure that the user is not already in the pool
        require(!accountMembership[_collateral][msg.sender], Errors.ACCOUNT_ALREADY_ENTERED);
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

        require(getAccountLiquidity(msg.sender).liquidity >= 0, Errors.INSUFFICIENT_COLLATERAL);
    }

    /**
     * @notice Deposit ETH
     */
    function depositETH() virtual override public payable {
        // check if param _amount == msg.value sent with tx
        require(msg.value > 0, Errors.ZERO_AMOUNT);
        // wrap ETH
        IWETH(WETH_ADDRESS).deposit{value: msg.value}();
        depositInternal(msg.sender, WETH_ADDRESS, msg.value);
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
        require(collateral.isActive, Errors.ASSET_NOT_ACTIVE);

        // ensure user has entered the market
        if(!accountMembership[_collateral][_account]){
            enterCollateral(_collateral);
        }
        
        // Update balance
        accountCollateralBalance[_account][_collateral] += _amount;

        // Update collateral supply
        collateral.totalDeposits += _amount;
        require(collateral.totalDeposits <= collateral.cap, Errors.EXCEEDED_MAX_CAPACITY);

        // emit event
        emit Deposit(_account, _collateral, _amount);
    }

    /**
     * @notice Withdraw collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to withdraw
     */
    function withdraw(address _collateral, uint _amount, bool unwrap) virtual override public {
        // Process withdraw
        withdrawInternal(msg.sender, _collateral, _amount);
        // Transfer collateral to user
        transferOut(_collateral, msg.sender, _amount, unwrap);
    }

    function withdrawInternal(address _account, address _collateral, uint _amount) internal whenNotPaused {
        Collateral storage supply = collaterals[_collateral];
        // check deposit balance
        uint depositBalance = accountCollateralBalance[_account][_collateral];
        // allow only upto their deposit balance
        require(depositBalance >= _amount, Errors.INSUFFICIENT_BALANCE);
        // Update balance
        accountCollateralBalance[_account][_collateral] = depositBalance - (_amount);
        // Update collateral supply
        supply.totalDeposits -= (_amount);
        // check for positive liquidity
        require(getAccountLiquidity(_account).liquidity >= 0, Errors.INSUFFICIENT_COLLATERAL);
        // Emit successful event
        emit Withdraw(_account, _collateral, _amount);
    }

    /**
     * @notice Transfer asset out to address
     * @param _asset The address of the asset
     * @param recipient The address of the recipient
     * @param _amount Amount
     */
    function transferOut(address _asset, address recipient, uint _amount, bool unwrap) internal nonReentrant {
        if(_asset == WETH_ADDRESS && unwrap){
            IWETH(WETH_ADDRESS).withdraw(_amount);
            (bool success, ) = recipient.call{value: _amount}("");
            require(success, Errors.TRANSFER_FAILED);
        } else {
            IERC20Upgradeable(_asset).safeTransfer(recipient, _amount);
        }
    }

    /**
     * @notice Issue synths to the user
     * @param _account The address of the user to issue synths to
     * @param _amount Amount of synth
     * @dev Only Active Synth (ERC20X) contract can call this function
     */
    function commitMint(address _account, uint _amount) virtual override whenNotPaused external returns(uint) {
        Vars_Mint memory vars;
        // check if synth is enabled
        require(synths[msg.sender].isActive, Errors.ASSET_NOT_ACTIVE);

        vars.tokens = new address[](2);
        vars.tokens[0] = msg.sender;
        vars.tokens[1] = feeToken;
        vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        int _borrowCapacity = getAccountLiquidity(_account).liquidity;
        
        require(_borrowCapacity > 0, Errors.INSUFFICIENT_COLLATERAL);

        // 10 cETH * 1000 = 10000 USD
        // +10% fee = 11 cETH debt to issue (11000 USD)
        // 10 cETH minted to user (10000 USD)
        // 1 cETH fee (1000 USD) = 0.5 cETH minted to vault (1-issuerAlloc) + 0.5 cETH not minted (burned) 
        // This would result in net -0.5 cETH ($500) worth of debt issued; i.e. $500 of debt is reduced from pool (for all users)
        
        // Amount of debt to issue (in usd, including mintFee)
        uint amountUSD = _amount.toUSD(vars.prices[0]);
        uint amountPlusFeeUSD = amountUSD + (amountUSD * (synths[msg.sender].mintFee) / (BASIS_POINTS));
        if(_borrowCapacity < int(amountPlusFeeUSD)){
            amountPlusFeeUSD = uint(_borrowCapacity);
        }

        // call for reward distribution before minting
        synthex.distribute(_account, totalSupply(), balanceOf(_account));

        if(totalSupply() == 0){
            // Mint initial debt tokens
            _mint(_account, amountPlusFeeUSD);
        } else {
            // Calculate the amount of debt tokens to mint
            // debtSharePrice = totalDebt / totalSupply
            // mintAmount = amountUSD / debtSharePrice 
            uint mintAmount = amountPlusFeeUSD * totalSupply() / getTotalDebtUSD();
            // Mint the debt tokens
            _mint(_account, mintAmount);
        }

        // Amount * (fee * issuerAlloc) is burned from global debt
        // Amount * (fee * (1 - issuerAlloc)) to vault
        // Fee amount of feeToken: amountUSD * fee * (1 - issuerAlloc) / feeTokenPrice
        amountUSD = amountPlusFeeUSD * (BASIS_POINTS) / (BASIS_POINTS + (synths[msg.sender].mintFee));
        _amount = amountUSD.toToken(vars.prices[0]);

        uint feeAmount = (
            (amountPlusFeeUSD - amountUSD)      // total fee amount in USD
            * (BASIS_POINTS - issuerAlloc)      // multiplying (1 - issuerAlloc)
            / (BASIS_POINTS))                   // for multiplying issuerAlloc
            .toToken(vars.prices[1]             // to feeToken amount
        );                           
        
        // Mint FEE tokens to vault
        address vault = synthex.vault();
        if(vault != address(0)) {
            ERC20X(feeToken).mintInternal(
                vault,
                feeAmount
            );
        }

        // return the amount of synths to issue
        return _amount;
    }

    /**
     * @notice Burn synths from the user
     * @param _account User whose debt is being burned
     * @param _amount The amount of synths to burn
     * @return The amount of synth burned
     * @notice The amount of synths to burn is calculated based on the amount of debt tokens burned
     * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
     */
    function commitBurn(address _account, uint _amount) virtual override whenNotPaused external returns(uint) {
        Vars_Burn memory vars;
        Synth memory synth = synths[msg.sender];
        // check if synth is valid
        if(!synth.isActive) require(synth.isDisabled, Errors.ASSET_NOT_ENABLED);

        vars.tokens = new address[](2);
        vars.tokens[0] = msg.sender;
        vars.tokens[1] = feeToken;
        vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        // amount of debt to burn (in usd, including burnFee)
        // amountUSD = amount * price / (1 + burnFee)
        uint amountUSD = _amount.toUSD(vars.prices[0]) * (BASIS_POINTS) / (BASIS_POINTS + synth.burnFee);
        // ensure user has enough debt to burn
        uint debt = getUserDebtUSD(_account);
        if(debt < amountUSD){
            // amount = debt + debt * burnFee / BASIS_POINTS
            _amount = (debt + (debt * (synth.burnFee) / (BASIS_POINTS))).toToken(vars.prices[0]);
            amountUSD = debt;
        }

        // ensure user has enough debt to burn
        if(amountUSD == 0) return 0;

        // call for reward distribution
        synthex.distribute(_account, totalSupply(), balanceOf(_account));

        _burn(_account, totalSupply() * amountUSD / getTotalDebtUSD());

        // Mint fee * (1 - issuerAlloc) to vault
        uint feeAmount = (
            (amountUSD * synth.burnFee * (BASIS_POINTS - issuerAlloc) / (BASIS_POINTS)) 
            / BASIS_POINTS          // for multiplying burnFee
        ).toToken(vars.prices[1]);  // to feeToken amount

        address vault = synthex.vault();
        if(vault != address(0)) {
            ERC20X(feeToken).mintInternal(
                vault,
                feeAmount
            );
        }

        return _amount;
    }

    /**
     * @notice Exchange a synthetic asset for another
     * @param _amount The amount of synthetic asset to exchange
     * @param _synthTo The address of the synthetic asset to receive
     * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
     */
    function commitSwap(address _recipient, uint _amount, address _synthTo) virtual override whenNotPaused external returns(uint) {
        // check if enabled synth is calling
        // should be able to swap out of disabled (inactive) synths
        if(!synths[msg.sender].isActive) require(synths[msg.sender].isDisabled, Errors.ASSET_NOT_ENABLED);
        // ensure exchange is not to same synth
        require(msg.sender != _synthTo, Errors.INVALID_ARGUMENT);

        address[] memory t = new address[](3);
        t[0] = msg.sender;
        t[1] = _synthTo;
        t[2] = feeToken;
        uint[] memory prices = priceOracle.getAssetsPrices(t);

        uint amountUSD = _amount.toUSD(prices[0]);
        uint fee = amountUSD * (synths[_synthTo].mintFee + synths[msg.sender].burnFee) / BASIS_POINTS;

        // 1. Mint (amount - fee) toSynth to recipient
        ERC20X(_synthTo).mintInternal(_recipient, (amountUSD - fee).toToken(prices[1]));
        // 2. Mint fee * (1 - issuerAlloc) (in feeToken) to vault
        address vault = synthex.vault();
        if(vault != address(0)) {
            ERC20X(feeToken).mintInternal(
                vault,
                (fee * (BASIS_POINTS - issuerAlloc)        // multiplying (1 - issuerAlloc)
                / (BASIS_POINTS))                           // for multiplying issuerAlloc
                .toToken(prices[2])
            );
        }
        // 3. Burn all fromSynth
        return _amount; 
    }

    /**
     * @notice Liquidate a user's debt
     * @param _liquidator The address of the liquidator
     * @param _account The address of the account to liquidate
     * @param _amount The amount of debt (in repaying synth) to liquidate
     * @param _outAsset The address of the collateral asset to receive
     * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
     */
    function commitLiquidate(address _liquidator, address _account, uint _amount, address _outAsset) virtual override whenNotPaused external returns(uint) {
        require(_amount > 0);

        Vars_Liquidate memory vars;
        // check if synth is enabled
        if(!synths[msg.sender].isActive) require(synths[msg.sender].isDisabled, Errors.ASSET_NOT_ENABLED);

        // Get account liquidity
        vars.liq = getAccountLiquidity(_account);
        vars.collateral = collaterals[_outAsset];
        require(vars.liq.debt > 0, Errors.INSUFFICIENT_DEBT);
        require(vars.liq.collateral > 0, Errors.INSUFFICIENT_COLLATERAL);
        vars.ltv = vars.liq.debt * (SCALER) / (vars.liq.collateral);
        require(vars.ltv > vars.collateral.liqThreshold * SCALER / BASIS_POINTS, Errors.ACCOUNT_BELOW_LIQ_THRESHOLD);
        // Ensure user has entered the collateral market
        require(accountMembership[_outAsset][_account], Errors.ACCOUNT_NOT_ENTERED);

        vars.tokens = new address[](3);
        vars.tokens[0] = msg.sender;
        vars.tokens[1] = _outAsset;
        vars.tokens[2] = feeToken;
        vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        // Amount of debt to burn (in usd, excluding burnFee)
        vars.amountUSD = _amount.toUSD(vars.prices[0]) * (BASIS_POINTS)/(BASIS_POINTS + synths[msg.sender].burnFee);
        if(vars.liq.debt < vars.amountUSD) {
            vars.amountUSD = vars.liq.debt;
        }

        // Amount of debt to burn (in terms of collateral)
        vars.amountOut = vars.amountUSD.toToken(vars.prices[1]);
        vars.penalty = 0;
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
            balanceOut = balanceOut * vars.ltv / SCALER;
            if(vars.amountOut > balanceOut){
                vars.amountOut = balanceOut;
            }
            // penalty = amountOut * liqBonus
            vars.penalty = vars.amountOut * (vars.collateral.liqBonus - BASIS_POINTS) / (BASIS_POINTS);

            // if we don't have enough for [complete] bonus, take partial bonus
            if(vars.ltv * vars.collateral.liqBonus / BASIS_POINTS > SCALER){
                // penalty = amountOut * (1 - ltv)/ltv 
                vars.penalty = vars.amountOut * (SCALER - vars.ltv) / (vars.ltv);
            }
            // calculate refund if we have enough for bonus + extra
            else {
                // refundOut = amountOut * (1 - ltv * liqBonus)
                vars.refundOut = vars.amountOut * (SCALER - (vars.ltv * vars.collateral.liqBonus / BASIS_POINTS)) / SCALER;
            }
        }

        accountCollateralBalance[_account][_outAsset] -= (vars.amountOut + vars.penalty + vars.refundOut);

        // Add collateral to liquidator
        accountCollateralBalance[_liquidator][_outAsset]+= (vars.amountOut + vars.penalty);

        // Transfer refund to user
        if(vars.refundOut > 0){
            transferOut(_outAsset, _account, vars.refundOut, false);
        }

        vars.amountUSD = vars.amountOut.toUSD(vars.prices[1]);
        _burn(_account, totalSupply() * vars.amountUSD / getTotalDebtUSD());

        // send (burn fee - issuerAlloc) in feeToken to vault
        uint fee = vars.amountUSD * (synths[msg.sender].burnFee) / (BASIS_POINTS);
        address vault = synthex.vault();
        if(vault != address(0)) {
            ERC20X(feeToken).mintInternal(
                vault,
                (fee * (BASIS_POINTS - issuerAlloc)        // multiplying (1 - issuerAlloc)
                / BASIS_POINTS)                            // for multiplying issuerAlloc
                .toToken(vars.prices[2])
            );
        }

        emit Liquidate(_liquidator, _account, _outAsset, vars.amountOut, vars.penalty, vars.refundOut);

        // amount (in synth) plus burn fee
        return vars.amountUSD.toToken(vars.prices[0]) * (BASIS_POINTS + synths[msg.sender].burnFee) / (BASIS_POINTS);
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
            liq.liquidity += int(
                (accountCollateralBalance[_account][vars.collateral]
                 * (collaterals[vars.collateral].baseLTV)
                 / (BASIS_POINTS))                      // adjust for volatility ratio
                .toUSD(vars.price));
            // collateralAmountUSD = CollateralAmount * Price 
            liq.collateral += (
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
            totalDebt += (
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
        return balanceOf(_account) * getTotalDebtUSD() / totalSupply(); 
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    modifier onlyL1Admin() {
        require(synthex.isL1Admin(msg.sender), Errors.CALLER_NOT_L1_ADMIN);
        _;
    }

    modifier onlyL2Admin() {
        require(synthex.isL2Admin(msg.sender), Errors.CALLER_NOT_L2_ADMIN);
        _;
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
     * @notice Update collateral params
     * @notice Only L1Admin can call this function 
     */
    function updateCollateral(address _collateral, Collateral memory _params) virtual override public onlyL1Admin {
        Collateral storage collateral = collaterals[_collateral];
        // if max deposit is less than total deposits, set max deposit to total deposits
        if(_params.cap < collateral.totalDeposits){
            _params.cap = collateral.totalDeposits;
        }
        // update collateral params
        collateral.cap = _params.cap;
        require(_params.baseLTV >= 0 && _params.baseLTV <= BASIS_POINTS, Errors.INVALID_ARGUMENT);
        collateral.baseLTV = _params.baseLTV;
        require(_params.liqThreshold >= _params.baseLTV && _params.liqThreshold <= BASIS_POINTS, Errors.INVALID_ARGUMENT);
        collateral.liqThreshold = _params.liqThreshold;
        // TODO: CHECK THIS
        require(_params.liqBonus >= BASIS_POINTS && _params.liqBonus <= BASIS_POINTS + (BASIS_POINTS - (_params.liqThreshold)), Errors.INVALID_ARGUMENT);
        collateral.liqBonus = _params.liqBonus;

        collateral.isActive = _params.isActive;

        emit CollateralParamsUpdated(_collateral, _params.cap, _params.baseLTV, _params.liqThreshold, _params.liqBonus, _params.isActive);
    }

    /**
     * @dev Add a new synth to the pool
     * @notice Only L1Admin can call this function
     */
    function addSynth(address _synth, uint mintFee, uint burnFee) external override onlyL1Admin {
        for(uint i = 0; i < synthsList.length; i++){
            require(synthsList[i] != _synth, Errors.ASSET_NOT_ACTIVE);
        }
        // Add the synth to the list of synths
        synthsList.push(_synth);
        // Update synth params
        updateSynth(_synth, Synth(true, false, mintFee, burnFee));
    }

    /**
     * @dev Update synth params
     * @notice Only L1Admin can call this function
     */
    function updateSynth(address _synth, Synth memory _params) virtual override public onlyL1Admin {
        // Update synth params
        synths[_synth].isActive = _params.isActive;
        synths[_synth].isDisabled = _params.isDisabled;
        require(_params.mintFee < BASIS_POINTS, Errors.INVALID_ARGUMENT);
        synths[_synth].mintFee = _params.mintFee;
        require(_params.burnFee < BASIS_POINTS, Errors.INVALID_ARGUMENT);
        synths[_synth].burnFee = _params.burnFee;

        // Emit event on synth enabled
        emit SynthUpdated(_synth, _params.isActive, _params.isDisabled, _params.mintFee, _params.burnFee);
    }

    /**
     * @dev Removes the synth from the pool
     * @param _synth The address of the synth to remove
     * @notice Removes from synthList => would not contribute to pool debt
     * @notice Only L1Admin can call this function
     */
    function removeSynth(address _synth) virtual override public onlyL1Admin {
        synths[_synth].isActive = false;
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