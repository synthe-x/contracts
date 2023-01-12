// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract AddressManager {
    mapping(bytes32 => address) private addresses;

    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    function setAddress(bytes32 _key, address _value) public {
        addresses[_key] = _value;
    }
}