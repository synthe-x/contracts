// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract PriceFeed {
    uint public price;

    constructor(uint _price) {
        price = _price;
    }

    function setPrice(uint _price) public {
        price = _price;
    }

    function getPrice() public view returns(uint) {
        return price;
    }
}