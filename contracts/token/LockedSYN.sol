// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Locked.sol";
import "../System.sol";

/**
 * @title Locked SYN
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice Sealed tokens cannot be transferred
 * @notice Sealed tokens can only be minted and burned
 */
contract LockedSYN is ERC20Locked {
    /// @notice AddressStorage contract
    System public system;
    
    constructor(address _system) ERC20("Locked SYN", "xSYN") {
        system = System(_system);
    }

    /**
     * @notice L1_ADMIN can grant MINTER_ROLE to any address
     */
    function grantMinterRole(address minter) public {
        require(system.hasRole(system.L1_ADMIN_ROLE(), msg.sender), "SealedSYN: Only L1_ADMIN can grant MINTER_ROLE");
        _setupRole(MINTER_ROLE, minter);
    }

    /**
     * @notice L1_ADMIN can revoke MINTER_ROLE from any address
     */
    function revokeMinterRole(address minter) public {
        require(system.hasRole(system.L1_ADMIN_ROLE(), msg.sender), "SealedSYN: Only L1_ADMIN can revoke MINTER_ROLE");
        revokeRole(MINTER_ROLE, minter);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Locked)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}