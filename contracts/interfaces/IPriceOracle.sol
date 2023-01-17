// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracle {
    /**
     * @dev Emitted when price feed address is updated
     */
    event FeedUpdated(address indexed token, address indexed feed);
    
    /**
     * @dev Price data structure
     */
    struct Price {
        uint256 price;
        uint256 decimals;
    }
    /**
     * @dev Get price feed address for an asset
     * @param _token Asset address
     */
    function getFeed(address _token) external view returns (address);

    /**
     * @dev Get price for an asset
     * @param _asset Asset address
     * @return Price
     */
    function getAssetPrice(address _asset) external view returns(Price memory);

    /**
     * @dev Get prices for multiple assets
     * @param _assets Array of asset addresses
     * @return Array of prices
     */
    function getAssetPrices(address[] memory _assets) external view returns(Price[] memory);
}