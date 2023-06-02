//SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../../interfaces/compound/CTokenInterface.sol";

interface IPriceOracleETH {
    /// @notice The ETH-USD aggregator address
    function ethUsdAggregator() external view returns (address);

    /**
     * @notice Get the underlying price of a listed cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function getUnderlyingPrice(CTokenInterface cToken) external view returns (uint256);
}