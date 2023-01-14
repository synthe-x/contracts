// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IPriceOracle.sol";

interface ISyntheX {
  
    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    function enterPool(address _tradingPool) external;
    function exitPool(address _tradingPool) external;
    function enterCollateral(address _collateral) external;
    function exitCollateral(address _collateral) external;
    function enterAndDeposit(address _collateral, uint _amount) external payable;
    function deposit(address _collateral, uint _amount) external payable ;
    function withdraw(address _collateral, uint _amount) external;
    function enterAndIssue(address _tradingPool, address _synth, uint _amount) external;
    function issue(address _tradingPool, address _synth, uint _amount) external;
    function burn(address _tradingPool, address _synth, uint _amount) external;
    function exchange(address _tradingPool, address _synthFrom, address _synthTo, uint _amount) external;
    function setPoolSpeed(address _tradingPool, uint _speed) external ;
    function liquidate(address _account, address _tradingPool, address _inAsset, uint _inAmount, address _outAsset) external;
    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function enableTradingPool(address _tradingPool, uint _volatilityRatio) external;
    function disableTradingPool(address _tradingPool) external;
    function enableCollateral(address _collateral, uint _volatilityRatio) external;
    function disableCollateral(address _collateral) external;
    function setSafeCRatio(uint256 _safeCRatio) external;
    /* -------------------------------------------------------------------------- */
    /*                          $SYN Reward Distribution                          */
    /* -------------------------------------------------------------------------- */
    function claimSYN(address holder, address[] memory tradingPoolsList) external ;
    function claimSYN(address[] memory holders, address[] memory _tradingPools) external;
    function getSYNAccrued(address _account, address[] memory tradingPoolsList) external returns(uint);
    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function collateralMembership(address market, address account) external view returns(bool);
    function tradingPoolMembership(address market, address account) external view returns(bool);
    function healthFactor(address _account) external view returns(uint) ;
    function getLTV(address _account) external view returns(uint) ;
    function getUserTotalCollateralUSD(address _account) external view returns(uint);
    function getAdjustedUserTotalCollateralUSD(address _account) external view returns(uint);
    function getUserTotalDebtUSD(address _account) external view returns(uint);
    function getAdjustedUserTotalDebtUSD(address _account) external view returns(uint) ;
    function getUserPoolDebtUSD(address _account, address _tradingPool) external view returns(uint);
    function oracle() external view returns(IPriceOracle);
    /* -------------------------------------------------------------------------- */
    /*                               Events                                       */
    /* -------------------------------------------------------------------------- */
    event CollateralEnabled(address indexed asset, uint256 volatilityRatio);
    event CollateralDisabled(address indexed asset);
    event TradingPoolEnabled(address indexed pool, uint256 volatilityRatio);
    event TradingPoolDisabled(address indexed pool);
    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Issue(address indexed user, address indexed tradingPool, address indexed asset, uint256 amount);
    event Burn(address indexed user, address indexed tradingPool, address indexed asset, uint256 amount);
    event Exchange(address indexed user, address indexed tradingPool, address indexed fromAsset, address toAsset, uint256 fromAmount, uint256 toAmount);
    event SetPoolRewardSpeed(address indexed pool, uint256 rewardSpeed);
    event DistributedSYN(address indexed pool, address _account, uint256 accountDelta, uint rewardIndex);
}