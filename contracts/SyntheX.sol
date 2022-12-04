// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SyntheXPool.sol";
import "hardhat/console.sol";
import "./SyntheXStorage.sol";

contract SyntheX is Ownable, SyntheXStorage {
    using SafeMath for uint256;

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Add a new trading pool
     * @param _tradingPool The address of the trading pool
     * @param _volatilityRatio The volatility ratio of the trading pool
     */
    function enableTradingPool(address _tradingPool, uint _volatilityRatio) public onlyOwner {
        tradingPools[_tradingPool].isEnabled = true;
        tradingPools[_tradingPool].volatilityRatio = _volatilityRatio;
        tradingPoolsList.push(_tradingPool);
    }
    
    /**
     * @dev Disable a trading pool
     * @param _tradingPool The address of the trading pool
     */
    function disableTradingPool(address _tradingPool) public onlyOwner {
        tradingPools[_tradingPool].isEnabled = false;
    }

    /**
     * @dev Remove a trading pool
     * @param _tradingPool The address of the trading pool
     */
    function removeTradingPool(address _tradingPool) public onlyOwner {
        tradingPools[_tradingPool].isEnabled = false;
        // remove from list
        for (uint i = 0; i < tradingPoolsList.length; i++) {
            if (tradingPoolsList[i] == _tradingPool) {
                tradingPoolsList[i] = tradingPoolsList[tradingPoolsList.length - 1];
                tradingPoolsList.pop();
                break;
            }
        }
    }

    /**
     * @dev Add a new collateral
     * @param _collateral The address of the collateral
     * @param _volatilityRatio The volatility ratio of the collateral
     */
    function enableCollateral(address _collateral, uint _volatilityRatio) public onlyOwner {
        collaterals[_collateral].isEnabled = true;
        collaterals[_collateral].volatilityRatio = _volatilityRatio;
        collateralsList.push(_collateral);
        emit NewCollateralAsset(_collateral, _volatilityRatio);
    }

    /**
     * @dev Disable a collateral
     * @param _collateral The address of the collateral
     */
    function disableCollateral(address _collateral) public onlyOwner {
        collaterals[_collateral].isEnabled = false;
    }

    /**
     * @dev Remove a collateral
     * @param _collateral The address of the collateral
     */
    function removeCollateral(address _collateral) public onlyOwner {
        collaterals[_collateral].isEnabled = false;
        // remove from list
        for (uint i = 0; i < collateralsList.length; i++) {
            if (collateralsList[i] == _collateral) {
                collateralsList[i] = collateralsList[collateralsList.length - 1];
                collateralsList.pop();
                break;
            }
        }
    }

    /**
     * @dev Set the price oracle
     * @param _oracle The address of the price oracle
     */
    function setOracle(address _oracle) public onlyOwner {
        oracle = PriceOracle(_oracle);
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
     * @dev Deposit collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to deposit
     */
    function deposit(address _collateral, uint _amount) public {
        require(collaterals[_collateral].isEnabled, "Collateral not enabled");
        require(collaterals[_collateral].accountMembership[msg.sender], "Account not in collateral");
        ERC20(_collateral).transferFrom(msg.sender, address(this), _amount);
        accountCollateralBalance[msg.sender] += _amount;

        emit Deposit(msg.sender, _collateral, _amount);
    }

    /**
     * @dev Withdraw collateral
     * @param _collateral The address of the collateral
     * @param _amount The amount of collateral to withdraw
     */
    function withdraw(address _collateral, uint _amount) public {
        require(accountCollateralBalance[msg.sender] >= _amount, "Insufficient balance");
        ERC20(_collateral).transfer(msg.sender, _amount);
        accountCollateralBalance[msg.sender] -= _amount;

        // check health
        require(healthFactor(msg.sender) > 1e18, "Health factor below 1");

        emit Withdraw(msg.sender, _collateral, _amount);
    }

    /**
     * @dev Issue a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to issue
     */
    function issue(address _tradingPool, address _synth, uint _amount) public {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");
        require(pool.accountMembership[msg.sender], "Account not in trading pool");
        
        uint amountUSD = _amount * oracle.getPrice(_synth)/1e18;
        SyntheXPool(_tradingPool).issueSynth(_synth, msg.sender, _amount, amountUSD);

        emit Issue(msg.sender, _tradingPool, _synth, _amount);
    }

    /**
     * @dev Redeem a synthetic asset
     * @param _tradingPool The address of the trading pool
     * @param _synth The address of the synthetic asset
     * @param _amount The amount of synthetic asset to redeem
     */
    function burn(address _tradingPool, address _synth, uint _amount) public {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");
        require(pool.accountMembership[msg.sender], "Account not in trading pool");
        
        uint amountUSD = _amount * oracle.getPrice(_synth)/1e18;
        SyntheXPool(_tradingPool).burnSynth(_synth, msg.sender, _amount, amountUSD);

        emit Burn(msg.sender, _tradingPool, _synth, _amount);
    }

    /**
     * @dev Exchange a synthetic asset for another
     * @param _tradingPool The address of the trading pool
     * @param _synthFrom The address of the synthetic asset to exchange
     * @param _synthTo The address of the synthetic asset to receive
     * @param _amount The amount of synthetic asset to exchange
     */
    function exchange(address _tradingPool, address _synthFrom, address _synthTo, uint _amount) public {
        uint amountDst = _amount * oracle.getPrice(_synthFrom) / oracle.getPrice(_synthTo);
        SyntheXPool(_tradingPool).exchange(_synthFrom, _synthTo, msg.sender, _amount, amountDst);

        emit Exchange(msg.sender, _tradingPool, _synthFrom, _synthTo, _amount, amountDst);
    }

    function liquidate(address _account) external view {
        require(healthFactor(_account) < 1e18, "Health factor above 1");
        // TODO: liquidate
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */

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
     * @dev Get the total collateral of an account
     * @param _account The address of the account
     * @return The total collateral of the account
     */
    function getUserTotalCollateralUSD(address _account) public view returns(uint) {
        uint totalCollateral = 0;
        for(uint i = 0; i < accountCollaterals[_account].length; i++){
            address collateral = accountCollaterals[_account][i];
            totalCollateral += accountCollateralBalance[_account] * oracle.getPrice(collateral) * collaterals[collateral].volatilityRatio / 1e36;
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
            totalCollateral += accountCollateralBalance[_account] * oracle.getPrice(collateral) * collaterals[collateral].volatilityRatio / 1e36;
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
        uint debtShare = IERC20(_tradingPool).balanceOf(_account).mul(1e18).div(totalDebtShare);
        uint debt = getPoolTotalDebtUSD(_tradingPool);
        return debtShare.mul(debt).div(1e18); 
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
}