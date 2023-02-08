// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./AddressStorage.sol";

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
 * GOVERNANCE_MODULE - Can handle proposals actions passed thru protocol governance
 */
contract System is AddressStorage, AccessControlUpgradeable {

    /// @notice Roles for access control
    bytes32 public constant L1_ADMIN_ROLE = keccak256("L1_ADMIN_ROLE");
    bytes32 public constant L2_ADMIN_ROLE = keccak256("L2_ADMIN_ROLE");
    bytes32 public constant GOVERNANCE_MODULE_ROLE = keccak256("GOVERNANCE_MODULE_ROLE");

    /// @notice Address storage keys
    bytes32 public constant PRICE_ORACLE = keccak256("PRICE_ORACLE");
    bytes32 public constant VAULT = keccak256("VAULT");
    bytes32 public constant SYNTHEX = keccak256("SYNTHEX");

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

    /* -------------------------------------------------------------------------- */
    /*                            Role Access Controļ                            */
    /* -------------------------------------------------------------------------- */
    function isL0Admin(address _account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function isL1Admin(address _account) external view returns (bool) {
        return hasRole(L1_ADMIN_ROLE, _account);
    }

    function isL2Admin(address _account) external view returns (bool) {
        return hasRole(L2_ADMIN_ROLE, _account);
    }

    function isGovernanceModule(address _account) external view returns (bool) {
        return hasRole(GOVERNANCE_MODULE_ROLE, _account);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Address Getteŗ̧̧                             */
    /* -------------------------------------------------------------------------- */
    function priceOracle() external view returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    function vault() external view returns (address) {
        return getAddress(VAULT);
    }

    function synthex() external view returns (address) {
        return getAddress(SYNTHEX);
    }
}