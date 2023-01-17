// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

import "../System.sol";

contract SyntheXToken is ERC20, ERC20Burnable, Pausable, ERC20Permit, ERC20Votes {
    /// @notice AddressStorage contract
    System public system;
    /// @notice Storing admin role hash here to save gas
    bytes32 public constant L1_ADMIN_ROLE = keccak256("L1_ADMIN_ROLE");
    bytes32 public constant L2_ADMIN_ROLE = keccak256("L2_ADMIN_ROLE");

    constructor(address _system) ERC20("SyntheX Token", "SYN") ERC20Permit("SyntheX Token") {
        system = System(_system);
    }

    /**
     * @notice Pause the token transfers, mints and burns
     * @dev Only L2_ADMIN can pause
     */
    function pause() public {
        require(system.hasRole(system.L2_ADMIN_ROLE(), msg.sender));
        _pause();
    }

    /**
     * @notice Unpause the token transfers, mints and burns
     * @dev Only L2_ADMIN can unpause
     */
    function unpause() public {
        require(system.hasRole(system.L2_ADMIN_ROLE(), msg.sender));
        _unpause();
    }

    /**
     * @notice Mint tokens
     * @dev Only L1_ADMIN can mint
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public {
        require(system.hasRole(system.L1_ADMIN_ROLE(), msg.sender));
        _mint(to, amount);
    }

    /**
     * @dev Override _beforeTokenTransfer hook to add pausable functionality
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}