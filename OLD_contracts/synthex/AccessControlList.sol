// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/Errors.sol";

contract AccessControlList is Initializable, AccessControlUpgradeable {
    /// @notice Roles for access control
    bytes32 public constant L1_ADMIN_ROLE = keccak256("L1_ADMIN_ROLE");
    bytes32 public constant L2_ADMIN_ROLE = keccak256("L2_ADMIN_ROLE");

    uint256[50] private __gap;

    function __AccessControlList_init(
        address _l0Admin, address _l1Admin, address _l2Admin
    ) public onlyInitializing {
        __AccessControlList_init_unchained(_l0Admin, _l1Admin, _l2Admin);
    }

    function __AccessControlList_init_unchained(
        address _l0Admin, address _l1Admin, address _l2Admin
    ) public onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _l0Admin);
        _setupRole(L1_ADMIN_ROLE, _l1Admin);
        _setupRole(L2_ADMIN_ROLE, _l2Admin);
        _setRoleAdmin(L2_ADMIN_ROLE, L1_ADMIN_ROLE);
    }

    function isL0Admin(address _account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function isL1Admin(address _account) public view returns (bool) {
        return hasRole(L1_ADMIN_ROLE, _account);
    }

    function isL2Admin(address _account) public view returns (bool) {
        return hasRole(L2_ADMIN_ROLE, _account);
    }

    modifier onlyL1Admin() {
        require(isL1Admin(msg.sender), Errors.NOT_AUTHORIZED);
        _;
    }

    modifier onlyL2Admin() {
        require(isL2Admin(msg.sender), Errors.NOT_AUTHORIZED);
        _;
    }
}