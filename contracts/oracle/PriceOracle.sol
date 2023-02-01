// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPriceOracle.sol";
import "../System.sol";
import "../interfaces/IChainlinkAggregator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PriceOracle
 * @notice PriceOracle contract to get price of an asset (synth and collateral)
 */
contract PriceOracle is IPriceOracle {
    /// @notice Mapping to store price feed for an asset
    mapping(address => IChainlinkAggregator) public feeds;
    /// @notice AddressStorage contract
    System public system;

    constructor(address _system) {
        system = System(_system);
    }

    /**
     * @dev Set price feed for an asset
     * @param _token Asset address
     * @param _feed Price feed address
     */
    function setFeed(address _token, address _feed) public {
        // only L1_ADMIN or Governance can set price feed
        require(
            system.hasRole(system.L1_ADMIN_ROLE(), msg.sender) ||
            system.hasRole(system.GOVERNANCE_MODULE_ROLE(), msg.sender), 
            "PriceOracle: Only L1_ADMIN can set price feed"
        );

        // wrap in chainlink interface
        feeds[_token] = IChainlinkAggregator(_feed);

        // sanity check
        require(feeds[_token].latestAnswer() > 0, "PriceOracle: Price is <= 0");
        require(feeds[_token].decimals() >= 0, "PriceOracle: Decimals is <= 0");

        // emit event
        emit FeedUpdated(_token, _feed);
    }

    /**
     * @dev Get price feed address for an asset
     * @param _token Asset address
     */
    function getFeed(address _token) public view returns (address) {
        return address(feeds[_token]);
    }

    /**
     * @dev Get price for an asset from price feed
     * @param _asset Asset address
     * @return Price
     */
    function getAssetPrice(address _asset) public view returns(Price memory) {
        IChainlinkAggregator _feed = feeds[_asset];
        int256 price = _feed.latestAnswer();
        uint8 decimals = _feed.decimals();

        require(price > 0, "PriceOracle: Price is <= 0");

        return Price({
            price: uint256(price),
            decimals: decimals
        });
    }

    /**
     * @dev Get prices for multiple assets
     * @param _assets Asset addresses
     * @return Array of prices
     */
    function getAssetPrices(address[] memory _assets) public view returns(Price[] memory) {
        Price[] memory prices = new Price[](_assets.length);
        for(uint256 i = 0; i < _assets.length; i++) {
            prices[i] = getAssetPrice(_assets[i]);
        }
        return prices;
    }
}