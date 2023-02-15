// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
// safe erc20
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function supply(
        IPool pool,
        address asset,
        uint256 amount
    ) external onlyAuthorized returns(uint) {
        // transfer from owner to this contract
        require(IERC20(asset).transferFrom(owner, address(this), amount), "Transfer failed");
        // approve aave
        IERC20(asset).safeApprove(address(pool), amount);

        IPool(pool).supply(asset, amount, address(this), 0);
        
        return amount;
    }

    function withdraw(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external onlyAuthorized returns (uint256) {
        // withdraw from aave
        return pool.withdraw(asset, amount, recipient);
    }

    function borrowAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external onlyAuthorized returns (uint256) {
        uint preBorrowBalance = IERC20(asset).balanceOf(address(this));
        // borrow from aave
        pool.borrow(asset, amount, 2, 0, address(this));

        require(
            IERC20(asset).balanceOf(address(this)) >= preBorrowBalance + amount,
            "Borrow failed"
        );

        // transfer to recipient
        require(IERC20(asset).transfer(recipient, amount), "Transfer failed");

        return amount;
    }
}
