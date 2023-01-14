// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    using SafeERC20 for ERC20;

    constructor(address _admin) {
        _transferOwnership(_admin);
    }

    function withdraw(address _tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        // require(ERC20(_tokenAddress).balanceOf(address(this)) >= amount, "Vault: Not enough amount on the Vault");
        ERC20(_tokenAddress).safeTransfer(owner(), amount);
    }
}