// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Sealed SYN
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice Sealed tokens cannot be transferred
 * @notice Sealed tokens can only be minted and burned
 */
abstract contract ERC20Sealed is ERC20, ERC20Burnable, Ownable {

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
        require(from == address(0) || to == address(0), "ERC20Sealed: Token is sealed");
    }
}