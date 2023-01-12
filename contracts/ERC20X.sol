// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

import "./utils/AddressManager.sol";

contract ERC20X is ERC20, ERC20FlashMint {

    bytes32 public constant VAULT = keccak256("VAULT");
    bytes32 public constant POOL_MANAGER = keccak256("POOL_MANAGER");

    address public pool;
    AddressManager public addressManager;

    uint public flashLoanFee;

    constructor(string memory name, string memory symbol, address _pool, address _addressManager) ERC20(name, symbol) {
        pool = _pool;
        addressManager = AddressManager(_addressManager);
    }

    function _flashFeeReceiver() internal view override returns (address){
        return addressManager.getAddress(VAULT);
    }

    function updateFlashFee(uint _flashLoanFee) public {
        require(msg.sender == addressManager.getAddress(POOL_MANAGER), "Only pool manager can update flash fee");
        flashLoanFee = _flashLoanFee;
    }

    function _flashFee(address token, uint256 amount) internal view override returns (uint256) {
        // silence warning about unused variable without the addition of bytecode.
        token;
        return amount + amount*flashLoanFee/1e18;
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