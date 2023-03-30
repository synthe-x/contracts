// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../synthex/SyntheX.sol";

/**
 * @title FeeVault
 * @notice FeeVault contract to store fees from the protocol
 * @custom:security-contact prasad@chainscore.finance
 */
contract Vault {
    using SafeERC20 for ERC20;

    // AddressStorage contract
    SyntheX public synthex;

    fallback() external payable {}

    receive() external payable {}

    /**
     * @dev Constructor
     * @param _synthex System contract address
     */
    constructor(address _synthex) {
        synthex = SyntheX(_synthex);
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
        require(synthex.isL1Admin(msg.sender), Errors.CALLER_NOT_L1_ADMIN);
        ERC20(_tokenAddress).safeTransfer(msg.sender, amount);
    }
}