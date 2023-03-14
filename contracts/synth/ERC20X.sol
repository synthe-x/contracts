// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "../synthex/SyntheX.sol";
import "../pool/Pool.sol";

import "../libraries/Errors.sol";

/**
 * @title ERC20X
 * @dev ERC20 for Synthetic Asset with minting and burning thru pool contract
 * @dev ERC20FlashMint for flash loan with charged fee that burns debt
 */
contract ERC20X is ERC20Upgradeable, ERC20PermitUpgradeable, ERC20FlashMintUpgradeable, PausableUpgradeable, MulticallUpgradeable {
    /// @notice Using SafeMath for uint256 to prevent overflow and underflow
    using SafeMathUpgradeable for uint256;

    // TradingPool that owns this token
    Pool public pool; 
    // System contract 
    SyntheX public synthex;
    /// @notice Fee charged for flash loan % in BASIS_POINTS
    uint public flashLoanFee;
    /// @notice Basis points: 1e4 * 1e18 = 100%
    uint public constant BASIS_POINTS = 10000e18;

    /// @notice Emitted when flash fee is updated
    event FlashFeeUpdated(uint _flashLoanFee);

    event Mint(address indexed referredBy);
    event Swap(address indexed referredBy);

    function initialize(string memory _name, string memory _symbol, address _pool, address _synthex) initializer external {
        __ERC20_init(_name, _symbol);
        __ERC20FlashMint_init();
        __Pausable_init();
        pool = Pool(payable(_pool));
        synthex = SyntheX(_synthex);
    }

    modifier onlyInternal(){
        require(msg.sender == address(pool), Errors.NOT_AUTHORIZED);
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             External Functions                             */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Mint token. Issue debt
     * @param amount Amount of token to mint
     */
    function mint(uint256 amount, address recipient, address referredBy) external whenNotPaused {
        // ensure amount is greater than 0
        require(amount > 0, Errors.ZERO_AMOUNT);
        uint amountToMint = pool.commitMint(msg.sender, amount);
        // TODO check if amount is correct
        _mint(recipient, amountToMint);
        emit Mint(referredBy);
    }

    /**
     * @notice Burn synth. Repays debt
     * @param amount Amount of token to burn
     */
    function burn(uint256 amount) external whenNotPaused {
        require(amount > 0, Errors.ZERO_AMOUNT);
        amount = pool.commitBurn(msg.sender, amount);
        // TODO check if amount is correct
        _burn(msg.sender, amount);
    }

    /**
     * @notice Swap synth to another synth in pool
     * @param amount Amount of token to swap
     * @param synthTo Synth to swap to
     */
    function swap(uint256 amount, address synthTo, address _recipient, address referredBy) external whenNotPaused {
        require(amount > 0, Errors.ZERO_AMOUNT);
        amount = pool.commitSwap(_recipient, amount, synthTo);
        // TODO check if amount is correct
        _burn(msg.sender, amount);
        emit Swap(referredBy);
    }

    /**
     * @notice Liquidate with this synth
     */
    function liquidate(address account, uint256 amount, address outAsset) external whenNotPaused {
        require(amount > 0, Errors.ZERO_AMOUNT);
        amount = pool.commitLiquidate(msg.sender, account, amount, outAsset);
        // TODO sanity check
        _burn(msg.sender, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Restricted Functions                            */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Debt pool contract minting synth
     * @param account Account to mint token
     * @param amount Amount of tokens to mint
     */
    function mintInternal(address account, uint256 amount) onlyInternal external {
        _mint(account, amount);
    }

    /**
     * @notice Debt pool contract burning synth
     * @param account Account to burn from
     * @param amount Amount of tokens to burn
     */
    function burnInternal(address account, uint256 amount) onlyInternal external {
        _burn(account, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Flash Mint                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Update flash fee
     * @param _flashLoanFee New flash fee
     */
    function updateFlashFee(uint _flashLoanFee) public {
        require(synthex.isL1Admin(msg.sender), Errors.CALLER_NOT_L1_ADMIN);
        flashLoanFee = _flashLoanFee;
        emit FlashFeeUpdated(_flashLoanFee);
    }

    /**
     * @notice Return flash fee = amount * flashLoanFee / 1e18
     * @param token Token address
     * @param amount Amount of token
     */
    function _flashFee(address token, uint256 amount) internal view override returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        return amount.mul(flashLoanFee).div(BASIS_POINTS);
    }    

    function _flashFeeReceiver() internal view override returns (address) {
        return synthex.vault();
    }
}