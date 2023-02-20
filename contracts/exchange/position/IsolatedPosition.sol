// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@aave/core-v3/contracts/interfaces/IPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Position
 * @author 
 * @notice Tracks a leveraged position of a user. Cross or Isolated position can be tracked
 */
contract IsolatedPosition {
    using SafeERC20 for IERC20;

    address public immutable owner;
    address public immutable exchange;

    address public immutable token0;
    address public immutable token1;
    
    constructor (
        address _owner,
        address _exchange,
        address _token0,    
        address _token1
    ) {
        token0 = _token0;
        token1 = _token1;
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
        require(asset == token0 || asset == token1, "Asset not supported");
        // withdraw from aave
        return pool.withdraw(asset, amount, recipient);
    }

    function borrowAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external onlyAuthorized {
        require(asset == token0 || asset == token1, "Asset not supported");
        require(amount > 0, "Amount must be greater than 0");

        // borrow from aave
        pool.borrow(asset, amount, 2, 0, address(this));

        // transfer to recipient
        require(IERC20(asset).transfer(recipient, amount), "Transfer failed");
    }
}