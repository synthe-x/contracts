// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../oracle/IPriceOracle.sol";
import "./SyntheXStorage.sol";

abstract contract ISyntheX is SyntheXStorage {
    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    function enterPool(address _tradingPool) external virtual;
    function exitPool(address _tradingPool) external virtual;
    function enterCollateral(address _collateral) external virtual;
    function exitCollateral(address _collateral) external virtual;
    
    function deposit(address _collateral, uint _amount) external virtual;
    function depositWithPermit(
        address _collateral, 
        uint _amount,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual;
    function depositETH() external virtual payable;
    
    function withdraw(address _collateral, uint _amount) external virtual;
    function withdrawETH(uint _amount) external virtual;

    function commitMint(address _account, address _synth, uint _amount) external virtual returns(int);    
    function commitBurn(address _account, address _synth, uint _amount) external virtual;
    function setPoolSpeed(address _rewardToken, address _tradingPool, uint _speed) external virtual;
    function commitLiquidate(address _account, address _liquidator, address _outAsset, uint _outAmount, uint _penalty, uint _fee) external virtual returns(uint);    
    
    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function enableTradingPool(address _tradingPool, uint _volatilityRatio) external virtual;
    function disableTradingPool(address _tradingPool) external virtual;
    function enableCollateral(address _collateral, uint _volatilityRatio) external virtual;
    function disableCollateral(address _collateral) external virtual;
    function setSafeCRatio(uint256 _safeCRatio) external virtual;
    function setCollateralParams(address _collateral, SyntheXStorage.CollateralSupply memory) external virtual;
    
    /* -------------------------------------------------------------------------- */
    /*                          $SYN Reward Distribution                          */
    /* -------------------------------------------------------------------------- */
    function claimReward(address _rewardToken, address holder, address[] memory tradingPoolsList) external virtual;
    function claimReward(address _rewardToken, address[] memory holders, address[] memory tradingPoolsList) external virtual;
    function getRewardsAccrued(address _rewardToken, address _account, address[] memory tradingPoolsList) external virtual returns(uint);


    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function healthFactorOf(address _account) external virtual view returns(uint);
    function collateralMembership(address market, address account) external virtual view returns(bool);
    function tradingPoolMembership(address market, address account) external virtual view returns(bool);
    function borrowCapacity(SyntheXStorage.AccountLiquidity memory _liquidity) external virtual view returns(int);
    function getAccountLiquidity(address _account) external virtual view returns(SyntheXStorage.AccountLiquidity memory liquidity);
    function getAccountPosition(address _account) external virtual view returns(SyntheXStorage.AccountLiquidity memory liquidity);

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
    event SetPoolRewardSpeed(address indexed rewardToken, address indexed pool, uint256 rewardSpeed);
    event DistributedReward(address indexed rewardToken, address indexed pool, address _account, uint256 accountDelta, uint rewardIndex);
    event CollateralParamsUpdated(address indexed asset, uint maxDeposits, uint minDeposit, uint maxDeposit, uint maxWithdraw, uint totalDeposits);
    event RewardTokenAdded(address indexed rewardToken);
}