// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../synthex/SyntheX.sol";
import "hardhat/console.sol";

/**
 * @title Locked SYN
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice Sealed tokens can only be transferred by authorized senders
 * @notice Sealed tokens can only be minted and burned by authorized minters and burners
 */
contract EscrowedSYN is ERC20, ERC20Permit, ERC20Burnable, AccessControl {
    /// @notice System contract
    SyntheX public synthex;

    // This role can transfer tokens
    bytes32 public constant AUTHORIZED_SENDER = keccak256("AUTHORIZED_SENDER");

    constructor(address _synthex) ERC20("Escrowed SYN", "esSYN") ERC20Permit("Escrowed SYN") {
        synthex = SyntheX(_synthex);
    }

    function mint(address to, uint256 amount) public {
        require(synthex.isL1Admin(msg.sender), "EscrowedSYN: Only L1_ADMIN can mint tokens");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(synthex.isL1Admin(msg.sender), "EscrowedSYN: Only L1_ADMIN can mint tokens");
        _burn(from, amount);
    }

    /**
     * @notice Sealed tokens can be transferred only by authorized senders
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
        require(synthex.isL1Admin(msg.sender), "EscrowedSYN: Only L1_ADMIN can grant roles");
        _grantRole(role, account);
    }

    /**
     * @notice L1_ADMIN can revoke MINTER_ROLE from any address
     */
    function revokeRole(bytes32 role, address account) public override {
        require(synthex.isL1Admin(msg.sender), "EscrowedSYN: Only L1_ADMIN can revoke roles");
        _revokeRole(role, account);
    }
}