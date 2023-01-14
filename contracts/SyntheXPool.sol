// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC20X.sol";
import "./PriceOracle.sol";
import "./SyntheX.sol";
import "./utils/AddressStorage.sol";
import "./interfaces/ISyntheXPool.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SyntheXPool is ISyntheXPool, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    /**
     * @dev Address storage keys
     */
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant POOL_MANAGER = keccak256("POOL_MANAGER");
    bytes32 public constant PRICE_ORACLE = keccak256("PRICE_ORACLE");
    bytes32 public constant VAULT = keccak256("VAULT");
    bytes32 public constant SYNTHEX = keccak256("SYNTHEX");

    /**
     * @dev Check if synth is enabled
     */
    mapping(address => bool) public synths;
    /**
     * @dev The fee for actions in the pool
     * @notice The fee is in basis points
     * @notice 10000 basis points * 1e18 = 100%
     */
    uint public fee;
    uint private constant BASIS_POINTS = 10000;

    /**
     * @dev The list of synths in the pool to calculate total debt
     */
    address[] private _synthsList;
    /**
     * @dev The address of the address storage contract
     */
    AddressStorage public addressStorage;

    /**
     * @dev Initialize the contract
     */
    function initialize(string memory name, string memory symbol, address _addressStorage) public initializer {
        __ERC20_init(name, symbol);
        addressStorage = AddressStorage(_addressStorage);
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
    function enableSynth(address _synth) virtual override public onlyAdmin {
        if(!synths[_synth]){
            synths[_synth] = true;
            _synthsList.push(_synth); 
            emit SynthEnabled(_synth);
        }
    }

    /**
     * @dev Update the fee for the pool
     * @param _fee The new fee
     */
    function updateFee(uint _fee) virtual override public onlyAdmin {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /**
     * @dev Disable a synth from the pool
     * @param _synth The address of the synth to disable
     * @notice Only the owner can call this function
     */
    function disableSynth(address _synth) virtual override public onlyAdmin {
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
    function removeSynth(address _synth) virtual override public onlyAdmin {
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
    function getSynths() virtual override public view returns (address[] memory) {
        return _synthsList;
    }

    function oracle() virtual override public view returns(IPriceOracle) {
        return IPriceOracle(addressStorage.getAddress(PRICE_ORACLE));
    }

    function vault() virtual override public view returns (address) {
        return addressStorage.getAddress(VAULT);
    }

    /**
     * @dev Get the total debt of a trading pool
     * @return The total debt of the trading pool
     */
    function getTotalDebtUSD() virtual override public view returns(uint) {
        // Get the list of synths in this trading pool
        address[] memory _synths = getSynths();
        // Total debt in USD
        uint totalDebt = 0;
        // Fetch and cache oracle address
        IPriceOracle _oracle = oracle();
        // Iterate through the list of synths and add each synth's total supply in USD to the total debt
        for(uint i = 0; i < _synths.length; i++){
            address synth = _synths[i];
            IPriceOracle.Price memory price = _oracle.getAssetPrice(synth);
            // synthDebt = synthSupply * price
            totalDebt = totalDebt.add(ERC20X(synth).totalSupply().mul(price.price).div(10**price.decimals));
        }
        return totalDebt;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Override                                  */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Debt tokens are non transferrable
     * @dev Override the transfer function to restrict transfer of pool debt tokens
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // If not minting or burning
        if(from != address(0) && to != address(0)) {
            revert("SyntheXPool: Cannot transfer debt tokens");
        }
    }

    /**
     * @dev Only synthex owner can call admin functions
     */
    modifier onlyAdmin(){
        require(addressStorage.getAddress(POOL_MANAGER) == msg.sender, "SyntheXPool: Only PoolManager can call");
        _;
    }

    /**
     * @dev Only synthex can call
     */
    modifier onlyInternal(){
        require(AddressStorage(addressStorage).getAddress(SYNTHEX) == msg.sender, "SyntheXPool: Only SyntheX can call this function");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Issue synths to the user
     * @param _user The address of the user
     * @param _amountUSD The amount of USD to issue
     * @notice Only SyntheX can call this function
     */
    function mint(address _user, uint _amountUSD) virtual override public onlyInternal {
        if(totalSupply() == 0){
            _mint(_user, _amountUSD);
        } else {
            /**
             * @dev Calculate the amount of debt tokens to mint
             * @dev debtSharePrice = totalDebt / totalSupply
             * @dev mintAmount = amountUSD / debtSharePrice
             * @dev 1e18 is used to avoid decimal issues
             */
            uint _totalDebt = getTotalDebtUSD();
            uint totalSupply = totalSupply();
            uint debtSharePrice = _totalDebt * 1e18 / totalSupply;
            uint mintAmount = _amountUSD * 1e18 / debtSharePrice;
            // Mint the debt tokens
            _mint(_user, mintAmount);
        }
    }

    /**
     * @dev Issue synths to the user
     * @param _synth The address of the synth to issue
     * @param _user The address of the user
     * @param _amount The amount of synths to issue
     */
    function mintSynth(address _synth, address _user, uint _amount) virtual override public onlyInternal {
        // Fetch the fee and cache it
        uint _fee = fee;
        // Mint amount minus fee
        ERC20X(_synth).mint(_user, _amount.mul(uint(1e18).sub(_fee.div(BASIS_POINTS))).div(1e18));
        // Mint fee
        ERC20X(_synth).mint(addressStorage.getAddress(VAULT), _amount.mul(_fee.div(BASIS_POINTS)).div(1e18));
    }

    /**
     * @dev Burn synths from the user
     * @param _user The address of the user
     * @param _amountUSD The amount of USD to burn
     */
    function burn(address _user, uint _amountUSD) virtual override public onlyInternal {
        uint _totalDebt = getTotalDebtUSD();
        uint totalSupply = totalSupply();
        uint burnAmount = totalSupply * _amountUSD / _totalDebt;
        _burn(_user, burnAmount);
    }

    /**
     * @dev Burn synths from the user
     * @param _synth The address of the synth to burn
     * @param _user The address of the user
     * @param _amount The amount of synths to burn
     */
    function burnSynth(address _synth, address _user, uint _amount) virtual override public onlyInternal {
        // Burn amount
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
    function exchange(address _fromSynth, address _toSynth, address _user, uint _fromAmount, uint _toAmount) virtual override public onlyInternal {
        require(synths[_toSynth], "Synth not enabled");
        uint _fee = fee;
        // burn from synth
        ERC20X(_fromSynth).burn(_user, _fromAmount);
        // mint to synth
        ERC20X(_toSynth).mint(_user, _toAmount.mul(uint(1e18).sub(_fee.div(BASIS_POINTS))).div(1e18));
        // mint fee to synthex
        ERC20X(_toSynth).mint(vault(), _toAmount.mul(_fee).div(BASIS_POINTS).div(1e18));
    }
}