// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20X is IERC20 {
    function mint(uint256 amount) external;

    function burn(uint256 amount) external;

    function swap(uint256 amount, address synthTo) external;

    function liquidate(address account, uint256 amount, address outAsset) external;

    function flashFee(address token, uint256 amount) external view returns (uint256);

    function maxFlashLoan(address token) external view returns (uint256);
}