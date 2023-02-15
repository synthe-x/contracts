// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Position
 * @author 
 * @notice Tracks a leveraged position of a user. Cross or Isolated position can be tracked
 */
contract IsolatedPosition is Ownable {

    address public immutable pool;
    address public immutable token0;
    address public immutable token1;
    
    constructor (
        address _pool,      // aave pool
        address _token0,    
        address _token1
    ) {
        pool = _pool;
        token0 = _token0;
        token1 = _token1;
    }
}