// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./ERC20X.sol";
import "./oracle/PriceOracle.sol";
import "./SyntheX.sol";
import "./system/System.sol";
import "./interfaces/IDebtPool.sol";
import "./libraries/PriceConvertor.sol";
import "./storage/DebtPoolStorage.sol";

import "hardhat/console.sol";

/**
 * @title DebtPool
 * @notice DebtPool contract to manage synths and debt
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 */
contract DebtPool is IDebtPool, ERC20Upgradeable, PausableUpgradeable, DebtPoolStorage {
    /// @notice Using SafeMath for uint256 to prevent overflows and underflows
    using SafeMathUpgradeable for uint256;
    /// @notice Using Math for uint256 to calculate minimum and maximum
    using MathUpgradeable for uint256; 
    /// @notice for converting token prices
    using PriceConvertor for uint256;
    
    /// @dev Initialize the contract
    function initialize(string memory name, string memory symbol, address _system) public initializer {
        __ERC20_init(name, symbol);
        __Pausable_init();
        system = System(_system);
    }

    /// @dev Override to disable transfer
    function _transfer(address, address, uint256) internal virtual override {
        revert("DebtPool: Transfer not allowed");
    }

    /* -------------------------------------------------------------------------- */
    /*                              External Functions                            */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Issue synths to the user
     * @param _account The address of the user to issue synths to
     * @param _amount Amount of synth
     * @notice Only SyntheX can call this function
     */
    function commitMint(address _account, uint _amount) virtual override whenNotPaused external returns(uint) {
        // check if synth is enabled
        require(synths[msg.sender], "SyntheXPool: Synth not enabled");

        IPriceOracle.Price[] memory prices;
        address[] memory t = new address[](2);
        t[0] = msg.sender;
        t[1] = feeToken;
        prices = IPriceOracle(system.priceOracle()).getAssetPrices(t);

        int borrowCapacity = ISyntheX(system.synthex()).commitMint(_account, msg.sender, _amount);
        require(borrowCapacity > 0, "SyntheXPool: Insufficient liquidity");
        
        // amount of debt to issue (in usd, including mintFee)
        uint amountPlusFeeUSD = _amount.toUSD(prices[0]);
        amountPlusFeeUSD = amountPlusFeeUSD.add(amountPlusFeeUSD.mul(mintFee).div(BASIS_POINTS));
        if(borrowCapacity < int(amountPlusFeeUSD)){
            amountPlusFeeUSD = uint(borrowCapacity);
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
        uint initialAmountUSD = amountPlusFeeUSD.mul(BASIS_POINTS).div(BASIS_POINTS.add(mintFee));
        uint feeAmount = amountPlusFeeUSD.sub(initialAmountUSD) // fee amount in USD
            .mul(uint(BASIS_POINTS).sub(issuerAlloc))           // multiplying (1 - issuerAlloc)
            .div(BASIS_POINTS)                                  // for multiplying issuerAlloc
            .toToken(prices[1]);                                // to feeToken amount
        
        // Mint fee
        ERC20X(feeToken).mintInternal(
            system.vault(),
            feeAmount
        );

        // Mint (amount - fee) toSynth to user
        return initialAmountUSD.toToken(prices[0]);
    }

    /**
     * @notice Burn synths from the user
     * @param _account User whose debt is being burned
     * @param _amount The amount of synths to burn
     * @return The amount of synth burned
     * @notice The amount of synths to burn is calculated based on the amount of debt tokens burned
     */
    function commitBurn(address _account, uint _amount) virtual override whenNotPaused external returns(uint) {
        // check if synth is valid
        for(uint i = 0; i < synthsList.length; i++){
            if(synthsList[i] == msg.sender){
                break;
            } else if(i == synthsList.length - 1){
                revert("SyntheXPool: Synth not found");
            }
        }

        IPriceOracle.Price[] memory prices;
        address[] memory t = new address[](2);
        t[0] = msg.sender;
        t[1] = feeToken;
        prices = IPriceOracle(system.priceOracle()).getAssetPrices(t);

        // amount of debt to burn (in usd, including burnFee)
        uint amountUSD = _amount.toUSD(prices[0]);
        amountUSD = amountUSD.mul(BASIS_POINTS).div(BASIS_POINTS.add(burnFee));
        // ensure user has enough debt to burn
        uint debt = getUserDebtUSD(_account);
        if(debt < amountUSD){
            _amount = debt.add(debt.mul(burnFee).div(BASIS_POINTS)).toToken(prices[0]);
            amountUSD = debt;
        }

        // ensure user has enough debt to burn
        if(amountUSD == 0) return 0;

        _burn(_account, totalSupply().mul(amountUSD).div(getTotalDebtUSD()));

        // Mint fee * (1 - issuerAlloc) to vault
        ERC20X(feeToken).mintInternal(
            system.vault(),
            amountUSD.mul(burnFee).mul(uint(BASIS_POINTS).sub(issuerAlloc)).div(BASIS_POINTS).div(BASIS_POINTS).toToken(prices[1])
        );

        return _amount;
    }

    /**
     * @notice Exchange a synthetic asset for another
     * @param _amount The amount of synthetic asset to exchange
     * @param _synthTo The address of the synthetic asset to receive
     */
    function commitSwap(address _account, uint _amount, address _synthTo) virtual override whenNotPaused external returns(uint) {
        // check if synth is enabled
        require(synths[msg.sender], "DebtPool: SynthFrom not enabled");
        require(synths[_synthTo], "DebtPool: SynthTo not enabled");
        // ensure exchange is not to same synth
        require(msg.sender != _synthTo, "DebtPool: Synths are the same");

        IPriceOracle.Price[] memory prices;
        address[] memory t = new address[](3);
        t[0] = msg.sender;
        t[1] = _synthTo;
        t[2] = feeToken;
        prices = IPriceOracle(system.priceOracle()).getAssetPrices(t);

        uint amountUSD = _amount.toUSD(prices[0]);
        uint fee = amountUSD.mul(swapFee).div(BASIS_POINTS);

        // 1. Mint (amount - fee) toSynth to user
        ERC20X(_synthTo).mintInternal(_account, amountUSD.sub(fee).toToken(prices[1]));
        // 2. Mint fee * (1 - issuerAlloc) (in feeToken) to vault
        ERC20X(feeToken).mintInternal(
            system.vault(),     
            fee.mul(uint(BASIS_POINTS).sub(issuerAlloc))        // multiplying (1 - issuerAlloc)
            .div(BASIS_POINTS)                                  // for multiplying issuerAlloc
            .toToken(prices[2])
        );
        // 3. Burn all fromSynth
        return _amount;
    }

    /**
     * @notice Liquidate a user's debt
     */
    function commitLiquidate(address _liquidator, address _account, uint _amount, address _outAsset) virtual override whenNotPaused external returns(uint) {
        // check if synth is enabled
        require(synths[msg.sender], "DebtPool: SynthFrom not enabled");

        IPriceOracle.Price[] memory prices;
        address[] memory t = new address[](3);
        t[0] = msg.sender;
        t[1] = _outAsset;
        prices = IPriceOracle(system.priceOracle()).getAssetPrices(t);

        uint amountUSD = _amount.toUSD(prices[0]);
        uint debtUSD = balanceOf(_account).mul(getTotalDebtUSD()).div(totalSupply());
        // burn only the amount of debt that the user has
        if(debtUSD < amountUSD) {
            _amount = debtUSD.toToken(prices[0]);
        }

        // amount in terms of collateral
        uint amountOut = _amount.t1t2(prices[0], prices[1]); 
        // penalty on amountOut
        uint penalty = amountOut.mul(liquidationPenalty).div(BASIS_POINTS); 
        // fee from penalty to send to vault
        uint reserve = penalty.mul(liquidationFee).div(BASIS_POINTS); 

        // % of collateral that was siezed
        uint executedOut = SyntheX(system.synthex()).commitLiquidate(
            _account, _liquidator, _outAsset, 
            amountOut, 
            penalty,
            reserve
        );

        amountUSD = executedOut.toUSD(prices[1]);
        _burn(_account, totalSupply().mul(amountUSD).div(getTotalDebtUSD()));

        return amountUSD.toToken(prices[0]);
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
     * @dev Get the total debt of a trading pool
     * @return The total debt of the trading pool
     */
    function getTotalDebtUSD() virtual override public view returns(uint) {
        // Get the list of synths in this trading pool
        address[] memory _synths = getSynths();
        // Total debt in USD
        uint totalDebt = 0;
        // Fetch and cache oracle address
        IPriceOracle _oracle = IPriceOracle(system.priceOracle());
        // Iterate through the list of synths and add each synth's total supply in USD to the total debt
        for(uint i = 0; i < _synths.length; i++){
            address synth = _synths[i];
            IPriceOracle.Price memory price = _oracle.getAssetPrice(synth);
            // synthDebt = synthSupply * price
            totalDebt = totalDebt.add(ERC20X(synth).totalSupply().mul(price.price).div(10**price.decimals));
        }
        return totalDebt;
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
    /**
     * @notice Pause the contract
     * @dev Only callable by L2 admin
     */
    function pause() public onlyL2Admin() {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only callable by L2 admin
     */
    function unpause() public onlyL2Admin() {
        _unpause();
    }
    /**
     * @dev Add a new synth to the pool
     * @param _synth The address of the synth to add
     * @notice Only the owner can call this function
     * @notice The synth contract must have pool (this contract) as owner
     */
    function enableSynth(address _synth) virtual override public onlyGov {
        // Ensure _synth is not already enabled in pool
        require(!synths[_synth], "Synth already exists in pool");
        // Enable synth
        synths[_synth] = true;
        // Ensure _synthsList does not already contain _synth
        for(uint i = 0; i < synthsList.length; i++){
            require(synthsList[i] != _synth, "Synth already exists in pool, but is disabled");
        }
        // Append to _synthsList
        synthsList.push(_synth); 
        // Sanity check. Ensure synth has pool as owner
        require(address(ERC20X(_synth).pool()) == address(this), "Synth must have pool as owner");
        // Emit event on synth enabled
        emit SynthEnabled(_synth);
    }

    /**
     * @dev Update the fee for the pool
     * @param _mintFee New mint fee
     * @param _swapFee New swap fee
     * @param _burnFee New burn fee
     * @param _issuerAlloc The new issuer allocation
     */
    function updateFee(uint _mintFee, uint _swapFee, uint _burnFee, uint _liquidationFee, uint _liquidationPenalty, uint _issuerAlloc) virtual override public onlyGov {
        require(_mintFee <= BASIS_POINTS, "Mint fee cannot be more than 100%");
        mintFee = _mintFee;
        require(_swapFee <= BASIS_POINTS, "Swap fee cannot be more than 100%");
        swapFee = _swapFee;
        require(_burnFee <= BASIS_POINTS, "Burn fee cannot be more than 100%");
        burnFee = _burnFee;
        require(_liquidationFee <= BASIS_POINTS, "Liquidation fee cannot be more than 100%");
        liquidationFee = _liquidationFee;
        require(_liquidationPenalty <= BASIS_POINTS, "Liquidation penalty cannot be more than 100%");
        liquidationPenalty = _liquidationPenalty;
        require(_issuerAlloc <= BASIS_POINTS, "Issuer allocation cannot be more than 100%");
        issuerAlloc = _issuerAlloc;
        // Emit event on fee updated
        emit FeesUpdated(_mintFee, _swapFee, _burnFee, _liquidationFee, _liquidationPenalty, _issuerAlloc);
    }

    /**
     * @dev Update the address of the primary token
     */
    function updateFeeToken(address _feeToken) virtual override public onlyL2Admin {
        feeToken = _feeToken;
        require(synths[_feeToken], "Synth not enabled");
        // Emit event on primary token updated
        emit FeeTokenUpdated(_feeToken);
    }

    /**
     * @dev Disable a synth from the pool
     * @param _synth The address of the synth to disable
     * @notice Only the owner can call this function
     */
    function disableSynth(address _synth) virtual override public onlyGovOrL2Admin {
        require(synths[_synth], "Synth is not enabled in pool");
        // Disable synth
        // Not removing from _synthsList => would still contribute to pool debt
        synths[_synth] = false;
        emit SynthDisabled(_synth);
    }

    /**
     * @dev Removes the synth from the pool
     * @param _synth The address of the synth to remove
     * @notice Removes from synthList => would not contribute to pool debt
     */
    function removeSynth(address _synth) virtual override public onlyGov {
        synths[_synth] = false;
        for (uint i = 0; i < synthsList.length; i++) {
            if (synthsList[i] == _synth) {
                synthsList[i] = synthsList[synthsList.length - 1];
                synthsList.pop();
                emit SynthRemoved(_synth);
                break;
            } 
        }
    }


    /* -------------------------------------------------------------------------- */
    /*                                 Modifiers                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Only L2_ADMIN_ROLE can call admin functions
     */
    modifier onlyL2Admin(){
        require(system.isL2Admin(msg.sender), "SyntheXPool: Only L2_ADMIN_ROLE can call");
        _;
    }

    /**
     * @notice Only GOVERNANCE_MODULE_ROLE can call function
     */
    modifier onlyGov(){
        require(system.isGovernanceModule(msg.sender), "SyntheXPool: Only GOVERNANCE_MODULE_ROLE can call");
        _;
    }

    /**
     * @notice Only GOVERNANCE_MODULE_ROLE or L2_ADMIN_ROLE can call function
     */
    modifier onlyGovOrL2Admin(){
        require(system.isGovernanceModule(msg.sender) || system.isL2Admin(msg.sender), "SyntheXPool: Only GOVERNANCE_MODULE_ROLE or L2_ADMIN_ROLE can call");
        _;
    }

    /**
     * @notice Only synthex can call
     */
    modifier onlyInternal(){
        require(system.synthex() == msg.sender, "SyntheXPool: Only SyntheX can call this function");
        _;
    }
}