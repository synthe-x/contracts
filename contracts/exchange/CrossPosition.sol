// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract CrossPosition {
    using SafeERC20 for IERC20;
    address public immutable owner;
    address public immutable exchange;

    constructor(
        address _owner, // owner of the contract
        address _exchange // exchange contract
    ) {
        owner = _owner;
        exchange = _exchange;
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == exchange, "Unauthorized");
        _;
    }

    function withdrawAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external onlyAuthorized returns(uint) {
        // withdraw from aave
        return pool.withdraw(asset, amount, recipient);
    }

    function borrowAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external onlyAuthorized {
        require(amount > 0, "Amount must be greater than 0");

        // console.log("amount: %s", amount);
        // borrow from aave
        pool.borrow(asset, amount, 2, 0, address(this));

        // transfer to recipient
        require(IERC20(asset).transfer(recipient, amount), "Transfer failed");
    }
}
