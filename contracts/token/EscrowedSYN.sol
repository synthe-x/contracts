// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../system/System.sol";
import "hardhat/console.sol";

/**
 * @title Locked SYN
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice Sealed tokens cannot be transferred
 * @notice Sealed tokens can only be minted and burned
 */
contract EscrowedSYN is ERC20, ERC20Burnable, AccessControl {
    /// @notice System contract
    System public system;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant AUTHORIZED_SENDER = keccak256("AUTHORIZED_SENDER");

    constructor(address _system) ERC20("Escrowed SYN", "esSYN") {
        system = System(_system);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    /**
     * @notice Sealed tokens cannot be transferred, can only be minted and burned
     */
    function _transfer(
        address,
        address,
        uint256
    ) internal virtual override {
        require(
            hasRole(AUTHORIZED_SENDER, msg.sender), 
            "Not authorized to transfer"
        );
    }
    
    /**
     * @notice L1_ADMIN can grant MINTER_ROLE to any address
     */
    function grantRole(bytes32 role, address account) public override {
        require(system.isL1Admin(msg.sender), "EscrowedSYN: Only L1_ADMIN can grant roles");
        _grantRole(role, account);
    }

    /**
     * @notice L1_ADMIN can revoke MINTER_ROLE from any address
     */
    function revokeRole(bytes32 role, address account) public override {
        require(system.isL1Admin(msg.sender), "EscrowedSYN: Only L1_ADMIN can revoke roles");
        _revokeRole(role, account);
    }
}