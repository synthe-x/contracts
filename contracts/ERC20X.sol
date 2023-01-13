// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

import "./utils/AddressStorage.sol";

contract ERC20X is ERC20, ERC20FlashMint {

    address public pool;
    AddressStorage public addressStorage;

    uint public flashLoanFee;

    constructor(string memory name, string memory symbol, address _pool, address _addressStorage) ERC20(name, symbol) {
        pool = _pool;
        addressStorage = AddressStorage(_addressStorage);
    }

    function _flashFeeReceiver() internal view override returns (address){
        return addressStorage.getAddress(keccak256("VAULT"));
    }

    function updateFlashFee(uint _flashLoanFee) public {
        require(msg.sender == addressStorage.getAddress(keccak256("ADMIN")), "ERC20X: Only ADMIN can update flash fee");
        flashLoanFee = _flashLoanFee;
    }

    function _flashFee(address token, uint256 amount) internal view override returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        return amount + amount * flashLoanFee/1e18;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == pool, "Only pool can mint");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require(msg.sender == pool, "Only pool can burn");
        _burn(account, amount);
    }

    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        if(spender == pool) {
            return;
        }
        super._spendAllowance(_owner, spender, amount);
    }
}