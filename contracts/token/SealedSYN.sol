// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Sealed.sol";

/**
 * @title Sealed SYN
 * @author SyntheX
 * @custom:security-contact prasad@chainscore.finance
 * @notice Sealed tokens cannot be transferred
 * @notice Sealed tokens can only be minted and burned
 */
contract SealedSYN is ERC20Sealed {
    
    constructor(address _admin) ERC20("Sealed SYN", "xSYN") {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Sealed)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}