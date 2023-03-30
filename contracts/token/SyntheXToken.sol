// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../synthex/SyntheX.sol";
import "../libraries/Errors.sol";

// erc165
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title SyntheX Token contract
 * @author Prasad prasad@chainscore.finance
 * @notice SyntheX Token contract, based on OpenZeppelin ERC20
 * @dev Pausable, Burnable, Permit
 */
contract SyntheXToken is ERC20Permit, ERC165, ERC20Burnable, Pausable {
    /// @notice System contract to check access control
    SyntheX public synthex;

    constructor(address _synthex) ERC20("SyntheX Token", "SYX") ERC20Permit("SyntheX Token") {
        // validate synthex address
        require(_synthex != address(0), Errors.INVALID_ADDRESS);
        // check if contract
        require(Address.isContract(_synthex), Errors.ADDRESS_IS_NOT_CONTRACT);
        // set synthex
        synthex = SyntheX(_synthex);
    }

    // support interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC20Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Pause the token transfers, mints and burns
     * @dev Only L2_ADMIN can pause
     */
    function pause() public {
        require(synthex.isL2Admin(msg.sender), Errors.CALLER_NOT_L2_ADMIN);
        _pause();
    }

    /**
     * @notice Unpause the token transfers, mints and burns
     * @dev Only L2_ADMIN can unpause
     */
    function unpause() public {
        require(synthex.isL2Admin(msg.sender), Errors.CALLER_NOT_L2_ADMIN);
        _unpause();
    }

    /**
     * @notice Mint tokens
     * @dev Only L1_ADMIN can mint
     * @param to Address to mint tokens to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public {
        require(synthex.isL1Admin(msg.sender), Errors.CALLER_NOT_L1_ADMIN);
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