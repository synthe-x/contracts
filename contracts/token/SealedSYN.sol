// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SealedSYN is ERC20 {
    constructor() ERC20("Sealed SYN", "sSYN") {
        _mint(msg.sender, 32100000 * 10 ** decimals());
    }
}