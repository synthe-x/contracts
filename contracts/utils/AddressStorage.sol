// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Contract to store addresses
 * @dev This contract is used to store addresses of other contracts
 * Vaild keys are:
 * ADMIN: Admin address
 * VAULT: Vault address
 * PRICE_ORACLE: Price oracle address
 * POOL_MANAGER: Pool manager address
 * SYNTHEX: Main Synthex contract address
 */
contract AddressStorage {
    
    event AddressUpdated(bytes32 indexed key, address indexed value);

    mapping(bytes32 => address) private addresses;
    bytes32 constant ADMIN = keccak256("ADMIN");

    constructor(address _admin) {
        _setAddress(ADMIN, _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == getAddress(ADMIN), "AddressStorage: Only admin can call this function");
        _;
    }
    
    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    function setAddress(bytes32 _key, address _value) public onlyAdmin {
        addresses[_key] = _value;
        emit AddressUpdated(_key, _value);
    }

    function _setAddress(bytes32 _key, address _value) internal {
        addresses[_key] = _value;
    }
}