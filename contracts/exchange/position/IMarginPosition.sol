// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@aave/core-v3/contracts/interfaces/IPool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Position
 * @author 
 * @notice Tracks a leveraged position of a user. Cross or Isolated position can be tracked
 */
interface IMarginPosition {
    function owner() external view returns(address);
    function exchange() external view returns(address);
    function isSupportedMarket(address token) external view returns(bool);
    
    function supportTokens(address[] memory tokens) external;

    function withdrawAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external returns(uint);

    function borrowAndTransfer(
        IPool pool,
        address asset,
        uint256 amount,
        address recipient
    ) external;
}