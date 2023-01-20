// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./utils/AddressStorage.sol";

/**
 * @title System
 * @author SyntheX 
 * @custom:security-contact prasad@chainscore.finance
 * 
 * @notice Stores address, manages roles and access control
 * 
 * @notice This contract is used to access control of the protocol
 * @dev There are 3 levels of admin, and 1 governance module:
 * DEFAULT_ADMIN - Backup admin
 * L1_ADMIN - Top admininistrator: can set addresses, can upgrade contracts
 * L2_ADMIN - Admin to manage contracts params
 * GOVERNANCE_MODULE - Can handle proposals passed thru protocol governance
 */
contract System is AddressStorage, AccessControlUpgradeable {

    /// @notice Roles for access control
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

    function setAddress(bytes32 _key, address _value) external onlyRole(L1_ADMIN_ROLE) {
        _setAddress(_key, _value);
    }
}