// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20X is ERC20, ERC20FlashMint, Ownable {
    constructor(string memory name, string memory symbol, address _pool) ERC20(name, symbol) {
        _transferOwnership(_pool);
    }

    function _flashFeeReceiver() internal view override returns (address){
        // TODO update fee vault address
        return owner();
    } 

    function _flashFee(address token, uint256 amount) internal view override returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        // TODO store/update fee param
        return amount * (1e18 + 1e16) / 1e18;
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