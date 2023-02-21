// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 

contract MockToken is ERC20 {

    uint public _decimals = 18;

    constructor(string memory name, string memory symbol, uint __decimals) ERC20(name, symbol) {
        _decimals = __decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return uint8(_decimals);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}