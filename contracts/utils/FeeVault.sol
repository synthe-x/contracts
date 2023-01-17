// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../System.sol";

/**
 * @title FeeVault
 * @notice FeeVault contract to store fees from the protocol
 * @custom:security-contact prasad@chainscore.finance
 */
contract Vault {
    using SafeERC20 for ERC20;

    // AddressStorage contract
    System public system;

    /**
     * @dev Constructor
     * @param _system System contract address
     */
    constructor(address _system) {
        system = System(_system);
    }

    /**
     * @dev Withdraw tokens from the vault
     * @param _tokenAddress Token address
     * @param amount Amount to withdraw
     * @notice Only L1_ADMIN can withdraw
     */
    function withdraw(address _tokenAddress, uint256 amount)
        external
    {
        require(system.hasRole(system.L1_ADMIN_ROLE(), msg.sender), "Vault: Only fee collector can withdraw");
        ERC20(_tokenAddress).safeTransfer(msg.sender, amount);
    }
}