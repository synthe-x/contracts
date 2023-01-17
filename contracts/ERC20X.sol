// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

import "./System.sol";

/**
 * @title ERC20X
 * @dev ERC20 for Synthetic Asset with minting and burning thru pool contract
 * @dev ERC20FlashMint for flash loan with charged fee that burns debt
 */
contract ERC20X is ERC20, ERC20FlashMint {
    /// @notice Using SafeMath for uint256 to prevent overflow and underflow
    using SafeMath for uint256;

    // TradingPool that owns this token
    address public pool;
    // System contract
    System public system;
    /// @notice Fee charged for flash loan % in BASIS_POINTS
    uint public flashLoanFee;
    /// @notice Basis points: 1e4 * 1e18 = 100%
    uint public constant BASIS_POINTS = 10000;
    /// @notice Emitted when flash fee is updated
    event FlashFeeUpdated(uint _flashLoanFee);

    constructor(string memory name, string memory symbol, address _pool, address _system) ERC20(name, symbol) {
        pool = _pool;
        system = System(_system);
    }

    /**
     * @notice Update flash fee
     * @param _flashLoanFee New flash fee
     */
    function updateFlashFee(uint _flashLoanFee) public {
        require(system.hasRole(system.L2_ADMIN_ROLE(), msg.sender), "ERC20X: Only L2_ADMIN_ROLE can update flash fee");
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
        return amount.mul(flashLoanFee).div(1e18).div(BASIS_POINTS);
    }

    /**
     * @notice Mint token. Only pool can mint
     * @param account Account to mint token to
     * @param amount Amount of token to mint
     */
    function mint(address account, uint256 amount) public {
        require(msg.sender == pool, "Only pool can mint");
        _mint(account, amount);
    }

    /**
     * @notice Burn token. Only pool can burn
     * @param account Account to burn token from
     * @param amount Amount of token to burn
     */
    function burn(address account, uint256 amount) public {
        require(msg.sender == pool, "Only pool can burn");
        _burn(account, amount);
    }

    /**
     * @dev Override _spendAllowance to allow pool to spend any amount of token (for repayment of issued debt)
     * @param _owner Owner of token
     * @param spender Spender of token
     * @param amount Amount of token
     */
    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        if(spender == pool) {
            return;
        }
        super._spendAllowance(_owner, spender, amount);
    }
}