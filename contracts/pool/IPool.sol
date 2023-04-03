// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../utils/oracle/IPriceOracle.sol";
import "./PoolStorage.sol";

abstract contract IPool {

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
    
    function withdraw(address _collateral, uint _amount, bool unwrap) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function updateSynth(address _synth, PoolStorage.Synth memory _params) external virtual;
    function updateCollateral(address _collateral, PoolStorage.Collateral memory _params) external virtual;
    function removeSynth(address _synth) external virtual;
    function addSynth(address _synth, uint mintFee, uint burnFee) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function getAccountLiquidity(address _account) external virtual view returns(PoolStorage.AccountLiquidity memory liq);
    function getSynths() external virtual view returns (address[] memory);
    function getTotalDebtUSD() external virtual view returns(uint totalDebt);
    function getUserDebtUSD(address _account) external virtual view returns(uint);
    function supportsInterface(bytes4 interfaceId) external virtual view returns (bool);

    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    function commitMint(address _account, uint _amount) external virtual returns(uint);
    function commitBurn(address _account, uint _amount) external virtual returns(uint);
    function commitSwap(address _account, uint _amount, address _synthTo) external virtual returns(uint);
    function commitLiquidate(address _liquidator, address _account, uint _amount, address _outAsset) external virtual returns(uint);

    /* -------------------------------------------------------------------------- */
    /*                                 Events                                     */
    /* -------------------------------------------------------------------------- */
    event SynthUpdated(address indexed synth, bool isActive, bool isDisabled, uint mintFee, uint burnFee);
    event SynthRemoved(address indexed synth);
    event CollateralParamsUpdated(address indexed asset, uint cap, uint baseLTV, uint liqThreshold, uint liqBonus, bool isEnabled);
    event CollateralEntered(address indexed user, address indexed collateral);
    event CollateralExited(address indexed user, address indexed collateral);
    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);
    event Liquidate(address indexed liquidator, address indexed account, address indexed outAsset, uint256 outAmount, uint256 outPenalty, uint256 outRefund);
    event IssuerAllocUpdated(uint issuerAlloc);
    event PriceOracleUpdated(address indexed priceOracle);
    event FeeTokenUpdated(address indexed feeToken);
}