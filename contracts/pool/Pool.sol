// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../synth/IERC20X.sol";
import "./IPool.sol";
import "../libraries/Errors.sol";
import "../libraries/PriceConvertor.sol";
import "./PoolStorage.sol";
import "../synthex/ISyntheX.sol";
import "../utils/interfaces/IWETH.sol";

import "../libraries/PoolLogic.sol";
import "../libraries/CollateralLogic.sol";
import "../libraries/SynthLogic.sol";

/**
 * @title Pool
 * @notice Pool contract to manage collaterals and debt 
 * @author Prasad <prasad@chainscore.finance>
 */
contract Pool is 
    Initializable,
    IPool, 
    PoolStorage, 
    ERC20Upgradeable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    UUPSUpgradeable
{
    /// @notice Using Math for uint256 to calculate minimum and maximum
    using MathUpgradeable for uint256;
    /// @notice Using SafeERC20 for IERC20 to prevent reverts
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The address of the address storage contract
    /// @notice Stored here instead of PoolStorage to avoid Definition of base has to precede definition of derived contract
    ISyntheX public synthex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /// @dev Initialize the contract
    function initialize(string memory _name, string memory _symbol, address _synthex, address weth) public initializer {
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        // check if valid address
        require(ISyntheX(_synthex).supportsInterface(type(ISyntheX).interfaceId), Errors.INVALID_ADDRESS);
        // set addresses
        synthex = ISyntheX(_synthex);

        WETH_ADDRESS = weth;
        
        // paused till (1) collaterals are added, (2) synths are added and (3) feeToken is set
        _pause();
    }

    ///@notice required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyL1Admin {}

    // Support IPool interface
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IPool).interfaceId;
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
        CollateralLogic.enterCollateral(
            _collateral,
            collaterals,
            accountMembership,
            accountCollaterals
        );
    }

    /**
     * @notice Exit a collateral
     * @param _collateral The address of the collateral
     */
    function exitCollateral(address _collateral) virtual override public {
        CollateralLogic.exitCollateral(
            _collateral,
            accountMembership,
            accountCollaterals
        );
        require(getAccountLiquidity(msg.sender).liquidity >= 0, Errors.INSUFFICIENT_COLLATERAL);
    }

    /**
     * @notice Deposit ETH
     */
    function depositETH(address _account) virtual override public payable {
        CollateralLogic.depositETH(
            _account, 
            WETH_ADDRESS, 
            msg.value, 
            collaterals, 
            accountMembership, 
            accountCollateralBalance, 
            accountCollaterals
        );
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     * @param _approval The amount of collateral to approve
     */
    function depositWithPermit(
        address _collateral, 
        uint _amount,
        address _account,
        uint _approval, 
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) virtual override public whenNotPaused {
        CollateralLogic.depositWithPermit(
            _account, 
            _collateral, 
            _amount, 
            _approval, 
            _deadline, 
            _v, 
            _r, 
            _s, 
            collaterals, 
            accountMembership, 
            accountCollateralBalance, 
            accountCollaterals
        );
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     */
    function deposit(address _collateral, uint _amount, address _account) virtual override public whenNotPaused {
        CollateralLogic.depositERC20(
            _account, 
            _collateral, 
            _amount, 
            collaterals, 
            accountMembership, 
            accountCollateralBalance, 
            accountCollaterals
        );
    }

    /**
     * @notice Withdraw collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to withdraw
     */
    function withdraw(address _collateral, uint _amount, bool unwrap) virtual override public {
        // Process withdrawal
        CollateralLogic.withdraw(
            _collateral, 
            _amount, 
            getAccountLiquidity(msg.sender),
            collaterals,
            accountCollateralBalance
        );
        // Transfer collateral to user
        transferOut(_collateral, msg.sender, _amount, unwrap);
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
     * @param _synthIn The address of the synth
     * @param _amountIn Amount of synth
     * @dev Only Active Synth (ERC20X) contract can be issued
     */
    function mint(address _synthIn, uint _amountIn, address _to) virtual override whenNotPaused external returns(uint) {
        uint mintAmount = SynthLogic.commitMint(
            SynthLogic.MintVars(
                _to,
                _amountIn, 
                priceOracle, 
                _synthIn, 
                feeToken, 
                balanceOf(msg.sender),
                totalSupply(),
                getTotalDebtUSD(),
                getAccountLiquidity(msg.sender),
                synths[_synthIn],
                issuerAlloc,
                synthex
            )
        );

        _mint(msg.sender, mintAmount);

        // vars.tokens = new address[](2);
        // vars.tokens[0] = _synthIn;
        // vars.tokens[1] = feeToken;
        // vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        // // check borrow capacity
        // int _borrowCapacity = getAccountLiquidity(msg.sender).liquidity;
        // require(_borrowCapacity > 0, Errors.INSUFFICIENT_COLLATERAL);
 
        // // Amount of debt to issue (in usd, including mintFee)
        // uint amountUSD = _amountIn.toUSD(vars.prices[0]);
        // uint amountPlusFeeUSD = amountUSD + (amountUSD * (synths[_synthIn].mintFee) / (BASIS_POINTS));
        // if(_borrowCapacity < int(amountPlusFeeUSD)){
        //     amountPlusFeeUSD = uint(_borrowCapacity);
        // }

        // // call for reward distribution before minting
        // synthex.distribute(msg.sender, totalSupply(), balanceOf(msg.sender));

        // if(totalSupply() == 0){
        //     // Mint initial debt tokens
        //     _mint(msg.sender, amountPlusFeeUSD);
        // } else {
        //     // Calculate the amount of debt tokens to mint
        //     // debtSharePrice = totalDebt / totalSupply
        //     // mintAmount = amountUSD / debtSharePrice 
        //     uint mintAmount = amountPlusFeeUSD * totalSupply() / getTotalDebtUSD();
        //     // Mint the debt tokens
        //     _mint(msg.sender, mintAmount);
        // }

        // // Amount * (fee * issuerAlloc) is burned from global debt
        // // Amount * (fee * (1 - issuerAlloc)) to vault
        // // Fee amount of feeToken: amountUSD * fee * (1 - issuerAlloc) / feeTokenPrice
        // amountUSD = amountPlusFeeUSD * (BASIS_POINTS) / (BASIS_POINTS + (synths[_synthIn].mintFee));
        // _amountIn = amountUSD.toToken(vars.prices[0]);

        // uint feeAmount = (
        //     (amountPlusFeeUSD - amountUSD)      // total fee amount in USD
        //     * (BASIS_POINTS - issuerAlloc)      // multiplying (1 - issuerAlloc)
        //     / (BASIS_POINTS))                   // for multiplying issuerAlloc
        //     .toToken(vars.prices[1]             // to feeToken amount
        // );                           
        
        // // Mint FEE tokens to vault
        // address vault = synthex.vault();
        // if(vault != address(0)) {
        //     IERC20X(feeToken).mint(
        //         vault,
        //         feeAmount
        //     );
        // }

        // // return the amount of synths to issue
        // IERC20X(_synthIn).mint(msg.sender, _amountIn);

        // return _amountIn;
    }

    /**
     * @notice Burn synths from the user
     * @param _synthIn User whose debt is being burned
     * @param _amountIn The amount of synths to burn
     * @return burnAmount The amount of synth burned
     * @notice The amount of synths to burn is calculated based on the amount of debt tokens burned
     * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
     */
    function burn(address _synthIn, uint _amountIn) virtual override whenNotPaused external returns(uint burnAmount) {
        burnAmount = SynthLogic.commitBurn(
            SynthLogic.BurnVars(
                _amountIn, 
                priceOracle, 
                _synthIn, 
                feeToken, 
                balanceOf(msg.sender),
                totalSupply(),
                getUserDebtUSD(msg.sender),
                getTotalDebtUSD(),
                synths[_synthIn],
                issuerAlloc,
                synthex
            )
        );
        
        _burn(msg.sender, burnAmount);

        // DataTypes.Vars_Burn memory vars;
        // DataTypes.Synth memory synth = synths[_synth];
        // // check if synth is valid
        // if(!synth.isActive) require(synth.isDisabled, Errors.ASSET_NOT_ENABLED);

        // vars.tokens = new address[](2);
        // vars.tokens[0] = _synth;
        // vars.tokens[1] = feeToken;
        // vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        // // amount of debt to burn (in usd, including burnFee)
        // // amountUSD = amount * price / (1 + burnFee)
        // uint amountUSD = _amount.toUSD(vars.prices[0]) * (BASIS_POINTS) / (BASIS_POINTS + synth.burnFee);
        // // ensure user has enough debt to burn
        // uint debt = getUserDebtUSD(msg.sender);
        // if(debt < amountUSD){
        //     // amount = debt + debt * burnFee / BASIS_POINTS
        //     _amount = (debt + (debt * (synth.burnFee) / (BASIS_POINTS))).toToken(vars.prices[0]);
        //     amountUSD = debt;
        // }
        // // ensure user has enough debt to burn
        // if(amountUSD == 0) return 0;

        // // call for reward distribution
        // synthex.distribute(msg.sender, totalSupply(), balanceOf(msg.sender));

        // _burn(msg.sender, totalSupply() * amountUSD / getTotalDebtUSD());

        // // Mint fee * (1 - issuerAlloc) to vault
        // uint feeAmount = (
        //     (amountUSD * synth.burnFee * (BASIS_POINTS - issuerAlloc) / (BASIS_POINTS)) 
        //     / BASIS_POINTS          // for multiplying burnFee
        // ).toToken(vars.prices[1]);  // to feeToken amount

        // address vault = synthex.vault();
        // if(vault != address(0)) {
        //     IERC20X(feeToken).mint(
        //         vault,
        //         feeAmount
        //     );
        // }

        // IERC20X(_synth).burn(msg.sender, _amount);

        // return _amount;
    }

    /**
     * @notice Exchange a synthetic asset for another
     * @param _synthIn The address of the synthetic asset to exchange
     * @param _amount The amount of synthetic asset to exchangs
     * @param _synthOut The address of the synthetic asset to receive
     * @param _kind The type of exchange to perform
     * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
     */
    function swap(address _synthIn, uint _amount, address _synthOut, DataTypes.SwapKind _kind, address _to) virtual override whenNotPaused external returns(uint[2] memory) {
        return SynthLogic.commitSwap(
            SynthLogic.SwapVars(
                _to,
                _synthIn,
                _synthOut,
                _amount, 
                _kind,
                priceOracle,
                feeToken,
                synths[_synthIn],
                synths[_synthOut],
                issuerAlloc,
                synthex
            )
        );
        
        // // check if enabled synth is calling
        // // should be able to swap out of disabled (inactive) synths
        // if(!synths[_synthIn].isActive) require(synths[_synthIn].isDisabled, Errors.ASSET_NOT_ENABLED);
        // // ensure exchange is not to same synth
        // require(_synthIn != _synthOut, Errors.INVALID_ARGUMENT);

        // address[] memory t = new address[](3);
        // t[0] = _synthIn;
        // t[1] = _synthOut;
        // t[2] = feeToken;
        // uint[] memory prices = priceOracle.getAssetsPrices(t);

        // uint amountUSD = _amountIn.toUSD(prices[0]);
        // uint fee = amountUSD * (synths[_synthOut].mintFee + synths[_synthIn].burnFee) / BASIS_POINTS;
        // uint amountOut = (amountUSD - fee).toToken(prices[1]);

        // // 1. Mint (amount - fee) toSynth to recipient
        // IERC20X(_synthOut).mint(msg.sender, amountOut);
        // // 2. Mint fee * (1 - issuerAlloc) (in feeToken) to vault
        // address vault = synthex.vault();
        // if(vault != address(0)) {
        //     IERC20X(feeToken).mint(
        //         vault,
        //         (fee * (BASIS_POINTS - issuerAlloc)        // multiplying (1 - issuerAlloc)
        //         / (BASIS_POINTS))                           // for multiplying issuerAlloc
        //         .toToken(prices[2])
        //     );
        // }
        // // 3. Burn all fromSynth
        // IERC20X(_synthIn).burn(msg.sender, _amountIn);

        // return amountOut;
    }

    // /**
    //  * @notice Exchange a synthetic asset for another
    //  * @param _synthIn The address of the synthetic asset to exchange
    //  * @param _amountOut The amount of synthetic asset to output
    //  * @param _synthOut The address of the synthetic asset to receive
    //  * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
    //  */
    // function swapExactAmountOut(address _synthIn, uint _amountOut, address _synthOut) virtual override whenNotPaused external returns(uint) {
    //     return SwapLogic.commitSwap(
    //         SwapLogic.SwapVars(
    //             _synthIn,
    //             _synthOut,
    //             _amountOut, 
    //             SwapLogic.SwapKind.GIVEN_OUT,
    //             priceOracle,
    //             feeToken,
    //             synths[_synthIn],
    //             synths[_synthOut],
    //             issuerAlloc,
    //             synthex
    //         )
    //     );
        // check if enabled synth is calling
        // should be able to swap out of disabled (inactive) synths
        // if(!synths[_synthIn].isActive) require(synths[_synthIn].isDisabled, Errors.ASSET_NOT_ENABLED);
        // // ensure exchange is not to same synth
        // require(_synthIn != _synthOut, Errors.INVALID_ARGUMENT);

        // address[] memory t = new address[](3);
        // t[0] = _synthIn;
        // t[1] = _synthOut;
        // t[2] = feeToken;
        // uint[] memory prices = priceOracle.getAssetsPrices(t);

        // uint amountUSD = _amountOut.toUSD(prices[1]);
        // uint fee = amountUSD - amountUSD * BASIS_POINTS / (BASIS_POINTS + synths[_synthOut].mintFee + synths[_synthIn].burnFee);
        // uint amountIn = (amountUSD + fee).toToken(prices[1]);

        // // 1. Mint (amount - fee) toSynth to recipient
        // IERC20X(_synthOut).mint(msg.sender, _amountOut);
        // // 2. Mint fee * (1 - issuerAlloc) (in feeToken) to vault
        // address vault = synthex.vault();
        // if(vault != address(0)) {
        //     IERC20X(feeToken).mint(
        //         vault,
        //         (fee * (BASIS_POINTS - issuerAlloc)        // multiplying (1 - issuerAlloc)
        //         / (BASIS_POINTS))                           // for multiplying issuerAlloc
        //         .toToken(prices[2])
        //     );
        // }
        // // 3. Burn all fromSynth
        // IERC20X(_synthIn).burn(msg.sender, amountIn);

        // return amountIn;
    // }

    /**
     * @notice Liquidate a user's debt
     * @param _synthIn The address of the liquidator
     * @param _account The address of the account to liquidate
     * @param _amount The amount of debt (in repaying synth) to liquidate
     * @param _outAsset The address of the collateral asset to receive
     * @dev Only Active/Disabled Synth (ERC20X) contract can call this function
     */
    function liquidate(address _synthIn, address _account, uint _amount, address _outAsset) virtual override whenNotPaused external {
        require(accountMembership[_outAsset][_account], Errors.ACCOUNT_NOT_ENTERED);
        (uint refundOut, uint burnAmount) = SynthLogic.commitLiquidate(
            SynthLogic.LiquidateVars(
                _amount, 
                _account,
                priceOracle, 
                _synthIn, 
                _outAsset,
                feeToken,
                totalSupply(),
                getTotalDebtUSD(),
                getAccountLiquidity(_account),
                synths[_synthIn],
                collaterals[_outAsset],
                issuerAlloc,
                synthex
            ),
            accountCollateralBalance
        );
        // Transfer refund to user
        if(refundOut > 0){
            transferOut(_outAsset, _account, refundOut, false);
        }
        // Burn debt
        _burn(_account, burnAmount);

        // DataTypes.Vars_Liquidate memory vars;
        // // check if synth is enabled
        // if(!synths[_synthIn].isActive) require(synths[_synthIn].isDisabled, Errors.ASSET_NOT_ENABLED);

        // // Get account liquidity
        // vars.liq = getAccountLiquidity(_account);
        // vars.collateral = collaterals[_outAsset];
        // require(vars.liq.debt > 0, Errors.INSUFFICIENT_DEBT);
        // require(vars.liq.collateral > 0, Errors.INSUFFICIENT_COLLATERAL);
        // vars.ltv = vars.liq.debt * (SCALER) / (vars.liq.collateral);
        // require(vars.ltv > vars.collateral.liqThreshold * SCALER / BASIS_POINTS, Errors.ACCOUNT_BELOW_LIQ_THRESHOLD);
        // // Ensure user has entered the collateral market
        // require(accountMembership[_outAsset][_account], Errors.ACCOUNT_NOT_ENTERED);

        // vars.tokens = new address[](3);
        // vars.tokens[0] = _synthIn;
        // vars.tokens[1] = _outAsset;
        // vars.tokens[2] = feeToken;
        // vars.prices = priceOracle.getAssetsPrices(vars.tokens);

        // // Amount of debt to burn (in usd, excluding burnFee)
        // vars.amountUSD = _amount.toUSD(vars.prices[0]) * (BASIS_POINTS)/(BASIS_POINTS + synths[_synthIn].burnFee);
        // if(vars.liq.debt < vars.amountUSD) {
        //     vars.amountUSD = vars.liq.debt;
        // }

        // // Amount of debt to burn (in terms of collateral)
        // vars.amountOut = vars.amountUSD.toToken(vars.prices[1]);
        // vars.penalty = 0;
        // vars.refundOut = 0;

        // // Sieze collateral
        // uint balanceOut = accountCollateralBalance[_account][_outAsset];
        // if(vars.ltv > SCALER){
        //     // if ltv > 100%, take all collateral, no penalty
        //     if(vars.amountOut > balanceOut){
        //         vars.amountOut = balanceOut;
        //     }
        // } else {
        //     // take collateral based on ltv, and apply penalty
        //     balanceOut = balanceOut * vars.ltv / SCALER;
        //     if(vars.amountOut > balanceOut){
        //         vars.amountOut = balanceOut;
        //     }
        //     // penalty = amountOut * liqBonus
        //     vars.penalty = vars.amountOut * (vars.collateral.liqBonus - BASIS_POINTS) / (BASIS_POINTS);

        //     // if we don't have enough for [complete] bonus, take partial bonus
        //     if(vars.ltv * vars.collateral.liqBonus / BASIS_POINTS > SCALER){
        //         // penalty = amountOut * (1 - ltv)/ltv 
        //         vars.penalty = vars.amountOut * (SCALER - vars.ltv) / (vars.ltv);
        //     }
        //     // calculate refund if we have enough for bonus + extra
        //     else {
        //         // refundOut = amountOut * (1 - ltv * liqBonus)
        //         vars.refundOut = vars.amountOut * (SCALER - (vars.ltv * vars.collateral.liqBonus / BASIS_POINTS)) / SCALER;
        //     }
        // }

        // accountCollateralBalance[_account][_outAsset] -= (vars.amountOut + vars.penalty + vars.refundOut);

        // // Add collateral to liquidator
        // accountCollateralBalance[msg.sender][_outAsset]+= (vars.amountOut + vars.penalty);

        // // Transfer refund to user
        // if(vars.refundOut > 0){
        //     transferOut(_outAsset, _account, vars.refundOut, false);
        // }

        // vars.amountUSD = vars.amountOut.toUSD(vars.prices[1]);
        // _burn(_account, totalSupply() * vars.amountUSD / getTotalDebtUSD());

        // // send (burn fee - issuerAlloc) in feeToken to vault
        // uint fee = vars.amountUSD * (synths[_synthIn].burnFee) / (BASIS_POINTS);
        // address vault = synthex.vault();
        // if(vault != address(0)) {
        //     IERC20X(feeToken).mint(
        //         vault,
        //         (fee * (BASIS_POINTS - issuerAlloc)        // multiplying (1 - issuerAlloc)
        //         / BASIS_POINTS)                            // for multiplying issuerAlloc
        //         .toToken(vars.prices[2])
        //     );
        // }

        // emit Liquidate(msg.sender, _account, _outAsset, vars.amountOut, vars.penalty, vars.refundOut);

        // // amount (in synth) plus burn fee
        // IERC20X(_synthIn).burn(msg.sender, vars.amountUSD.toToken(vars.prices[0]) * (BASIS_POINTS + synths[_synthIn].burnFee) / (BASIS_POINTS));
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Get the total adjusted position of an account: E(amount of an asset)*(volatility ratio of the asset)
     * @param _account The address of the account
     * @return liq liquidity The total debt of the account
     */
    function getAccountLiquidity(address _account) virtual override public view returns(DataTypes.AccountLiquidity memory liq) {
        return PoolLogic.getAccountLiquidity(priceOracle, accountCollaterals[_account], accountCollateralBalance[_account], collaterals, getUserDebtUSD(_account));
    }

    /**
     * @dev Get the total debt of a trading pool
     * @return totalDebt The total debt of the trading pool
     */
    function getTotalDebtUSD() virtual override public view returns(uint totalDebt) {
        return PoolLogic.getTotalDebtUSD(synthsList, priceOracle);
    }

    /**
     * @dev Get the debt of an account in this trading pool
     * @param _account The address of the account
     * @return The debt of the account in this trading pool
     */
    function getUserDebtUSD(address _account) virtual override public view returns(uint){
        return PoolLogic.getUserDebtUSD(
            totalSupply(),
            balanceOf(_account),
            getTotalDebtUSD()
        );
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
    function updateCollateral(address _collateral, DataTypes.Collateral memory _params) virtual override public onlyL1Admin {
        PoolLogic.update(collaterals, _collateral, _params);
    }

    /**
     * @dev Add a new synth to the pool
     * @notice Only L1Admin can call this function
     */
    function addSynth(address _synth, DataTypes.Synth memory _params) external override onlyL1Admin {
        PoolLogic.add(synths, synthsList, _synth, _params);
    }

    /**
     * @dev Update synth params
     * @notice Only L1Admin can call this function
     */
    function updateSynth(address _synth, DataTypes.Synth memory _params) virtual override public onlyL1Admin {
        PoolLogic.update(synths, _synth, _params);
    }

    /**
     * @dev Removes the synth from the pool
     * @param _synth The address of the synth to remove
     * @notice Removes from synthList => would not contribute to pool debt
     * @notice Only L1Admin can call this function
     */
    function removeSynth(address _synth) virtual override public onlyL1Admin {
        PoolLogic.remove(synths, synthsList, _synth);
    }
}