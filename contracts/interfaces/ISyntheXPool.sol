// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IPriceOracle.sol";

interface ISyntheXPool {

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function enableSynth(address _synth) external;
    function updateFee(uint _fee, uint _alloc) external;
    function disableSynth(address _synth) external;
    function removeSynth(address _synth) external;
    function updateFeeToken(address _feeToken) external;

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function getSynths() external view returns (address[] memory);
    function getTotalDebtUSD() external view returns(uint);

    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    function mint(address _synth, address _borrower, address _account, uint _amount, uint _amountUSD) external;
    function mintSynth(address _synth, address _user, uint _amount, uint amountUSD) external;
    function burn(address _synth, address _repayer, address _borrower, uint _amount, uint _amountUSD) external;
    function burnSynth(address _synth, address _user, uint _amount) external;

    /* -------------------------------------------------------------------------- */
    /*                               Events                                       */
    /* -------------------------------------------------------------------------- */
    event SynthEnabled(address indexed synth);
    event SynthDisabled(address indexed synth);
    event SynthRemoved(address indexed synth);
    event FeesUpdated(uint fee, uint issuerAlloc);
    event FeeTokenUpdated(address feeToken);
}
