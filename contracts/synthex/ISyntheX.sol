// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../utils/oracle/IPriceOracle.sol";
import "./SyntheXStorage.sol";

abstract contract ISyntheX is SyntheXStorage {
    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    function commitMint(address _account, address _synth, uint _amount) external virtual;    
    function commitBurn(address _account, address _synth, uint _amount) external virtual;
    function setPoolSpeed(address _rewardToken, address _tradingPool, uint _speed) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                          $SYX Reward Distribution                          */
    /* -------------------------------------------------------------------------- */
    function claimReward(address _rewardToken, address holder, address[] memory tradingPoolsList) external virtual;
    function claimReward(address _rewardToken, address[] memory holders, address[] memory tradingPoolsList) external virtual;
    function getRewardsAccrued(address _rewardToken, address _account, address[] memory tradingPoolsList) external virtual returns(uint);

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