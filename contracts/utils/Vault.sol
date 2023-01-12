pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Vault is AccessControlUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;

    address public adminAddress;
    bytes32 constant public SYNTHEX_ADMIN_ROLE = keccak256("SYNTHEX_ADMIN_ROLE");


    constructor(address _adminAddress) {
        adminAddress = _adminAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(SYNTHEX_ADMIN_ROLE, msg.sender);  // deploying address
    }


    function withdraw(address _tokenAddress, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(balance(_tokenAddress) >= amount, "Vault: Not enough amount on the Vault");
        ERC20Upgradeable(_tokenAddress).safeTransfer(adminAddress, amount);
    }


    function balance(address _tokenAddress) public view returns (uint256) {
        return ERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }
}