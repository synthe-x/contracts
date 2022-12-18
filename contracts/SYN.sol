pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SYN is ERC20 {
    constructor() ERC20("SyntheX", "SYN") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}