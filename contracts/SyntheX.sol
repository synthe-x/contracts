// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SyntheXPool.sol";
import "hardhat/console.sol";

contract SyntheX is Ownable {
    using SafeMath for uint256;

    bytes32 ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Price Oracle
    PriceOracle oracle; 

    mapping(address => address[]) public accountPools;
    mapping(address => address[]) public accountCollaterals;

    mapping(address => uint) public accountCollateralBalance;

    struct Market {
        bool isEnabled;
        uint volatilityRatio;
        mapping(address => bool) accountMembership;
    }

    mapping(address => Market) public tradingPools;
    mapping(address => Market) public collaterals;

    address[] public tradingPoolsList;
    address[] public collateralsList;

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    function enableTradingPool(address _tradingPool, uint volatilityRatio) public onlyOwner {
        tradingPools[_tradingPool].isEnabled = true;
        tradingPools[_tradingPool].volatilityRatio = volatilityRatio;
        tradingPoolsList.push(_tradingPool);
    }

    function disableTradingPool(address _tradingPool) public onlyOwner {
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

    function enableCollateral(address _collateral, uint volatilityRatio) public onlyOwner {
        collaterals[_collateral].isEnabled = true;
        collaterals[_collateral].volatilityRatio = volatilityRatio;
        collateralsList.push(_collateral);
    }

    function disableCollateral(address _collateral) public onlyOwner {
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

    function setOracle(address _oracle) public onlyOwner {
        oracle = PriceOracle(_oracle);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */

    function enterPool(address _pool) public {
        tradingPools[_pool].accountMembership[msg.sender] = true;
        accountPools[msg.sender].push(_pool);
    }

    function exitPool(address _pool) public {
        tradingPools[_pool].accountMembership[msg.sender] = false;
        // remove from list
        for (uint i = 0; i < accountPools[msg.sender].length; i++) {
            if (accountPools[msg.sender][i] == _pool) {
                accountPools[msg.sender][i] = accountPools[msg.sender][accountPools[msg.sender].length - 1];
                accountPools[msg.sender].pop();
                break;
            }
        }
    }

    function enterCollateral(address _collateral) public {
        collaterals[_collateral].accountMembership[msg.sender] = true;
        accountCollaterals[msg.sender].push(_collateral);
    }

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

    function deposit(address _collateral, uint amount) public {
        require(collaterals[_collateral].isEnabled, "Collateral not enabled");
        require(collaterals[_collateral].accountMembership[msg.sender], "Account not in collateral");
        ERC20(_collateral).transferFrom(msg.sender, address(this), amount);
        accountCollateralBalance[msg.sender] += amount;
    }

    function withdraw(address _collateral, uint amount) public {
        require(accountCollateralBalance[msg.sender] >= amount, "Insufficient balance");
        ERC20(_collateral).transfer(msg.sender, amount);
        accountCollateralBalance[msg.sender] -= amount;

        // check health
        require(healthFactor(msg.sender) > 1e18, "Health factor below 1");
    }

    function issue(address _tradingPool, address _synth, uint amount) public {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");
        require(pool.accountMembership[msg.sender], "Account not in trading pool");
        
        uint amountUSD = amount * oracle.getPrice(_synth)/1e18;
        SyntheXPool(_tradingPool).issueSynth(_synth, msg.sender, amount, amountUSD);
    }

    function burn(address _tradingPool, address _synth, uint amount) public {
        Market storage pool = tradingPools[_tradingPool];
        require(pool.isEnabled, "Trading pool not enabled");
        require(pool.accountMembership[msg.sender], "Account not in trading pool");
        
        uint amountUSD = amount * oracle.getPrice(_synth)/1e18;
        SyntheXPool(_tradingPool).burnSynth(_synth, msg.sender, amount, amountUSD);
    }

    function exchange(address pool, address src, address dst, uint amount) public {
        uint amountDst = amount * oracle.getPrice(src) / oracle.getPrice(dst);
        SyntheXPool(pool).exchange(src, dst, msg.sender, amount, amountDst);
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    
    function healthFactor(address account) public view returns(uint) {
        uint totalCollateral = getAdjustedUserTotalCollateralUSD(account);
        uint totalDebt = getAdjustedUserTotalDebtUSD(account);
        if(totalDebt == 0) return type(uint).max;
        return totalCollateral * 1e18 / totalDebt;
    }

    function getUserTotalCollateralUSD(address account) public view returns(uint) {
        uint totalCollateral = 0;
        for(uint i = 0; i < accountCollaterals[account].length; i++){
            address collateral = accountCollaterals[account][i];
            totalCollateral += accountCollateralBalance[account] * oracle.getPrice(collateral) * collaterals[collateral].volatilityRatio / 1e36;
        }
        return totalCollateral;
    }

    function getAdjustedUserTotalCollateralUSD(address account) public view returns(uint) {
        uint totalCollateral = 0;
        for(uint i = 0; i < accountCollaterals[account].length; i++){
            address collateral = accountCollaterals[account][i];
            totalCollateral += accountCollateralBalance[account] * oracle.getPrice(collateral) * collaterals[collateral].volatilityRatio / 1e36;
        }
        return totalCollateral;
    }

    function getUserTotalDebtUSD(address user) public view returns(uint) {
        uint totalDebt = 0;
        address[] memory _accountPools = accountPools[user];
        for(uint i = 0; i < _accountPools.length; i++){
            totalDebt += getUserPoolDebtUSD(user, _accountPools[i]);
        }
        return totalDebt;
    }

    function getAdjustedUserTotalDebtUSD(address user) public view returns(uint) {
        uint adjustedTotalDebt = 0;
        address[] memory _accountPools = accountPools[user];
        for(uint i = 0; i < _accountPools.length; i++){
            Market storage pool = tradingPools[_accountPools[i]];
            adjustedTotalDebt += getUserPoolDebtUSD(user, _accountPools[i]) * 1e18 / pool.volatilityRatio;
        }
        return adjustedTotalDebt;
    }

    function getUserPoolDebtUSD(address user, address pool) public view returns(uint){
        uint totalDebtShare = IERC20(pool).totalSupply();
        if(totalDebtShare == 0){
            return 0;
        }
        uint debtShare = IERC20(pool).balanceOf(user).mul(1e18).div(totalDebtShare);
        uint debt = getPoolTotalDebtUSD(pool);
        return debtShare.mul(debt).div(1e18); 
    }

    function getPoolTotalDebtUSD(address pool) public view returns(uint) {
        address[] memory _synths = SyntheXPool(pool).getSynths();
        uint totalDebt = 0;
        for(uint i = 0; i < _synths.length; i++){
            address synth = _synths[i];
            totalDebt += ERC20X(synth).totalSupply() * oracle.getPrice(synth) / 1e18;
        }
        return totalDebt;
    }
}