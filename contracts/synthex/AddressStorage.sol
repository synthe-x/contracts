// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
 */
abstract contract AddressStorage {
    /// @notice Addresses of contracts
    bytes32 public constant VAULT = keccak256("VAULT");

    /// @notice Event to be emitted when address is updated
    event AddressUpdated(bytes32 indexed key, address indexed value);

    function vault() external view returns(address) {
        return getAddress(VAULT);
    }

    // Mapping to store addresses (hashedKey => address)
    mapping(bytes32 => address) private addresses;

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
    function _setAddress(bytes32 _key, address _value) internal {
        addresses[_key] = _value;
        emit AddressUpdated(_key, _value);
    }

    uint256[49] private __gap;
}