// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@aave/core-v3/contracts/interfaces/IPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IMarginPosition.sol";

/**
 * @title Position
 * @author 
 * @notice Tracks a leveraged position of a user. Cross or Isolated position can be tracked
 */
contract MarginPosition is IMarginPosition {
    using SafeERC20 for IERC20;

    address public immutable override owner;
    address public immutable override exchange;

    mapping(address => bool) public override isSupportedMarket;
    
    constructor (
        address _owner,
        address _exchange,
        address[] memory _supportedMarkets
    ) {
        owner = _owner;
        exchange = _exchange;

        for (uint i = 0; i < _supportedMarkets.length; i++) {
            isSupportedMarket[_supportedMarkets[i]] = true;
        }
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == exchange, "Unauthorized");
        _;
    }

    function supportTokens(address[] memory tokens) external override onlyAuthorized {
        for (uint i = 0; i < tokens.length; i++) {
            isSupportedMarket[tokens[i]] = true;
        }
    }

    function withdrawAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external override onlyAuthorized returns(uint) {
        require(isSupportedMarket[asset], "Asset not supported");
        // withdraw from aave
        return pool.withdraw(asset, amount, recipient);
    }

    function borrowAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external override onlyAuthorized {
        require(isSupportedMarket[asset], "Asset not supported");
        require(amount > 0, "Amount must be greater than 0");

        // borrow from aave
        pool.borrow(asset, amount, 2, 0, address(this));

        // transfer to recipient
        require(IERC20(asset).transfer(recipient, amount), "Transfer failed");
    }
}