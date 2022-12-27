// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20X is ERC20, Ownable {


    constructor(string memory name, string memory symbol, address _pool) ERC20(name, symbol) {
        _transferOwnership(_pool);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        if(spender == owner()) {
            return;
        }
        super._spendAllowance(_owner, spender, amount);
    }
}