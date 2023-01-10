// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../interfaces/IChainlinkAggregator.sol";

contract PriceFeed is IChainlinkAggregator {
    int public price;
    uint8 private _decimals;

    constructor(int _price) {
        price = _price;
    }

    function setPrice(int _price) public {
        price = _price;
    }
    
    function latestAnswer() external view returns (int256){
        return price;
    }

    function decimals() external view returns (uint8){
        return _decimals;
    }

    function latestTimestamp() external view returns (uint256){
        return block.timestamp;
    }
}