// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";

import "./DebtPool.sol";
import "./storage/SyntheXStorage.sol";
import "./token/SyntheXToken.sol";
import "./interfaces/IPriceOracle.sol";
import "./vault/FeeVault.sol";
import "./interfaces/ISyntheX.sol";

/**
 * @title SyntheX
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice This contract connects with debt pools to allows users to mint synthetic assets backed by collateral assets.
 * @dev Handles Reward Distribution: setPoolSpeed, claimReward
 * @dev Handle collateral: deposit/withdraw, enable/disable collateral, set collateral cap, volatility ratio
 * @dev Enable/disale trading pool, volatility ratio 
 */
contract SyntheX is ISyntheX, UUPSUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, SyntheXStorage {
    /// @notice Using SafeMath for uint256 to avoid overflow/underflow
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    /// @notice Using Math for uint256 to use min/max
    using MathUpgradeable for uint256;
    /// @notice Using SafeERC20 for ERC20 to avoid reverts
    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @notice Contract name and version
     */
    string public constant NAME = "SyntheX";
    uint public constant VERSION = 0;

    /**
     * @notice Initialize the contract
     * @param _system The address of the system contract
     * @param _safeCRatio Safe Collateralization Ratio
     */
    function initialize(address _system, uint _safeCRatio) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        
        isRewardTokenSealed = true;

        system = System(_system);
        safeCRatio = _safeCRatio;
    }

    modifier onlyL1Admin() {
        require(system.isL1Admin(msg.sender), "SyntheX: Not authorized");
        _;
    }

    modifier onlyL2Admin() {
        require(system.isL2Admin(msg.sender), "SyntheX: Not authorized");
        _;
    }

    modifier onlyGov() {
        require(system.isGovernanceModule(msg.sender), "SyntheX: Not authorized");
        _;
    }

    modifier onlyGovOrL2() {
        require(system.isL2Admin(msg.sender) || system.isGovernanceModule(msg.sender), "SyntheX: Not authorized");
        _;
    }


    ///@notice required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyL1Admin {}

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Enable a pool for trading
     * @param _tradingPool The address of the trading pool
     */
    function enterPool(address _tradingPool) virtual override public {
        _enterPool(msg.sender, _tradingPool);
    }

    function _enterPool(address _account, address _tradingPool) internal {
        // get pool
        Market storage market = tradingPools[_tradingPool];
        // ensure that the user is not already in the pool
        require(!market.accountMembership[_account], "SyntheX: Already in pool");
        // enable account's pool membership
        market.accountMembership[_account] = true;
        // add to account's pool list
        accountPools[_account].push(_tradingPool);
    }

    /**
     * @notice Exit a pool
     * @param _tradingPool The address of the trading pool
     */
    function exitPool(address _tradingPool) virtual override public {
        // ensure that the user has no debt in the pool
        require(DebtPool(_tradingPool).getUserDebtUSD(msg.sender) == 0, "SyntheX: Pool debt must be zero");
        // disable account's pool membership
        tradingPools[_tradingPool].accountMembership[msg.sender] = false;
        // remove from list of account's pools
        address[] storage pools = accountPools[msg.sender];
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i] == _tradingPool) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                return;
            }
        }
    }

    /**
     * @notice Enable a collateral
     * @param _collateral The address of the collateral
     */
    function enterCollateral(address _collateral) virtual override public {
        // get collateral pool
        Market storage collateral = collaterals[_collateral];
        // ensure that the user is not already in the pool
        require(!collateral.accountMembership[msg.sender], "SyntheX: Already in collateral");
        // enable account's collateral membership
        collateral.accountMembership[msg.sender] = true;
        // add to account's collateral list
        accountCollaterals[msg.sender].push(_collateral);
    }

    /**
     * @notice Exit a collateral
     * @param _collateral The address of the collateral
     */
    function exitCollateral(address _collateral) virtual override public {
        collaterals[_collateral].accountMembership[msg.sender] = false;
        // remove from list
        for (uint i = 0; i < accountCollaterals[msg.sender].length; i++) {
            if (accountCollaterals[msg.sender][i] == _collateral) {
                accountCollaterals[msg.sender][i] = accountCollaterals[msg.sender][accountCollaterals[msg.sender].length - 1];
                accountCollaterals[msg.sender].pop();
                break;
            }
        }
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral; for ETH
     * @param _amount The amount of collateral to deposit
     */
    function deposit(address _collateral, uint _amount) virtual override public payable whenNotPaused nonReentrant {
        // get collateral market
        Market storage collateral = collaterals[_collateral];
        CollateralSupply storage supply = collateralSupplies[_collateral];
        // ensure collateral is globally enabled
        require(collateral.isEnabled, "Collateral not enabled");
        // ensure user has entered the market
        if(!collateral.accountMembership[msg.sender]){
            enterCollateral(_collateral);
        }
        
        // Transfer of tokens
        // if eth deposit; _collateral should be set address(0)
        if(_collateral == address(0)){
            // check if param _amount == msg.value sent with tx
            require(msg.value == _amount, "Incorrect ETH amount");
        } 
        // if erc20 deposit; _collateral should be set to asset address
        // safe transfer from user
        else {
            ERC20Upgradeable(_collateral).safeTransferFrom(msg.sender, address(this), _amount);
        }
        // Update balance
        accountCollateralBalance[msg.sender][_collateral] = accountCollateralBalance[msg.sender][_collateral].add(_amount);

        // Update collateral supply
        supply.totalDeposits = supply.totalDeposits.add(_amount);
        require(supply.totalDeposits <= supply.maxDeposits, "Collateral supply exceeded");

        // emit event
        emit Deposit(msg.sender, _collateral, _amount);
    }

    /**
     * @notice Withdraw collateral
     * @param _collateral The address of the collateral
     * @dev if eth withdraw; _collateral should be set address(0)
     * @dev if erc20 withdraw; _collateral should be set to asset address
     * @param _amount The amount of collateral to withdraw
     */
    function withdraw(address _collateral, uint _amount) virtual override public whenNotPaused nonReentrant {
        CollateralSupply storage supply = collateralSupplies[_collateral];
        // check deposit balance
        uint depositBalance = accountCollateralBalance[msg.sender][_collateral];
        // ensure user has enough deposit balance
        require(depositBalance >= _amount, "Insufficient balance");

        // Transfer assets to user
        _amount = transferOut(_collateral, msg.sender, _amount);

        // Update balance
        accountCollateralBalance[msg.sender][_collateral] = depositBalance.sub(_amount);
        // Update collateral supply
        supply.totalDeposits = supply.totalDeposits.sub(_amount);

        // Check health after withdrawal
        require(healthFactorOf(msg.sender) >= safeCRatio, "Health factor below safeCRatio");

        // Emit successful event
        emit Withdraw(msg.sender, _collateral, _amount);
    }

    function transferOut(address _collateral, address recipient, uint _amount) internal nonReentrant returns(uint) {
        if(_collateral == address(0)){
            if(address(this).balance < _amount){
                _amount = address(this).balance;
            }
            payable(recipient).transfer(_amount);
        } else {
            if(ERC20Upgradeable(_collateral).balanceOf(address(this)) < _amount){
                _amount = ERC20Upgradeable(_collateral).balanceOf(address(this));
            }
            ERC20Upgradeable(_collateral).safeTransfer(recipient, _amount);
        }

        return _amount;
    }

    /**
     * @notice Issue a synthetic asset
     * @param _account The address of the user
     * @param _synth The address of the synthetic asset
     * @param _amount Amount
     */
    function commitMint(address _account, address _synth, uint _amount) external override whenNotPaused returns(int) {
        _synth;
        _amount;

        address debtPool = msg.sender;
        // get trading pool market
        Market storage pool = tradingPools[debtPool];
        // ensure the pool is enabled
        require(pool.isEnabled, "Trading pool not enabled");
        // ensure the account is in the pool
        if(!pool.accountMembership[_account]){
            _enterPool(_account, debtPool);
        }
        
        // update reward index for the pool 
        updatePoolRewardIndex(address(rewardToken), debtPool);
        // distribute pending reward tokens to user
        distributeAccountReward(address(rewardToken), debtPool, _account);

        return getBorrowCapacity(_account);
    }

    /**
     * @notice Redeem a synthetic asset
     * @param _account The address of the user
     * @param _synth The address of the synthetic asset
     * @param _amount Amount
     */
    function commitBurn(address _account, address _synth, uint _amount) external override whenNotPaused {
        _synth;
        _amount;

        // update reward index for the pool 
        updatePoolRewardIndex(address(rewardToken), msg.sender);
        // distribute pending reward tokens to user
        distributeAccountReward(address(rewardToken), msg.sender, _account);
    }

    struct AccountLiquidity {
        uint totalCollateral;
        uint totalAdjustedCollateral;
        uint totalDebt;
        uint totalAdjustedDebt;
    }

    /**
     * @notice Liquidate an account
     */
    function commitLiquidate(address _account, address _liquidator, address _outAsset, uint _outAmount, uint _penalty, uint _fee) external override whenNotPaused returns(uint) {
        require(_outAmount > 0, "Invalid tokenOut amount");
        // Get account liquidity
        (uint totalCollateral, uint totalAdjustedCollateral, uint totalDebt, uint totalAdjustedDebt) = _getAccountLiquidity(_account);
        require(totalDebt > 0, "Account has no debt");
        require(totalAdjustedDebt > 0, "Account has no collateral");
        
        // Calculate health factor
        (uint _health, uint _ltv) = (totalAdjustedCollateral.mul(1e18).div(totalAdjustedDebt), totalCollateral.mul(1e18).div(totalDebt));
        // Ensure account is below liquidation threshold
        require(_health < 1e18, "Health factor above 1");
        // Ensure account is not already liquidated
        // Health factor goes 0 when completely liquidated (as collateral = 0)
        require(_health > 0, "Account is already liquidated");
        // Ensure incentive is greater than 0
        require(_ltv > 0, "Account has zero LTV");

        // Ensure collateral market is enabled
        require(collaterals[_outAsset].isEnabled, "Collateral not enabled");
        // Ensure user has entered the collateral market
        require(collaterals[_outAsset].accountMembership[_account], "Account not in collateral");

        // Sieze collateral
        uint siezePercent = accountCollateralBalance[_account][_outAsset].mul(1e18).div(_outAmount);
        if(siezePercent < 1e18){
            _outAmount = _outAmount.mul(siezePercent).div(1e18);
            _penalty = _penalty.mul(siezePercent).div(1e18);
            _fee = _fee.mul(siezePercent).div(1e18);
        }
        accountCollateralBalance[_account][_outAsset] = accountCollateralBalance[_account][_outAsset].sub(_outAmount.add(_penalty));

        // Add collateral to liquidator
        accountCollateralBalance[_liquidator][_outAsset] = accountCollateralBalance[_liquidator][_outAsset].add(_outAmount.add(_penalty).sub(_fee));

        // Transfer fee to vault
        if(_fee > 0){
            require(transferOut(_outAsset, system.vault(), _fee) == _fee, "Fee transfer failed");
        }

        return _outAmount;
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
     * @notice Add a new trading pool
     * @param _tradingPool The address of the trading pool
     * @param _volatilityRatio The volatility ratio of the trading pool
     */
    function enableTradingPool(address _tradingPool, uint _volatilityRatio) virtual override public onlyGov {
        require(_volatilityRatio > 0, "Volatility ratio must be greater than 0");
        Market storage pool = tradingPools[_tradingPool];
        // Enable pool
        pool.isEnabled = true;
        // Set pool's volatility ratio
        pool.volatilityRatio = _volatilityRatio;
        // Emit event
        emit TradingPoolEnabled(_tradingPool, _volatilityRatio);
    }
    
    /**
     * @notice Disable a trading pool
     * @dev Synths will not be issued from the pool anymore
     * @dev Will still be calculated for debt
     * @dev Can be re-enabled
     * @dev Trading pool can be disabled only by governance module or l2Admin (only in case of emergency)
     * @param _tradingPool The address of the trading pool
     */
    function disableTradingPool(address _tradingPool) virtual override public onlyGovOrL2 {
        if(tradingPools[_tradingPool].isEnabled){
            tradingPools[_tradingPool].isEnabled = false;
            emit TradingPoolDisabled(_tradingPool);
        }
    }

    /**
     * @notice Add a new collateral
     * @dev Collateral can be only added thru the governance module.
     * @param _collateral The address of the collateral
     * @param _volatilityRatio The volatility ratio of the collateral
     */
    function enableCollateral(address _collateral, uint _volatilityRatio) virtual override public onlyGov {
        Market storage collateral = collaterals[_collateral];
        // enable collateral
        collateral.isEnabled = true;
        // set collateral's volatility ratio
        collateral.volatilityRatio = _volatilityRatio;
        // emit event
        emit CollateralEnabled(_collateral, _volatilityRatio);
    }

    /**
     * @notice Disables a collateral, does not remove it from the system
     * @notice Collateral can be re-enabled
     * @notice Collateral can be withdrawn by users
     * @notice Will still be considered for calculation as collateral against debt
     * @param _collateral The address of the collateral
     */
    function disableCollateral(address _collateral) virtual override public onlyGovOrL2 {
        if(collaterals[_collateral].isEnabled){
            collaterals[_collateral].isEnabled = false;
            emit CollateralDisabled(_collateral);
        }
    }

    /**
     * @notice Update collateral max deposits
     * @notice Only governance module or l2Admin (in case of emergency) can update collateral cap
     */
    function setCollateralCap(address _collateral, uint _maxDeposit) virtual override public onlyGovOrL2 {
        CollateralSupply storage supply = collateralSupplies[_collateral];
        // if max deposit is less than total deposits, set max deposit to total deposits
        if(_maxDeposit < supply.totalDeposits){
            _maxDeposit = supply.totalDeposits;
        }
        supply.maxDeposits = _maxDeposit;
        emit CollateralCapUpdated(_collateral, _maxDeposit);
    }

    /**
     * @notice Update safe collateral ratio
     * @notice Only governance module or l2Admin (in case of emergency) can update safe collateral ratio
     */
    function setSafeCRatio(uint256 _safeCRatio) public virtual override onlyGovOrL2 {
        safeCRatio = _safeCRatio;
    }
    /* -------------------------------------------------------------------------- */
    /*                             Reward Distribution                            */
    /* -------------------------------------------------------------------------- */

    function updateRewardToken(address _rewardToken, bool isSealed) virtual public onlyGov {
        // update reward token
        rewardToken = SyntheXToken(_rewardToken);
        // update reward token sealed status
        isRewardTokenSealed = isSealed;
        // emit successful event
        emit RewardTokenAdded(_rewardToken, isSealed);
    }
    
    /**
     * @dev Set the reward speed for a trading pool
     * @param _rewardToken The reward token
     * @param _tradingPool The address of the trading pool
     * @param _speed The reward speed
     */
    function setPoolSpeed(address _rewardToken, address _tradingPool, uint _speed) virtual override public onlyGov {
        // get pool from storage
        Market storage pool = tradingPools[_tradingPool];
        // ensure pool is enabled
        require(pool.isEnabled, "Trading pool not enabled");
        // update existing rewards
        updatePoolRewardIndex(_rewardToken, _tradingPool);
        // set speed
        rewardSpeeds[_rewardToken][_tradingPool] = _speed;
        // emit successful event
        emit SetPoolRewardSpeed(_rewardToken, _tradingPool, _speed);
    }
    
    /**
     * @notice Accrue rewards to the market
     * @param _rewardToken The reward token
     * @param _tradingPool The market whose reward index to update
     */
    function updatePoolRewardIndex(address _rewardToken, address _tradingPool) internal {
        if(_rewardToken == address(0)) return;
        PoolRewardState storage poolRewardState = rewardState[_rewardToken][_tradingPool];
        uint rewardSpeed = rewardSpeeds[_rewardToken][_tradingPool];
        uint deltaTimestamp = block.timestamp - poolRewardState.timestamp;
        if(deltaTimestamp == 0) return;
        if (rewardSpeed > 0) {
            uint borrowAmount = DebtPool(_tradingPool).totalSupply();
            uint synAccrued = deltaTimestamp * rewardSpeed;
            uint ratio = borrowAmount > 0 ? synAccrued * 1e36 / borrowAmount : 0;
            poolRewardState.index = uint224(poolRewardState.index + ratio);
            poolRewardState.timestamp = uint32(block.timestamp);
        } else {
            poolRewardState.timestamp = uint32(block.timestamp);
        }
    } 

    /**
     * @notice Calculate reward accrued by a supplier and possibly transfer it to them
     * @param _rewardToken The reward token
     * @param _debtPool The market in which the supplier is interacting
     * @param _account The address of the supplier to distribute reward to
     */
    function distributeAccountReward(address _rewardToken, address _debtPool, address _account) internal {
        if(_rewardToken == address(0)) return;
        // This check should be as gas efficient as possible as distributeAccountReward is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        PoolRewardState storage poolRewardState = rewardState[_rewardToken][_debtPool];
        uint borrowIndex = poolRewardState.index;
        uint accountIndex = rewardIndex[_rewardToken][_debtPool][_account];

        // Update supplier's index to the current index since we are distributing accrued COMP
        rewardIndex[_rewardToken][_debtPool][_account] = borrowIndex;

        if (accountIndex == 0 && borrowIndex >= rewardInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with reward accrued from the start of when supplier rewards were first
            // set for the market.
            accountIndex = rewardInitialIndex; // 1e36
        }

        // Calculate change in the cumulative sum of the SYN per debt token accrued
        uint deltaIndex = borrowIndex - accountIndex;

        uint accountDebtTokens = DebtPool(_debtPool).balanceOf(_account);

        // Calculate reward accrued: cTokenAmount * accruedPerCToken
        uint accountDelta = accountDebtTokens * deltaIndex / 1e36;

        uint accountAccrued = rewardAccrued[_rewardToken][_account].add(accountDelta);
        rewardAccrued[_rewardToken][_account] = accountAccrued;

        emit DistributedReward(_rewardToken, _debtPool, _account, accountDelta, borrowIndex);
    }

    /**
     * @dev Claim all the SYN accrued by holder in the specified markets
     * @param _rewardToken The address of the reward token
     * @param holder The address to claim SYN for
     * @param tradingPoolsList The list of markets to claim SYN in
     * @dev We're taking a list of markets as input instead of a storing a list of them in contract
     */
    function claimReward(address _rewardToken, address holder, address[] memory tradingPoolsList) virtual override public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimReward(_rewardToken, holders, tradingPoolsList);
    }

    /**
     * @notice Claim all SYN accrued by the holders
     * @param _rewardToken The address of the reward token
     * @param holders The addresses to claim COMP for
     * @param _tradingPools The list of markets to claim COMP in
     */
    function claimReward(address _rewardToken, address[] memory holders, address[] memory _tradingPools) virtual override public {
        // Iterate through all holders and trading pools
        for (uint i = 0; i < _tradingPools.length; i++) { 
            address pool = _tradingPools[i];
            require(tradingPools[pool].isEnabled, "Market must be enabled");
            // Iterate thru all reward tokens
            updatePoolRewardIndex(_rewardToken, pool);
            for (uint k = 0; k < holders.length; k++) {
                distributeAccountReward(_rewardToken, pool, holders[k]);
            }
        }
        for (uint j = 0; j < holders.length; j++) {
            grantRewardInternal(_rewardToken, holders[j], rewardAccrued[_rewardToken][holders[j]]);
            rewardAccrued[_rewardToken][holders[j]] = 0;
        }
    }

    /** 
     * @notice Mint/Transfer SYN to the user
     * @param _reward The address of the reward token
     * @param _user The address of the user to transfer SYN to
     * @param _amount The amount of SYN to (possibly) mint
     * @return The amount of COMP SYN was NOT transferred to the user
     */
    function grantRewardInternal(address _reward, address _user, uint _amount) internal whenNotPaused nonReentrant returns (uint) {
        
        if(_reward == address(0)) return(0);

        SyntheXToken _rewardToken = SyntheXToken(_reward);
        // Check if the reward token is sealed
        // if sealed: mint it, else: transfer it
        if(isRewardTokenSealed){
            SyntheXToken(_reward).mint(_user, _amount);
            return 0;
        } else {
            // check if there is enough SYN
            uint rewardRemaining = _rewardToken.balanceOf(address(this));

            if (_amount > 0 && _amount <= rewardRemaining) {
                _rewardToken.transfer(_user, _amount);
                return 0;
            }

            return _amount;
        }

    }

    /**
     * @dev Get total $SYN accrued by an account
     * @dev Only for getting dynamic reward amount in frontend. To be statically called
     */
    function getRewardsAccrued(address _rewardToken, address _account, address[] memory _tradingPoolsList) virtual override public returns(uint) {
        // Iterate over all the trading pools and update the reward index and account's reward amount
        for (uint i = 0; i < _tradingPoolsList.length; i++) {
            require(tradingPools[_tradingPoolsList[i]].isEnabled, "Market must be listed");
            // Iterate thru all reward tokens
            updatePoolRewardIndex(_rewardToken, _tradingPoolsList[i]);
            distributeAccountReward(_rewardToken, _tradingPoolsList[i], _account);
        }
        // Get the rewards accrued
        return rewardAccrued[_rewardToken][_account];
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns if the collateral is enabled for an account
     */
    function collateralMembership(address market, address account) virtual override public view returns(bool){
        // reading the mapping accountMembership from struct collateral
        return collaterals[market].accountMembership[account];
    }

    /**
     * @dev Returns if the trading pool is enabled for an account.
     */
    function tradingPoolMembership(address market, address account) virtual override public view returns(bool){
        // reading the mapping accountMembership from struct tradingPool
        return tradingPools[market].accountMembership[account];
    }

    /**
     * @dev Get the health factor of an account.
     * @dev Health Factor = Total Adjusted Collateral / Total Adjusted Debt
     * @dev Total Adjusted Collateral = Sum(collateral.amount * (collateral.volatilityRatio))
     * @dev Total Adjusted Debt = Sum(debt.amount / (debt.volatilityRatio))
     * @param _account The address of the account.
     * @return The health factor of the account.
     */
    function healthFactorOf(address _account) virtual override public view returns(uint) {
        // Total adjusted collateral & Total adjusted debt in USD
        (uint totalCollateral, uint totalDebt) = getAdjustedAccountLiquidity(_account);
        // If total debt is 0, health factor is infinite
        if(totalDebt == 0) return type(uint).max;
        // health factor = collateral / debt
        return totalCollateral.mul(1e18).div(totalDebt);
    }

    /**
     * @dev Get the Loan-To-Value ratio of an account
     * @dev LTV = Total Collateral / Total Debt
     * @param _account The address of the account
     * @return The health factor of the account
     */
    function ltvOf(address _account) virtual override public view returns(uint) {
        // Total collateral & Total debt in USD
        (uint totalCollateral, uint totalDebt) = getAccountLiquidity(_account);
        // If total debt is 0, LTV is infinite 
        if(totalDebt == 0) return type(uint).max;
        // LTV = collateral / debt
        return totalCollateral.mul(1e18).div(totalDebt);
    }

    /**
     * @dev Get the borrow capacity of an account
     * @dev Borrow Capacity = (Total Collateral / safeCRatio) - Total Debt
     */
    function getBorrowCapacity(address _account) virtual override public view returns(int) {
        // Get the total collateral & total debt of the account
        (uint totalCollateral, uint totalDebt) = getAdjustedAccountLiquidity(_account);
        // Borrow capacity = (total collateral * LTV) - total debt
        return int(totalCollateral.mul(1e18).div(safeCRatio)).sub(int(totalDebt));
    }

    /**
     * @dev Returns the total collateral amount of an account
     * @param _account The address of the account
     * @return The total collateral of the account
     */
    function getAccountLiquidity(address _account) virtual override public view returns(uint, uint) {
        // Total collateral in USD
        uint totalCollateral = 0;

        // Read and cache the price oracle
        IPriceOracle _oracle = IPriceOracle(system.priceOracle());

        // Iterate over all the collaterals of the account
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            address collateral = accountCollaterals[_account][i];
            IPriceOracle.Price memory price = _oracle.getAssetPrice(collateral);
            // Add the collateral amount in USD
            // CollateralAmountUSD = CollateralAmount * Price / 10^PriceDecimals
            totalCollateral = totalCollateral.add(
                accountCollateralBalance[_account][collateral].mul(price.price).div(10**price.decimals)
            );
        }

        // Total debt in USD
        uint totalDebt = 0;
        // Read and cache the trading pools the user is in
        address[] memory _accountPools = accountPools[_account];
        // Iterate over all the trading pools of the account
        for(uint i = 0; i < _accountPools.length; i++){
            // Add the debt amount in USD
            totalDebt = totalDebt.add(DebtPool(_accountPools[i]).getUserDebtUSD(_account));
        }
        return (totalCollateral, totalDebt);
    }

    /**
     * @dev Get the total adjusted collateral of an account: E(amount of an asset)*(volatility ratio of the asset)
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getAdjustedAccountLiquidity(address _account) virtual override public view returns(uint, uint) {
        // Total collateral in USD
        uint totalCollateral = 0;
        
        // Read and cache the price oracle
        IPriceOracle _oracle = IPriceOracle(system.priceOracle());

        // Iterate over all the collaterals of the account
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            address collateral = accountCollaterals[_account][i];
            IPriceOracle.Price memory price = _oracle.getAssetPrice(collateral);
            // Add the adjusted collateral amount in USD
            // AdjustedCollateralAmountUSD = CollateralAmount * Price * volatilityRatio / 10^PriceDecimals
            totalCollateral = totalCollateral.add(
                accountCollateralBalance[_account][collateral]
                .mul(price.price)
                .mul(collaterals[collateral].volatilityRatio)
                .div(1e18)                      // adjust for volatility ratio
                .div(10**price.decimals)        // adjust for price
            ); 
        }

        // Total adjusted debt in USD
        uint totalDebt = 0;
        // Read and cache the trading pools the user is in
        address[] memory _accountPools = accountPools[_account];
        // Iterate over all the trading pools of the account
        for(uint i = 0; i < _accountPools.length; i++){
            // Add the adjusted debt amount in USD
            totalDebt = totalDebt.add(
                DebtPool(_accountPools[i]).getUserDebtUSD(_account)
                .mul(1e18)
                .div(tradingPools[_accountPools[i]].volatilityRatio)
            );
        }
        return (totalCollateral, totalDebt);
    }

    function _getAccountLiquidity(address _account) public view returns(uint, uint, uint, uint) {
        // Total collateral in USD
        uint totalCollateral = 0;
        uint totalAdjustedCollateral = 0;
        // Total adjusted debt in USD
        uint totalDebt = 0;
        uint totalAdjustedDebt = 0;

        // Read and cache the price oracle
        IPriceOracle _oracle = IPriceOracle(system.priceOracle());

        // Iterate over all the collaterals of the account
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            address collateral = accountCollaterals[_account][i];
            IPriceOracle.Price memory price = _oracle.getAssetPrice(collateral);
            // Add the adjusted collateral amount in USD
            // AdjustedCollateralAmountUSD = CollateralAmount * Price * volatilityRatio / 10^PriceDecimals
            totalAdjustedCollateral = totalAdjustedCollateral.add(
                accountCollateralBalance[_account][collateral]
                .mul(price.price)
                .mul(collaterals[collateral].volatilityRatio)
                .div(1e18)                      // adjust for volatility ratio
                .div(10**price.decimals)        // adjust for price
            ); 

            totalCollateral = totalCollateral.add(
                accountCollateralBalance[_account][collateral].mul(price.price).div(10**price.decimals)
            );
        }
        
        // Read and cache the trading pools the user is in
        address[] memory _accountPools = accountPools[_account];
        // Iterate over all the trading pools of the account
        for(uint i = 0; i < _accountPools.length; i++){
            // Add the adjusted debt amount in USD
            totalAdjustedDebt = totalAdjustedDebt.add(
                DebtPool(_accountPools[i]).getUserDebtUSD(_account)
                .mul(1e18)
                .div(tradingPools[_accountPools[i]].volatilityRatio)
            );

            totalDebt = totalDebt.add(DebtPool(_accountPools[i]).getUserDebtUSD(_account));
        }
        return (totalCollateral, totalAdjustedCollateral, totalDebt, totalAdjustedDebt);
    }
}