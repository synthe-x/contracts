// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IPriceOracle.sol";

interface ISyntheXPool {

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function enableSynth(address _synth) external;
    function updateFee(uint _fee) external;
    function disableSynth(address _synth) external;
    function removeSynth(address _synth) external ;
    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function getSynths() external view returns (address[] memory) ;
    function oracle() external view returns(IPriceOracle);
    function vault() external view returns (address) ;
    function getTotalDebtUSD() external view returns(uint);
    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    function mint(address _user, uint _amountUSD) external;
    function mintSynth(address _synth, address _user, uint _amount) external;
    function burn(address _user, uint _amountUSD) external;
    function burnSynth(address _synth, address _user, uint _amount) external;
    function exchange(address _fromSynth, address _toSynth, address _user, uint _fromAmount, uint _toAmount) external;
    /* -------------------------------------------------------------------------- */
    /*                               Events                                       */
    /* -------------------------------------------------------------------------- */
    event SynthEnabled(address indexed synth);
    event SynthDisabled(address indexed synth);
    event SynthRemoved(address indexed synth);
    event FeeUpdated(uint fee);
    
}
