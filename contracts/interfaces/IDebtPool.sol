// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPriceOracle.sol";

interface IDebtPool {

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function enableSynth(address _synth) external;
    function updateFee(uint _mintFee, uint _swapFee, uint _burnFee, uint _liquidationFee, uint _liquidationPenalty, uint _issuerAlloc) external;
    function disableSynth(address _synth) external;
    function removeSynth(address _synth) external;
    function updateFeeToken(address _feeToken) external;

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function getSynths() external view returns (address[] memory);
    function getTotalDebtUSD() external view returns(uint);
    function getUserDebtUSD(address _account) external view returns(uint);

    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    function commitMint(address _account, uint _amount) external returns(uint);
    function commitBurn(address _account, uint _amount) external returns(uint);
    function commitSwap(address _account, uint _amount, address _synthTo) external returns(uint);
    function commitLiquidate(address _liquidator, address _account, uint _amount, address _outAsset) external returns(uint);

    /* -------------------------------------------------------------------------- */
    /*                                 Events                                     */
    /* -------------------------------------------------------------------------- */
    event SynthEnabled(address indexed synth);
    event SynthDisabled(address indexed synth);
    event SynthRemoved(address indexed synth);
    event FeesUpdated(uint mintFee, uint swapFee, uint burnFee, uint _liquidationFee, uint _liquidationPenalty, uint issuerAlloc);
    event FeeTokenUpdated(address feeToken);
}
