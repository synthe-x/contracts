// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./SyntheXPool.sol";
import "./SyntheXStorage.sol";
import "./SYN.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @custom:security-contact prasad@chainscore.finance
contract SyntheX is AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, SyntheXStorage {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    event CollateralEnabled(address indexed asset, uint256 volatilityRatio);
    event CollateralDisabled(address indexed asset);
    event CollateralRemoved(address indexed asset);
    event TradingPoolEnabled(address indexed pool, uint256 volatilityRatio);
    event TradingPoolDisabled(address indexed pool);
    event TradingPoolRemoved(address indexed pool);
    
    event NewPriceOracle(address indexed oracle);

    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Issue(address indexed user, address indexed tradingPool, address indexed asset, uint256 amount);
    event Burn(address indexed user, address indexed tradingPool, address indexed asset, uint256 amount);

    event Exchange(address indexed user, address indexed tradingPool, address indexed fromAsset, address toAsset, uint256 fromAmount, uint256 toAmount);

    event SetPoolRewardSpeed(address indexed pool, uint256 rewardSpeed);
    event NewExchangeFee(uint256 _exchangeFee); 
    event DistributedSYN(address indexed pool, address _account, uint256 accountDelta, uint rewardIndex);

    constructor(){}

    function initialize(address _syn) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        syn = SyntheXToken(_syn);
        safeCRatio = 13e17;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(POOL_MANAGER_ROLE, msg.sender);
        _setupRole(PAUSE_GUARDIAN_ROLE, msg.sender);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Enable a pool
     * @param _tradingPool The address of the trading pool
     */
    function enterPool(address _tradingPool) public {
        tradingPools[_tradingPool].accountMembership[msg.sender] = true;
        accountPools[msg.sender].push(_tradingPool);

    }

    /**
     * @dev Exit a pool
     * @param _tradingPool The address of the trading pool
     */
    function exitPool(address _tradingPool) public {
        tradingPools[_tradingPool].accountMembership[msg.sender] = false;
        // remove from list
        for (uint i = 0; i < accountPools[msg.sender].length; i++) {
            if (accountPools[msg.sender][i] == _tradingPool) {
                accountPools[msg.sender][i] = accountPools[msg.sender][accountPools[msg.sender].length - 1];
                accountPools[msg.sender].pop();
                break;
            }
        }
    }

    /**
     * @dev Enable a collateral
     * @param _collateral The address of the collateral
     */
    function enterCollateral(address _collateral) public {
        collaterals[_collateral].accountMembership[msg.sender] = true;
        accountCollaterals[msg.sender].push(_collateral);
    }

    /**
     * @dev Exit a collateral
     * @param _collateral The address of the collateral
     */
    function exitCollateral(address _collateral) public {
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
     * @dev Enter a collateral and deposit collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to deposit
     */
    function enterAndDeposit(address _collateral, uint _amount) public payable {
        enterCollateral(_collateral);
        deposit(_collateral, _amount);
    }

    /**
     * @dev Deposit collateral
     * @param _collateral The address of the erc20 collateral;  for ETH
     * @param _amount The amount of collateral to deposit
     */
    function deposit(address _collateral, uint _amount) public payable whenNotPaused nonReentrant {
        require(collaterals[_collateral].isEnabled, "Collateral not enabled");
        require(collaterals[_collateral].accountMembership[msg.sender], "Account not in collateral");
        // Transfer of tokens
        if(_collateral == ETH_ADDRESS){
            require(msg.value == _amount, "Incorrect ETH amount");
        } else {
            ERC20(_collateral).transferFrom(msg.sender, address(this), _amount);
        }
        // Update balance
        accountCollateralBalance[msg.sender][_collateral] += _amount;
        emit Deposit(msg.sender, _collateral, _amount);
    }

    /**
     * @dev Withdraw collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to withdraw
     */
    function withdraw(address _collateral, uint _amount) public whenNotPaused nonReentrant {
        require(accountCollateralBalance[msg.sender][_collateral] >= _amount, "Insufficient balance");
        ERC20(_collateral).transfer(msg.sender, _amount);
        accountCollateralBalance[msg.sender][_collateral] -= _amount;

        // check health
        require(healthFactor(msg.sender) > safeCRatio, "Health factor below safeCRatio");

        emit Withdraw(msg.sender, _collateral, _amount);
    }

    /**
     * @dev Enter a pool and issue a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to issue
     */
    function enterAndIssue(address _tradingPool, address _synth, uint _amount) public {
        enterPool(_tradingPool);
        issue(_tradingPool, _synth, _amount);
    }

    /**
     * @dev Issue a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to issue
     */
    function issue(address _tradingPool, address _synth, uint _amount) public whenNotPaused nonReentrant {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");
        require(pool.accountMembership[msg.sender], "Account not in trading pool");
        require(SyntheXPool(_tradingPool).synths(_synth), "Synth not enabled");
        
        updateSYNIndex(_tradingPool);
        distributeAccountSYN(_tradingPool, msg.sender);

        uint amountUSD = _amount * oracle.getPrice(_synth)/1e18;
        SyntheXPool(_tradingPool).mint(msg.sender, amountUSD);
        SyntheXPool(_tradingPool).mintSynth(_synth, msg.sender, _amount);

        require(healthFactor(msg.sender) > safeCRatio, "Health factor below safeCRatio");

        emit Issue(msg.sender, _tradingPool, _synth, _amount);
    }

    /**
     * @dev Redeem a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to redeem
     */
    function burn(address _tradingPool, address _synth, uint _amount) public whenNotPaused nonReentrant {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");
        require(pool.accountMembership[msg.sender], "Account not in trading pool");
        
        updateSYNIndex(_tradingPool);
        distributeAccountSYN(_tradingPool, msg.sender);

        uint amountUSD = _amount * oracle.getPrice(_synth)/1e18;
        uint burnablePerc = getUserPoolDebtUSD(msg.sender, _tradingPool).min(amountUSD).mul(1e18).div(amountUSD);
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
    function exchange(address _tradingPool, address _synthFrom, address _synthTo, uint _amount) public whenNotPaused nonReentrant {
        uint amountDst = _amount.mul(oracle.getPrice(_synthFrom)).div(oracle.getPrice(_synthTo));
        SyntheXPool(_tradingPool).exchange(_synthFrom, _synthTo, msg.sender, _amount, amountDst);

        emit Exchange(msg.sender, _tradingPool, _synthFrom, _synthTo, _amount, amountDst);
    }

    /**
     * @dev Set the reward speed for a trading pool
     * @param _tradingPool The address of the trading pool
     * @param _speed The reward speed
     */
    function setPoolSpeed(address _tradingPool, uint _speed) public onlyRole(POOL_MANAGER_ROLE) {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");

        updateSYNIndex(_tradingPool);
        synRewardSpeeds[_tradingPool] = _speed;
        emit SetPoolRewardSpeed(_tradingPool, _speed);
    }

    /**
     * @dev Liquidate an account
     * @param _account The address of the account to liquidate
     * @param _tradingPool The address of the trading pool
     * @param _inAsset The address of the asset to liquidate
     * @param _inAmount The amount of asset to liquidate
     * @param _outAsset The address of the collateral to receive
     */
    function liquidate(address _account, address _tradingPool, address _inAsset, uint _inAmount, address _outAsset) external whenNotPaused nonReentrant {
        uint _healthFactor = healthFactor(_account);
        require(_healthFactor < 1e18, "Health factor above 1");
        require(_healthFactor > 0, "Account is already liquidated");

        uint incentive = getLTV(_account);
        uint inAssetPrice = oracle.getPrice(_inAsset);
        uint outAssetPrice = oracle.getPrice(_outAsset);

        // give back inAmountUSD*(discount) of collateral
        Market storage collateral = collaterals[_outAsset];
        require(collateral.isEnabled, "Collateral not enabled");
        require(collateral.accountMembership[_account], "Account not in collateral");

        uint collateralBalance = accountCollateralBalance[_account][_outAsset];

        // collateral to sieze
        uint collateralToSieze = (_inAmount * inAssetPrice) * incentive/(1e18 * outAssetPrice) ;

        // if collateral to sieze is more than collateral balance, sieze all collateral
        if(collateralBalance < collateralToSieze){
            collateralToSieze = collateralBalance;
        }

        accountCollateralBalance[_account][_outAsset] -= collateralToSieze;

        // burn synth & debt and transfer collateral to liquidator
        SyntheXPool(_tradingPool).burn(_account, collateralToSieze * outAssetPrice / incentive);
        SyntheXPool(_tradingPool).burnSynth(_inAsset, msg.sender, collateralToSieze * outAssetPrice * 1e18 / (incentive * inAssetPrice));
        accountCollateralBalance[msg.sender][_outAsset] += collateralToSieze;
    }
    
    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Pause the contract
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Set the exchange fee
     * @param _exchangeFee The new exchange fee
     * @notice Only the owner can call this function
     */
    function setExchangeFee(uint256 _exchangeFee) public onlyRole(ADMIN_ROLE) {
        exchangeFee = _exchangeFee;
        emit NewExchangeFee(_exchangeFee);
    }

    /**
     * @dev Add a new trading pool
     * @param _tradingPool The address of the trading pool
     * @param _volatilityRatio The volatility ratio of the trading pool
     */
    function enableTradingPool(address _tradingPool, uint _volatilityRatio) public onlyRole(POOL_MANAGER_ROLE) {
        Market storage pool = tradingPools[_tradingPool];
        if(!pool.isEnabled){
            pool.isEnabled = true;
            pool.volatilityRatio = _volatilityRatio;
            tradingPoolsList.push(_tradingPool);
            emit TradingPoolEnabled(_tradingPool, _volatilityRatio);
        }
    }
    
    /**
     * @dev Disable a trading pool
     * @param _tradingPool The address of the trading pool
     */
    function disableTradingPool(address _tradingPool) public onlyRole(POOL_MANAGER_ROLE) {
        if(tradingPools[_tradingPool].isEnabled){
            tradingPools[_tradingPool].isEnabled = false;
            emit TradingPoolDisabled(_tradingPool);
        }
    }

    /**
     * @dev Remove a trading pool
     * @param _tradingPool The address of the trading pool
     */
    function removeTradingPool(address _tradingPool) public onlyRole(POOL_MANAGER_ROLE) {
        tradingPools[_tradingPool].isEnabled = false;
        // remove from list
        for (uint i = 0; i < tradingPoolsList.length; i++) {
            if (tradingPoolsList[i] == _tradingPool) {
                tradingPoolsList[i] = tradingPoolsList[tradingPoolsList.length - 1];
                tradingPoolsList.pop();
                emit TradingPoolRemoved(_tradingPool);
                break;
            }
        }
    }

    /**
     * @dev Add a new collateral
     * @param _collateral The address of the collateral
     * @param _volatilityRatio The volatility ratio of the collateral
     */
    function enableCollateral(address _collateral, uint _volatilityRatio) public onlyRole(ADMIN_ROLE) {
        Market storage collateral = collaterals[_collateral];
        if(!collateral.isEnabled){
            collateral.isEnabled = true;
            collateral.volatilityRatio = _volatilityRatio;
            collateralsList.push(_collateral);
            emit CollateralEnabled(_collateral, _volatilityRatio);
        }
    }

    /**
     * @dev Disable a collateral
     * @param _collateral The address of the collateral
     */
    function disableCollateral(address _collateral) public onlyRole(ADMIN_ROLE) {
        if(collaterals[_collateral].isEnabled){
            collaterals[_collateral].isEnabled = false;
            emit CollateralDisabled(_collateral);
        }
    }

    /**
     * @dev Remove a collateral
     * @param _collateral The address of the collateral
     */
    function removeCollateral(address _collateral) public onlyRole(ADMIN_ROLE) {
        collaterals[_collateral].isEnabled = false;
        // remove from list
        for (uint i = 0; i < collateralsList.length; i++) {
            if (collateralsList[i] == _collateral) {
                collateralsList[i] = collateralsList[collateralsList.length - 1];
                collateralsList.pop();
                emit CollateralRemoved(_collateral);
                break;
            }
        }
    }

    /**
     * @dev Set the price oracle
     * @param _oracle The address of the price oracle
     */
    function setOracle(address _oracle) public onlyRole(ADMIN_ROLE) {
        oracle = PriceOracle(_oracle);
        emit NewPriceOracle(_oracle);
    }

    /* -------------------------------------------------------------------------- */
    /*                           SYN Reward Distribution                          */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Accrue COMP to the market by updating the supply index
     * @param _tradingPool The market whose supply index to update
     */
    function updateSYNIndex(address _tradingPool) internal {
        SynMarketState storage poolRewardState = synRewardState[_tradingPool];
        uint borrowSpeed = synRewardSpeeds[_tradingPool];
        uint deltaTimestamp = block.timestamp - poolRewardState.timestamp;
        if(deltaTimestamp == 0) return;
        if (borrowSpeed > 0) {
            uint borrowAmount = SyntheXPool(_tradingPool).totalSupply();
            uint compAccrued = deltaTimestamp * borrowSpeed;
            uint ratio = borrowAmount > 0 ? compAccrued * 1e36 / borrowAmount : 0;
            poolRewardState.index = uint224(poolRewardState.index + ratio);
            poolRewardState.timestamp = uint32(block.timestamp);
        } else {
            poolRewardState.timestamp = uint32(block.timestamp);
        }
    }

    /**
     * @notice Calculate COMP accrued by a supplier and possibly transfer it to them
     * @param _tradingPool The market in which the supplier is interacting
     * @param _account The address of the supplier to distribute COMP to
     */
    function distributeAccountSYN(address _tradingPool, address _account) internal {
        // TODO: Don't distribute supplier COMP if the user is not in the supplier market.
        // This check should be as gas efficient as possible as distributeSupplierComp is called in many places.
        // - We really don't want to call an external contract as that's quite expensive.

        SynMarketState storage poolRewardState = synRewardState[_tradingPool];
        uint borrowIndex = poolRewardState.index;
        uint accountIndex = synBorrowerIndex[_tradingPool][_account];

        // Update supplier's index to the current index since we are distributing accrued COMP
        synBorrowerIndex[_tradingPool][_account] = borrowIndex;

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

        uint accountAccrued = synAccrued[_account] + accountDelta;
        synAccrued[_account] = accountAccrued;

        emit DistributedSYN(_tradingPool, _account, accountDelta, borrowIndex);
    }

    /**
     * @notice Claim all the comp accrued by holder in all markets
     * @param holder The address to claim COMP for
     */
    function claimSYN(address holder) public {
        return claimSYN(holder, tradingPoolsList);
    }

    /**
     * @notice Claim all the comp accrued by holder in the specified markets
     * @param holder The address to claim COMP for
     * @param cTokens The list of markets to claim COMP in
     */
    function claimSYN(address holder, address[] memory cTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimSYN(holders, cTokens);
    }

    /**
     * @notice Claim all comp accrued by the holders
     * @param holders The addresses to claim COMP for
     * @param _tradingPools The list of markets to claim COMP in
     */
    function claimSYN(address[] memory holders, address[] memory _tradingPools) public {
        for (uint i = 0; i < _tradingPools.length; i++) {
            SyntheXPool cToken = SyntheXPool(_tradingPools[i]);
            require(tradingPools[address(cToken)].isEnabled, "market must be listed");

            updateSYNIndex(address(cToken));
            for (uint j = 0; j < holders.length; j++) {
                distributeAccountSYN(address(cToken), holders[j]);
            }
        }
        for (uint j = 0; j < holders.length; j++) {
            synAccrued[holders[j]] = grantSYNInternal(holders[j], synAccrued[holders[j]]);
        }
    }

    /**
     * @notice Transfer COMP to the user
     * @dev Note: If there is not enough COMP, we do not perform the transfer all.
     * @param user The address of the user to transfer COMP to
     * @param amount The amount of COMP to (possibly) transfer
     * @return The amount of COMP which was NOT transferred to the user
     */
    function grantSYNInternal(address user, uint amount) internal whenNotPaused nonReentrant returns (uint) {
        uint compRemaining = syn.balanceOf(address(this));
        if (amount > 0 && amount <= compRemaining) {
            syn.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns if the collateral is enabled for an account
     */
    function collateralMembership(address market, address account) public view returns(bool){
        return collaterals[market].accountMembership[account];
    }

    /**
     * @dev Returns if the trading pool is enabled for an account
     */
    function tradingPoolMembership(address market, address account) public view returns(bool){
        return tradingPools[market].accountMembership[account];
    }

    /**
     * @dev Get the health factor of an account
     * @param _account The address of the account
     * @return The health factor of the account
     */
    function healthFactor(address _account) public view returns(uint) {
        uint totalCollateral = getAdjustedUserTotalCollateralUSD(_account);
        uint totalDebt = getAdjustedUserTotalDebtUSD(_account);
        if(totalDebt == 0) return type(uint).max;
        return totalCollateral * 1e18 / totalDebt;
    }

    /**
     * @dev Get the health factor of an account
     * @param _account The address of the account
     * @return The health factor of the account
     */
    function getLTV(address _account) public view returns(uint) {
        uint totalCollateral = getUserTotalCollateralUSD(_account);
        uint totalDebt = getUserTotalDebtUSD(_account);
        if(totalDebt == 0) return type(uint).max;
        return totalCollateral * 1e18 / totalDebt;
    }

    /**
     * @dev Get the total collateral of an account
     * @param _account The address of the account
     * @return The total collateral of the account
     */
    function getUserTotalCollateralUSD(address _account) public view returns(uint) {
        uint totalCollateral = 0;
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            address collateral = accountCollaterals[_account][i];
            totalCollateral += accountCollateralBalance[_account][collateral] * oracle.getPrice(collateral) / 1e18;
        }
        return totalCollateral;
    }

    /**
     * @dev Get the total adjusted collateral of an account: E(amount of an asset)*(volatility ratio of the asset)
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getAdjustedUserTotalCollateralUSD(address _account) public view returns(uint) {
        uint totalCollateral = 0;
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            address collateral = accountCollaterals[_account][i];
            totalCollateral += accountCollateralBalance[_account][collateral] * oracle.getPrice(collateral) * collaterals[collateral].volatilityRatio / 1e36;
        }
        return totalCollateral;
    }

    /**
     * @dev Get the total debt of an account
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getUserTotalDebtUSD(address _account) public view returns(uint) {
        uint totalDebt = 0;
        address[] memory _accountPools = accountPools[_account];
        for(uint i = 0; i < _accountPools.length; i++){
            totalDebt += getUserPoolDebtUSD(_account, _accountPools[i]);
        }
        return totalDebt;
    }

    /**
     * @dev Get the total adjusted debt of an account: E(debt of an asset)/(volatility ratio of the asset)
     * @param _account The address of the account
     * @return The total debt of the account
     */
    function getAdjustedUserTotalDebtUSD(address _account) public view returns(uint) {
        uint adjustedTotalDebt = 0;
        address[] memory _accountPools = accountPools[_account];
        for(uint i = 0; i < _accountPools.length; i++){
            Market storage pool = tradingPools[_accountPools[i]];
            adjustedTotalDebt += getUserPoolDebtUSD(_account, _accountPools[i]) * 1e18 / pool.volatilityRatio;
        }
        return adjustedTotalDebt;
    }

    /**
     * @dev Get the debt of an account in a trading pool
     * @param _account The address of the account
     * @param _tradingPool The address of the trading pool
     * @return The debt of the account in the trading pool
     */
    function getUserPoolDebtUSD(address _account, address _tradingPool) public view returns(uint){
        uint totalDebtShare = IERC20(_tradingPool).totalSupply();
        if(totalDebtShare == 0){
            return 0;
        }
        return IERC20(_tradingPool).balanceOf(_account).mul(getPoolTotalDebtUSD(_tradingPool)).div(totalDebtShare); 
    }

    /**
     * @dev Get the total debt of a trading pool
     * @param _tradingPool The address of the trading pool
     * @return The total debt of the trading pool
     */
    function getPoolTotalDebtUSD(address _tradingPool) public view returns(uint) {
        address[] memory _synths = SyntheXPool(_tradingPool).getSynths();
        uint totalDebt = 0;
        for(uint i = 0; i < _synths.length; i++){
            address synth = _synths[i];
            totalDebt += ERC20X(synth).totalSupply() * oracle.getPrice(synth) / 1e18;
        }
        return totalDebt;
    }

    /**
     * @dev Get dynamic total $SYN accrued by an account
     */
    function getSYNAccrued(address _account) public returns(uint){
        for (uint i = 0; i < tradingPoolsList.length; i++) {
            SyntheXPool pool = SyntheXPool(tradingPoolsList[i]);
            require(tradingPools[address(pool)].isEnabled, "market must be listed");

            updateSYNIndex(address(pool));
            distributeAccountSYN(address(pool), _account);
        }
        return getSYNAccruedStored(_account);
    }

    /**
     * @dev Get stored total $SYN accrued by an account
     */
    function getSYNAccruedStored(address _account) public view returns(uint){
        return synAccrued[_account];
    }
}