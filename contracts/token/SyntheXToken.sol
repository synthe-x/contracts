// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "../synthex/SyntheX.sol";

contract SyntheXToken is ERC20, ERC20Burnable, Pausable, ERC20Permit {
    /// @notice System contract to check access control
    SyntheX public synthex;

    constructor(address _synthex) ERC20("SyntheX Token", "SYX") ERC20Permit("SyntheX Token") {
        synthex = SyntheX(_synthex);
    }

    /**
     * @notice Pause the token transfers, mints and burns
     * @dev Only L2_ADMIN can pause
     */
    function pause() public {
        require(synthex.isL2Admin(msg.sender));
        _pause();
    }

    /**
     * @notice Unpause the token transfers, mints and burns
     * @dev Only L2_ADMIN can unpause
     */
    function unpause() public {
        require(synthex.isL2Admin(msg.sender));
        _unpause();
    }

    /**
     * @notice Mint tokens
     * @dev Only L1_ADMIN can mint
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public {
        require(synthex.isL1Admin(msg.sender));
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
}