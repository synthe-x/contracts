// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AddressStorage.sol";

/**
 * @title FeeVault
 * @notice FeeVault contract to store fees from the protocol
 * @custom:security-contact prasad@chainscore.finance
 */
contract Vault {
    using SafeERC20 for ERC20;

    // AddressStorage contract
    AddressStorage public addressStorage;

    /**
     * @dev Constructor
     * @param _addressStorage AddressStorage contract address
     */
    constructor(address _addressStorage) {
        addressStorage = AddressStorage(_addressStorage);
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
        require(addressStorage.hasRole(addressStorage.L1_ADMIN_ROLE(), msg.sender), "Vault: Only fee collector can withdraw");
        ERC20(_tokenAddress).safeTransfer(msg.sender, amount);
    }
}