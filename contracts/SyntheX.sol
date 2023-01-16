// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./SyntheXPool.sol";
import "./SyntheXStorage.sol";
import "./token/SyntheXToken.sol";
import "./interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./utils/FeeVault.sol";
import "./interfaces/ISyntheX.sol";

/**
 * @title SyntheX
 * @author SyntheX <prasad@chainscore.finance>
 * @notice SyntheX is a decentralized synthetic asset protocol that allows users to mint synthetic assets backed by collateral assets.
 */
contract SyntheX is ISyntheX, UUPSUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, SyntheXStorage {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for ERC20Upgradeable;

    /**
     * @dev Contract name and version
     */
    string public constant NAME = "SyntheX";
    string public constant VERSION = "0";

    /**
     * @dev Address storage keys
     */
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant POOL_MANAGER = keccak256("POOL_MANAGER");
    bytes32 public constant PRICE_ORACLE = keccak256("PRICE_ORACLE");

    /**
     * @dev Initialize the contract
     * @param _syn The address of the SyntheX token
     * @param _addressStorage The address of the address storage contract
     */
    function initialize(address _syn, address _addressStorage) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        
        syn = SyntheXToken(_syn);
        compInitialIndex = 1e36;
        addressStorage = AddressStorage(_addressStorage);
    }

    modifier onlyAdmin(bytes32 role) {
        require(addressStorage.getAddress(role) == msg.sender, "SyntheX: Not authorized");
        _;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyAdmin(ADMIN) {}

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Enable a pool
     * @param _tradingPool The address of the trading pool
     */
    function enterPool(address _tradingPool) virtual override public {
        tradingPools[_tradingPool].accountMembership[msg.sender] = true;
        accountPools[msg.sender].push(_tradingPool);
    }

    /**
     * @dev Exit a pool
     * @param _tradingPool The address of the trading pool
     */
    function exitPool(address _tradingPool) virtual override public {
        require(getUserPoolDebtUSD(msg.sender, _tradingPool) == 0, "SyntheX: Pool debt must be zero");
        tradingPools[_tradingPool].accountMembership[msg.sender] = false;
        address[] storage pools = accountPools[msg.sender];
        // remove from list
        for (uint i = 0; i < pools.length; i++) {
            if (pools[i] == _tradingPool) {
                pools[i] = pools[pools.length - 1];
                pools.pop();
                return;
            }
        }
    }

    /**
     * @dev Enable a collateral
     * @param _collateral The address of the collateral
     */
    function enterCollateral(address _collateral) virtual override public {
        collaterals[_collateral].accountMembership[msg.sender] = true;
        accountCollaterals[msg.sender].push(_collateral);
    }

    /**
     * @dev Exit a collateral
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
     * @dev Deposit collateral
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
     * @dev Withdraw collateral
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
        // deduct balance
        accountCollateralBalance[msg.sender][_collateral] = depositBalance.sub(_amount);

        // Transfer assets to user
        if(_collateral == address(0)){
            require(address(this).balance >= _amount, "Insufficient ETH balance");
            payable(msg.sender).transfer(_amount);
        } else {
            require(ERC20Upgradeable(_collateral).balanceOf(address(this)) >= _amount, "Insufficient ERC20 balance");
            ERC20Upgradeable(_collateral).safeTransfer(msg.sender, _amount);
        }

        // check health after withdrawal
        require(healthFactor(msg.sender) > safeCRatio, "Health factor below safeCRatio");

        // Update collateral supply
        supply.totalDeposits = supply.totalDeposits.sub(_amount);

        // emit successful event
        emit Withdraw(msg.sender, _collateral, _amount);
    }

    /**
     * @dev Issue a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to issue
     */
    function issue(address _tradingPool, address _synth, uint _amount) virtual override public whenNotPaused nonReentrant {
        // ensure amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");
        // get trading pool market
        Market storage pool = tradingPools[_tradingPool];
        // ensure the pool is enabled
        require(pool.isEnabled, "Trading pool not enabled");
        // ensure the account is in the pool
        if(!pool.accountMembership[msg.sender]){
            enterPool(_tradingPool);
        }
        // ensure the synth to issue is enabled from the trading pool
        require(SyntheXPool(_tradingPool).synths(_synth), "Synth not enabled");
        
        // update reward index for the pool 
        updatePoolRewardIndex(address(syn), _tradingPool);
        // distribute pending reward tokens to user
        distributeAccountReward(address(syn), _tradingPool, msg.sender);

        // get price from oracle
        IPriceOracle.Price memory price = oracle().getAssetPrice(_synth);

        // amoount to issue in USD; needed to issue debt
        uint amountUSD = _amount.mul(price.price).div(10**price.decimals);
        // issue debt
        SyntheXPool(_tradingPool).mint(msg.sender, amountUSD);
        // issue synth
        SyntheXPool(_tradingPool).mintSynth(_synth, msg.sender, _amount);

        // ensure [after debt] health factor is positive
        require(healthFactor(msg.sender) > safeCRatio, "Health factor below safeCRatio");

        // emit event
        emit Issue(msg.sender, _tradingPool, _synth, _amount);
    }

    /**
     * @dev Redeem a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to redeem
     */
    function burn(address _tradingPool, address _synth, uint _amount) virtual override public whenNotPaused nonReentrant {
        // ensure amount is greater than 0
        require(_amount > 0, "Amount must be greater than 0");

        // update reward index for the pool 
        updatePoolRewardIndex(address(syn), _tradingPool);
        // distribute pending reward tokens to user
        distributeAccountReward(address(syn), _tradingPool, msg.sender);

        // get synth price
        IPriceOracle.Price memory price = oracle().getAssetPrice(_synth);

        // amount in USD for debt calculation
        // TODO: Performs a multiplication on the result of a division. Check SECURITY.md for details
        uint amountUSD = _amount.mul(price.price).div(10**price.decimals);

        uint burnablePerc = getUserPoolDebtUSD(msg.sender, _tradingPool).min(amountUSD).mul(1e18).div(amountUSD);

        // ensure user has enough debt to burn
        if(burnablePerc == 0) return;

        SyntheXPool(_tradingPool).burn(msg.sender, amountUSD.mul(burnablePerc).div(1e18));
        SyntheXPool(_tradingPool).burnSynth(_synth, msg.sender, _amount.mul(burnablePerc).div(1e18));

        emit Burn(msg.sender, _tradingPool, _synth, _amount);
    }

    /**
     * @dev Exchange a synthetic asset for another
     * @param _tradingPool The address of the trading pool
     * @param _synthFrom The address of the synthetic asset to exchange
     * @param _synthTo The address of the synthetic asset to receive
     * @param _amount The amount of synthetic asset to exchange
     */
    function exchange(address _tradingPool, address _synthFrom, address _synthTo, uint _amount) virtual override public whenNotPaused nonReentrant {
        // ensure exchange is not to same synth
        require(_synthFrom != _synthTo, "Synths are the same");
        // ensure amount > 0
        require(_amount > 0, "Amount must be greater than 0");

        IPriceOracle.Price[] memory prices;
        address[] memory t = new address[](2);
        t[0] = _synthFrom;
        t[1] = _synthTo;
        prices = oracle().getAssetPrices(t);

        // _amount in terms of _synthTo
        uint amountDst = _amount.mul(prices[0].price).mul(10**prices[1].decimals).div(prices[1].price).div(10**prices[0].decimals);

        // actual through trading pool
        SyntheXPool(_tradingPool).exchange(_synthFrom, _synthTo, msg.sender, _amount, amountDst);

        // emit successful exchange event
        emit Exchange(msg.sender, _tradingPool, _synthFrom, _synthTo, _amount, amountDst);
    }

    /**
     * @dev Liquidate an account
     * @param _account The address of the account to liquidate
     * @param _tradingPool The address of the trading pool
     * @param _inAsset The address of the asset to liquidate
     * @param _inAmount The amount of asset to liquidate
     * @param _outAsset The address of the collateral to receive
     */
    function liquidate(address _account, address _tradingPool, address _inAsset, uint _inAmount, address _outAsset) virtual override external whenNotPaused nonReentrant {
        uint _healthFactor = healthFactor(_account);
        // ensure account is below liquidation threshold
        require(_healthFactor < 1e18, "Health factor above 1");
        // ensure account is not already liquidated
        // health factor goes 0 when completely liquidated (as collateral = 0)
        require(_healthFactor > 0, "Account is already liquidated");
        // amount should be greater than 0
        require(_inAmount > 0, "Amount must be greater than 0");

        // liquidation incentive is the account loan to value ratio
        uint incentive = getLTV(_account);
        // ensure incentive is greater than 0
        require(incentive > 0, "Account has zero LTV");

        IPriceOracle.Price[] memory prices;
        address[] memory t = new address[](2);
        t[0] = _inAsset;
        t[1] = _outAsset;
        prices = oracle().getAssetPrices(t);

        // give back inAmountUSD*(discount) of collateral
        Market storage collateral = collaterals[_outAsset];
        // ensure collateral market is enabled
        require(collateral.isEnabled, "Collateral not enabled");
        // ensure user has entered the collateral market
        require(collateral.accountMembership[_account], "Account not in collateral");

        // get collateral balance
        uint collateralBalance = accountCollateralBalance[_account][_outAsset];

        // collateral to sieze = incentive * (inAmount * inAmountPrice) / outAssetPrice
        uint collateralToSieze = _inAmount
            .mul(prices[0].price)           // in asset price
            .mul(10**prices[1].decimals)    // from dividing outAssetPrice
            .mul(incentive)                 // liquidation incentive
            .div(1e18)                      // decimal points from multiplying incentive
            .div(prices[1].price)           // out asset price
            .div(10**prices[0].decimals);   // from multiplying inAssetPrice

        // if collateral to sieze is more than collateral balance, sieze all collateral
        if(collateralBalance < collateralToSieze){
            collateralToSieze = collateralBalance;
        }

        // sieze collateral
        accountCollateralBalance[_account][_outAsset] = collateralBalance.sub(collateralToSieze);

        // burn synth & debt
        SyntheXPool(_tradingPool).burn(_account, collateralToSieze.mul(prices[1].price).mul(1e18).div(incentive).div(10**prices[1].decimals));
        SyntheXPool(_tradingPool).burnSynth(_inAsset, msg.sender, collateralToSieze
            .mul(prices[1].price)
            .mul(10**prices[0].decimals)
            .mul(1e18)
            .div(incentive)
            .div(prices[0].price)
            .div(10**prices[1].decimals)
        );

        // add collateral to liquidator
        accountCollateralBalance[msg.sender][_outAsset] = accountCollateralBalance[msg.sender][_outAsset].add(collateralToSieze);
    }
    
    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Pause the contract
     */
    function pause() public onlyAdmin(ADMIN) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyAdmin(ADMIN) {
        _unpause();
    }

    /**
     * @dev Add a new trading pool
     * @param _tradingPool The address of the trading pool
     * @param _volatilityRatio The volatility ratio of the trading pool
     */
    function enableTradingPool(address _tradingPool, uint _volatilityRatio) virtual override public onlyAdmin(POOL_MANAGER) {
        require(_volatilityRatio > 0, "Volatility ratio must be greater than 0");
        Market storage pool = tradingPools[_tradingPool];
        // enable pool
        pool.isEnabled = true;
        // set pool's volatility ratio
        pool.volatilityRatio = _volatilityRatio;
        // emit event
        emit TradingPoolEnabled(_tradingPool, _volatilityRatio);
    }
    
    /**
     * @dev Disable a trading pool
     * @dev Synths will not be issued from the pool anymore
     * @dev Will still be calculated for debt
     * @dev Can be re-enabled
     * @param _tradingPool The address of the trading pool
     */
    function disableTradingPool(address _tradingPool) virtual override public onlyAdmin(POOL_MANAGER) {
        if(tradingPools[_tradingPool].isEnabled){
            tradingPools[_tradingPool].isEnabled = false;
            emit TradingPoolDisabled(_tradingPool);
        }
    }

    /**
     * @dev Add a new collateral
     * @param _collateral The address of the collateral
     * @param _volatilityRatio The volatility ratio of the collateral
     */
    function enableCollateral(address _collateral, uint _volatilityRatio) virtual override public onlyAdmin(ADMIN) {
        Market storage collateral = collaterals[_collateral];
        // enable collateral
        collateral.isEnabled = true;
        // set collateral's volatility ratio
        collateral.volatilityRatio = _volatilityRatio;
        // emit event
        emit CollateralEnabled(_collateral, _volatilityRatio);
    }

    /**
     * @dev Disables a collateral, does not remove it from the system
     * @notice Collateral can be re-enabled
     * @notice Collateral can be withdrawn by users
     * @notice Will still be considered for calculation as collateral against debt
     * @param _collateral The address of the collateral
     */
    function disableCollateral(address _collateral) virtual override public onlyAdmin(ADMIN) {
        if(collaterals[_collateral].isEnabled){
            collaterals[_collateral].isEnabled = false;
            emit CollateralDisabled(_collateral);
        }
    }

    /**
     * @dev Update collateral max deposits
     */
    function setCollateralCap(address _collateral, uint _maxDeposit) virtual override public onlyAdmin(ADMIN) {
        CollateralSupply storage supply = collateralSupplies[_collateral];
        require(_maxDeposit > supply.totalDeposits, "Max deposit must be greater than current deposits");
        supply.maxDeposits = _maxDeposit;
        emit CollateralCapUpdated(_collateral, _maxDeposit);
    }

    function setSafeCRatio(uint256 _safeCRatio) public virtual override onlyAdmin(ADMIN) {
        safeCRatio = _safeCRatio;
    }
    /* -------------------------------------------------------------------------- */
    /*                             Reward Distribution                            */
    /* -------------------------------------------------------------------------- */

    function updateRewardToken(address _rewardToken) virtual public onlyAdmin(ADMIN) {
        // update reward token
        syn = SyntheXToken(_rewardToken);
        emit RewardTokenAdded(_rewardToken);
    }
    
    /**
     * @dev Set the reward speed for a trading pool
     * @param _rewardToken The reward token
     * @param _tradingPool The address of the trading pool
     * @param _speed The reward speed
     */
    function setPoolSpeed(address _rewardToken, address _tradingPool, uint _speed) virtual override public onlyAdmin(POOL_MANAGER) {
        // get pool from storage
        Market storage pool = tradingPools[_tradingPool];
        // ensure pool is enabled
        require(pool.isEnabled, "Trading pool not enabled");
        // update existing rewards
        updatePoolRewardIndex(_rewardToken, _tradingPool);
        // set speed
        rewardSpeeds[_rewardToken][_tradingPool] = _speed;
        // emit successful event
        emit SetPoolRewardSpeed(_tradingPool, _speed);
    }
    

    /**
     * @notice Accrue rewards to the market
     * @param _rewardToken The reward token
     * @param _tradingPool The market whose reward index to update
     */
    function updatePoolRewardIndex(address _rewardToken, address _tradingPool) internal {
        PoolRewardState storage poolRewardState = rewardState[_rewardToken][_tradingPool];
        uint rewardSpeed = rewardSpeeds[_rewardToken][_tradingPool];
        uint deltaTimestamp = block.timestamp - poolRewardState.timestamp;
        if(deltaTimestamp == 0) return;
        if (rewardSpeed > 0) {
            uint borrowAmount = SyntheXPool(_tradingPool).totalSupply();
            uint synAccrued = deltaTimestamp * rewardSpeed;
            uint ratio = borrowAmount > 0 ? synAccrued * 1e36 / borrowAmount : 0;
            poolRewardState.index = uint224(poolRewardState.index + ratio);
            poolRewardState.timestamp = uint32(block.timestamp);
        } else {
            poolRewardState.timestamp = uint32(block.timestamp);
        }
    } 

    /**
     * @notice Calculate COMP accrued by a supplier and possibly transfer it to them
     * @param _rewardToken The reward token
     * @param _tradingPool The market in which the supplier is interacting
     * @param _account The address of the supplier to distribute COMP to
     */
    function distributeAccountReward(address _rewardToken, address _tradingPool, address _account) internal {
        // This check should be as gas efficient as possible as distributeSupplierComp is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        PoolRewardState storage poolRewardState = rewardState[_rewardToken][_tradingPool];
        uint borrowIndex = poolRewardState.index;
        uint accountIndex = rewardIndex[_rewardToken][_tradingPool][_account];

        // Update supplier's index to the current index since we are distributing accrued COMP
        rewardIndex[_rewardToken][_tradingPool][_account] = borrowIndex;

        if (accountIndex == 0 && borrowIndex >= compInitialIndex) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with COMP accrued from the start of when supplier rewards were first
            // set for the market.
            accountIndex = compInitialIndex; // 1e36
        }

        // Calculate change in the cumulative sum of the SYN per debt token accrued
        // console.log("accountIndex %s borrowIndex", accountIndex/1e18, borrowIndex/1e18);
        uint deltaIndex = borrowIndex - accountIndex;

        uint accountDebtTokens = SyntheXPool(_tradingPool).balanceOf(_account);

        // Calculate COMP accrued: cTokenAmount * accruedPerCToken
        uint accountDelta = accountDebtTokens * deltaIndex / 1e36;

        uint accountAccrued = rewardAccrued[_rewardToken][_account].add(accountDelta);
        rewardAccrued[_rewardToken][_account] = accountAccrued;

        emit DistributedSYN(_tradingPool, _account, accountDelta, borrowIndex);
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
            rewardAccrued[_rewardToken][holders[j]] = grantRewardInternal(_rewardToken, holders[j], rewardAccrued[_rewardToken][holders[j]]);
        }
    }

    /** 
     * @notice Transfer SYN to the user
     * @dev Note: If there is not enough SYN, we do not perform the transfer all.
     * @param _reward The address of the reward token
     * @param _user The address of the user to transfer SYN to
     * @param _amount The amount of SYN to (possibly) transfer
     * @return The amount of SYN which was NOT transferred to the user
     */
    function grantRewardInternal(address _reward, address _user, uint _amount) internal whenNotPaused nonReentrant returns (uint) {
        // check if there is enough SYN
        SyntheXToken(_reward).mint(_user, _amount);   
        return _amount;
    }

    /**
     * @dev Get total $SYN accrued by an account
     * @dev Only for getting dynamic reward amount in frontend. To be statically called
     */
    function getRewardsAccrued(address _rewardToken, address _account, address[] memory _tradingPoolsList) virtual override public returns(uint){
        // Iterate over all the trading pools and update the reward index and account's reward amount
        for (uint i = 0; i < _tradingPoolsList.length; i++) {
            SyntheXPool pool = SyntheXPool(_tradingPoolsList[i]);
            require(tradingPools[address(pool)].isEnabled, "Market must be listed");
            // Iterate thru all reward tokens
            updatePoolRewardIndex(_rewardToken, address(pool));
            distributeAccountReward(_rewardToken, address(pool), _account);
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
    function healthFactor(address _account) virtual override public view returns(uint) {
        // Total adjusted collateral in USD
        uint totalCollateral = getAdjustedUserTotalCollateralUSD(_account);
        // Total adjusted debt in USD
        uint totalDebt = getAdjustedUserTotalDebtUSD(_account);
        // If total debt is 0, health factor is infinite
        if(totalDebt == 0) return type(uint).max;
        // health factor = collateral / debt
        return totalCollateral * 1e18 / totalDebt;
    }

    /**
     * @dev Get the Loan-To-Value ratio of an account
     * @dev LTV = Total Collateral / Total Debt
     * @param _account The address of the account
     * @return The health factor of the account
     */
    function getLTV(address _account) virtual override public view returns(uint) {
        // Total collateral in USD
        uint totalCollateral = getUserTotalCollateralUSD(_account);
        // Total debt in USD
        uint totalDebt = getUserTotalDebtUSD(_account);
        // If total debt is 0, LTV is infinite
        if(totalDebt == 0) return type(uint).max;
        // LTV = collateral / debt
        return totalCollateral * 1e18 / totalDebt;
    }

    /**
     * @dev Returns the total collateral amount of an account
     * @param _account The address of the account
     * @return The total collateral of the account
     */
    function getUserTotalCollateralUSD(address _account) virtual override public view returns(uint) {
        // Total collateral in USD
        uint totalCollateral = 0;

        // Read and cache the price oracle
        IPriceOracle _oracle = oracle();

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
        return totalCollateral;
    }

    /**
     * @dev Get the total adjusted collateral of an account: E(amount of an asset)*(volatility ratio of the asset)
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getAdjustedUserTotalCollateralUSD(address _account) virtual override public view returns(uint) {
        // Total collateral in USD
        uint totalCollateral = 0;
        
        // Read and cache the price oracle
        IPriceOracle _oracle = oracle();

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
        return totalCollateral;
    }

    /**
     * @dev Get the total debt of an account
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getUserTotalDebtUSD(address _account) virtual override public view returns(uint) {
        // Total debt in USD
        uint totalDebt = 0;
        // Read and cache the trading pools the user is in
        address[] memory _accountPools = accountPools[_account];
        // Iterate over all the trading pools of the account
        for(uint i = 0; i < _accountPools.length; i++){
            // Add the debt amount in USD
            totalDebt = totalDebt.add(getUserPoolDebtUSD(_account, _accountPools[i]));
        }
        return totalDebt;
    }

    /**
     * @dev Get the total adjusted debt of an account: E(debt of an asset)/(volatility ratio of the asset)
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getAdjustedUserTotalDebtUSD(address _account) virtual override public view returns(uint) {
        // Total adjusted debt in USD
        uint adjustedTotalDebt = 0;
        // Read and cache the trading pools the user is in
        address[] memory _accountPools = accountPools[_account];
        // Iterate over all the trading pools of the account
        for(uint i = 0; i < _accountPools.length; i++){
            // Add the adjusted debt amount in USD
            adjustedTotalDebt = adjustedTotalDebt.add(
                getUserPoolDebtUSD(_account, _accountPools[i])
                .mul(1e18)
                .div(tradingPools[_accountPools[i]].volatilityRatio)
            );
        }
        return adjustedTotalDebt;
    }

    /**
     * @dev Get the debt of an account in a trading pool
     * @param _account The address of the account
     * @param _tradingPool The address of the trading pool
     * @return The debt of the account in the trading pool
     */
    function getUserPoolDebtUSD(address _account, address _tradingPool) virtual override public view returns(uint){
        // Get the total debt shares (supply) of the trading pool
        uint totalDebtShare = IERC20(_tradingPool).totalSupply();
        // If totalShares == 0, there's no debt
        if(totalDebtShare == 0){
            return 0;
        }
        // Get the total debt of the trading pool in USD
        uint poolDebt = SyntheXPool(_tradingPool).getTotalDebtUSD();
        // Get the debt of the account in the trading pool, based on its debt share balance
        return IERC20(_tradingPool).balanceOf(_account).mul(poolDebt).div(totalDebtShare); 
    }

    /**
     * @dev Get price oracle
     */
    function oracle() virtual override public view returns(IPriceOracle){
        return IPriceOracle(addressStorage.getAddress(PRICE_ORACLE));
    }
}