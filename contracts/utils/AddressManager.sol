// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract AddressManager {
    mapping(string => address) private addresses;

    function getAddress(string memory _key) public view returns (address) {
        return addresses[_key];
    }

    function setAddress(string memory _key, address _value) public {
        addresses[_key] = _value;
    }

}