// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./ERC20X.sol";
import "./PriceOracle.sol";
import "./SyntheX.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SyntheXPool is ERC20 {
    using SafeMath for uint256;
    using Math for uint256;

    event SynthEnabled(address indexed synth);
    event SynthDisabled(address indexed synth);
    event SynthRemoved(address indexed synth);

    SyntheX synthex;

    mapping(address => bool) synths;
    address[] private _synthsList;

    constructor(string memory name, string memory symbol, address _synthex) ERC20(name, symbol) {
        synthex = SyntheX(_synthex);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Add a new synth to the pool
     * @param _synth The address of the synth to add
     * @notice Only the owner can call this function
     * @notice The synth contract must have pool (this contract) as owner
     */
    function enableSynth(address _synth) public onlyOwner {
        if(!synths[_synth]){
            synths[_synth] = true;
            _synthsList.push(_synth);
            emit SynthEnabled(_synth);
        }
    }

    /**
     * @dev Disable a synth from the pool
     * @param _synth The address of the synth to disable
     * @notice Only the owner can call this function
     */
    function disableSynth(address _synth) public onlyOwner {
        if(synths[_synth]){
            synths[_synth] = false;
            emit SynthDisabled(_synth);
        }
    }

    /**
     * @dev Removes the synth from the pool
     * @param _synth The address of the synth to remove
     * @notice Removes from synthList => would not contribute to pool debt
     */
    function removeSynth(address _synth) public onlyOwner {
        synths[_synth] = false;
        for (uint i = 0; i < _synthsList.length; i++) {
            if (_synthsList[i] == _synth) {
                _synthsList[i] = _synthsList[_synthsList.length - 1];
                _synthsList.pop();
                emit SynthRemoved(_synth);
                break;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns the list of synths in the pool
     */
    function getSynths() public view returns (address[] memory) {
        return _synthsList;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Override                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Override the transfer function to restrict transfer of pool debt tokens
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if(from != address(0) && to != address(0)) {
            revert("SyntheXPool: Cannot transfer debt tokens");
        }
    }

    /**
     * @dev Only synthex owner can call admin functions
     */
    modifier onlyOwner(){
        require(synthex.owner() == msg.sender, "SyntheXPool: Only owner can mint");
        _;
    }

    /**
     * @dev Only synthex can call
     */
    modifier onlyInternal(){
        require(msg.sender == address(synthex), "Only SyntheX can call this function");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Issue synths to the user
     * @param _synth The address of the synth to issue
     * @param _user The address of the user
     * @param _amount The amount of synths to issue
     * @param _amountUSD The amount of USD to issue
     * @notice Only SyntheX can call this function
     */
    function mint(address _synth, address _user, uint _amount, uint _amountUSD) public onlyInternal {
        require(synths[_synth], "Synth not enabled");

        if(totalSupply() == 0){
            _mint(_user, _amount);
        } else {
            uint _totalDebt = synthex.getPoolTotalDebtUSD(address(this));
            uint totalSupply = totalSupply();
            uint debtSharePrice = _totalDebt * 1e18 / totalSupply;
            uint mintAmount = _amountUSD * 1e18 / debtSharePrice;
            _mint(_user, mintAmount);
        }
    }

    function mintSynth(address _synth, address _user, uint _amount) public onlyInternal {
        ERC20X(_synth).mint(_user, _amount);
    }

    /**
     * @dev Burn synths from the user
     * @param _synth The address of the synth to burn
     * @param _user The address of the user
     * @param _amount The amount of synths to burn
     * @param _amountUSD The amount of USD to burn
     */
    function burn(address _synth, address _user, uint _amount, uint _amountUSD) public onlyInternal {
        uint _totalDebt = synthex.getPoolTotalDebtUSD(address(this));
        uint totalSupply = totalSupply();
        uint debtSharePrice = _totalDebt * 1e18 / totalSupply;
        uint burnAmount = _amountUSD * 1e18 / debtSharePrice;
        _burn(_user, burnAmount);
    }

    function burnSynth(address _synth, address _user, uint _amount) public onlyInternal {
        ERC20X(_synth).burn(_user, _amount);
    }

    /**
     * @dev Exchange synths
     * @param _fromSynth The address of the synth to exchange from
     * @param _toSynth The address of the synth to exchange to
     * @param _user The address of the user
     * @param _fromAmount The amount of synths to exchange from
     * @param _toAmount The amount of synths to exchange to
     */
    function exchange(address _fromSynth, address _toSynth, address _user, uint _fromAmount, uint _toAmount) public onlyInternal {
        require(synths[_toSynth], "Synth not enabled");
        ERC20X(_fromSynth).burn(_user, _fromAmount);
        ERC20X(_toSynth).mint(_user, _toAmount);
    }
}
