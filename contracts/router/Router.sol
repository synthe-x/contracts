// SPDX-License-Identifier: MIT

contract Router {
    struct SwapData {
        address pair;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        uint256 deadline;
        bool isBalancer;
    }

    function swap(SwapData[] memory swapDatas) external {

    }
}