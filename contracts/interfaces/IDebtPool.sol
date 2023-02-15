// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPriceOracle.sol";
import "../storage/DebtPoolStorage.sol";

abstract contract IDebtPool is DebtPoolStorage {
    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function enableSynth(address _synth) external virtual;
    function updateFee(uint _mintFee, uint _swapFee, uint _burnFee, uint _liquidationFee, uint _liquidationPenalty, uint _issuerAlloc) external virtual;
    function disableSynth(address _synth) external virtual;
    function removeSynth(address _synth) external virtual;
    function updateFeeToken(address _feeToken) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function getSynths() external virtual view returns (address[] memory);
    function getTotalDebtUSD() external virtual view returns(uint);
    function getUserDebtUSD(address _account) external virtual view returns(uint);

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
    event SynthEnabled(address indexed synth);
    event SynthDisabled(address indexed synth);
    event SynthRemoved(address indexed synth);
    event FeesUpdated(uint mintFee, uint swapFee, uint burnFee, uint _liquidationFee, uint _liquidationPenalty, uint issuerAlloc);
    event FeeTokenUpdated(address feeToken);
}
