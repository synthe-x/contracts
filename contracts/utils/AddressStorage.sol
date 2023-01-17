// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Address Storage
 * @author SyntheX (prasad@chainscore.finance)
 * 
 * @notice Contract to store addresses
 * @notice This contract is used to store addresses of other contracts
 * @dev Vaild keys are:
 * VAULT - Vault address
 * PRICE_ORACLE - Price oracle address
 * SYNTHEX - Main Synthex contract address
 * 
 * @notice This contract is used to access control of the protocol
 * @dev There are 3 levels of admin, and 1 governance module:
 * DEFAULT_ADMIN - Backup admin
 * L1_ADMIN - Top admininistrator: can set addresses, can upgrade contracts
 * L2_ADMIN - Admin to manage contracts params
 * GOVERNANCE_MODULE - Can handle proposals passed thru protocol governance
 */
contract AddressStorage is AccessControl {
    /// @notice Event to be emitted when address is updated
    event AddressUpdated(bytes32 indexed key, address indexed value);

    /// @notice Mapping to store addresses (hashedKey => address)
    mapping(bytes32 => address) private addresses;

    /// @notice Roles
    bytes32 public constant L1_ADMIN_ROLE = keccak256("L1_ADMIN_ROLE");
    bytes32 public constant L2_ADMIN_ROLE = keccak256("L2_ADMIN_ROLE");
    bytes32 public constant GOVERNANCE_MODULE_ROLE = keccak256("GOVERNANCE_MODULE_ROLE");

    /**
     * @notice Constructor to set initial admin addresses
     */
    constructor(address _l0Admin, address _l1Admin, address _l2Admin, address _governanceModule) {
        _setupRole(DEFAULT_ADMIN_ROLE, _l0Admin);
        _setupRole(L1_ADMIN_ROLE, _l1Admin);
        _setupRole(L2_ADMIN_ROLE, _l2Admin);
        _setRoleAdmin(L2_ADMIN_ROLE, L1_ADMIN_ROLE);
        _setupRole(GOVERNANCE_MODULE_ROLE, _governanceModule);
        _setRoleAdmin(GOVERNANCE_MODULE_ROLE, L1_ADMIN_ROLE);
    }

    /**
     * @notice Function to get address of a contract
     * @param _key Key of the address
     * @return Address of the contract
     */
    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    /**
     * @notice Function to set address of a contract
     * @param _key Key of the address
     * @param _value Address of the contract
     */
    function setAddress(bytes32 _key, address _value) public onlyRole(L1_ADMIN_ROLE) {
        addresses[_key] = _value;
        emit AddressUpdated(_key, _value);
    }
}