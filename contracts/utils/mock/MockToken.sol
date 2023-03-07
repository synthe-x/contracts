// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
// ERC20Permit
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract MockToken is ERC20, ERC20Permit {

    uint public _decimals = 18;

    constructor(string memory _name, string memory _symbol, uint __decimals) ERC20(_name, _symbol) ERC20Permit(_name) {
        _decimals = __decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return uint8(_decimals);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}