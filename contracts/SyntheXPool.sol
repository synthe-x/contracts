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
import "hardhat/console.sol";

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
    /// @notice Issuer allocation (of fee) in basis points
    uint public issuerAlloc;
    /// @notice Basis points constant
    uint private constant BASIS_POINTS = 10000;

    /**
     * @dev The synth token used to pass on to vault as fee
     */
    address public feeToken;

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
        // Ensure _synth is not already enabled in pool
        require(!synths[_synth], "Synth already exists in pool");
        // Enable synth
        synths[_synth] = true;
        // Ensure _synthsList does not already contain _synth
        for(uint i = 0; i < _synthsList.length; i++){
            require(_synthsList[i] != _synth, "Synth already exists in pool, but is disabled");
        }
        // Append to _synthsList
        _synthsList.push(_synth); 
        // Sanity check. Ensure synth has pool as owner
        require(ERC20X(_synth).pool() == address(this), "Synth must have pool as owner");
        // Emit event on synth enabled
        emit SynthEnabled(_synth);
    }

    /**
     * @dev Update the fee for the pool
     * @param _fee The new fee
     * @param _alloc The new issuer allocation
     */
    function updateFee(uint _fee, uint _alloc) virtual override public onlyAdmin {
        fee = _fee;
        issuerAlloc = _alloc;
        // Emit event on fee updated
        emit FeesUpdated(_fee, _alloc);
    }

    /**
     * @dev Update the address of the primary token
     */
    function updateFeeToken(address _feeToken) virtual override public onlyAdmin {
        feeToken = _feeToken;
        // Emit event on primary token updated
        emit FeeTokenUpdated(_feeToken);
    }

    /**
     * @dev Disable a synth from the pool
     * @param _synth The address of the synth to disable
     * @notice Only the owner can call this function
     */
    function disableSynth(address _synth) virtual override public onlyAdmin {
        require(synths[_synth], "Synth is not enabled in pool");
        // Disable synth
        // Not removing from _synthsList => would still contribute to pool debt
        synths[_synth] = false;
        emit SynthDisabled(_synth);
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
        IPriceOracle _oracle = IPriceOracle(addressStorage.getAddress(PRICE_ORACLE));
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
     * @notice Make debt tokens non-transferrable
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
     * @notice Only synthex owner can call admin functions
     */
    modifier onlyAdmin(){
        require(addressStorage.getAddress(POOL_MANAGER) == msg.sender, "SyntheXPool: Only PoolManager can call");
        _;
    }

    /**
     * @notice Only synthex can call
     */
    modifier onlyInternal(){
        require(AddressStorage(addressStorage).getAddress(SYNTHEX) == msg.sender, "SyntheXPool: Only SyntheX can call this function");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Issue synths to the user
     * @param _borrower The address that is issuing the debt
     * @param _account The address of the user to issue synths to
     * @param _amountUSD The amount of USD to issue
     * @notice Only SyntheX can call this function
     */
    function mint(address _synth, address _borrower, address _account, uint _amount, uint _amountUSD) virtual override public onlyInternal {
        if(totalSupply() == 0){
            _mint(_borrower, _amountUSD);
        } else {
            /**
             * Calculate the amount of debt tokens to mint
             * debtSharePrice = totalDebt / totalSupply
             * mintAmount = amountUSD / debtSharePrice
             */
            uint mintAmount = _amountUSD.mul(totalSupply()).div(getTotalDebtUSD());
            // Mint the debt tokens
            _mint(_borrower, mintAmount);
        }
        mintSynth(_synth, _account, _amount, _amountUSD);
    }

    /**
     * @notice Issue synths to the user
     * @param _synth The address of the synth to issue
     * @param _user The address of the user
     * @param _amount The amount of synths to issue
     */
    function mintSynth(address _synth, address _user, uint _amount, uint amountUSD) virtual override public onlyInternal {
        // Fetch the fee and cache it
        uint _fee = fee;
        // Mint (amount - fee) toSynth to user
        ERC20X(_synth).mint(_user, _amount.mul(uint(1e18).mul(BASIS_POINTS).sub(_fee)).div(1e18).div(BASIS_POINTS));
        // (issuerAlloc * fee) is burned permanently

        // Mint ((1 - issuerAlloc) * fee) to staking rewards

        IPriceOracle _oracle = IPriceOracle(addressStorage.getAddress(PRICE_ORACLE));
        IPriceOracle.Price memory feeTokenPrice = _oracle.getAssetPrice(feeToken);

        // NOTE - Here performing all multiplications before all division causes overflow. So moved one multiplication after division
        uint toAmount = amountUSD
            .mul(_fee)
            .mul(uint(1e18).mul(BASIS_POINTS).sub(issuerAlloc))
            .div(BASIS_POINTS).div(1e18)            // for multiplying _fee
            .div(BASIS_POINTS).div(1e18)           // for multiplying issuerAlloc
            .mul(10**feeTokenPrice.decimals)        // for dividing with feeToken price
            .div(feeTokenPrice.price);
        
        // Mint fee
        ERC20X(feeToken).mint(
            addressStorage.getAddress(VAULT), 
            toAmount
        );
    }

    /**
     * @notice Burn synths from the user
     * @param _repayer User that is repaying the debt; the user that is burning the synth
     * @param _borrower User whose debt is being burned
     * @param _amountUSD The amount of USD to burn
     */
    function burn(address _synth, address _repayer, address _borrower, uint _amount, uint _amountUSD) virtual override public onlyInternal {
        uint _totalDebt = getTotalDebtUSD();
        uint totalSupply = totalSupply();
        uint burnAmount = totalSupply * _amountUSD / _totalDebt;
        _burn(_borrower, burnAmount);

        burnSynth(_synth, _repayer, _amount);
    }

    /**
     * @notice Burn synths from the user
     * @param _synth The address of the synth to burn
     * @param _user The address of the user
     * @param _amount The amount of synths to burn
     */
    function burnSynth(address _synth, address _user, uint _amount) virtual override public onlyInternal {
        // Burn amount
        ERC20X(_synth).burn(_user, _amount);
    }
}