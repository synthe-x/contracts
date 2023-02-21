// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "../interfaces/IChainlinkAggregator.sol";

contract MockPriceFeed /*is IChainlinkAggregator*/ {
    int public price;
    uint8 private _decimals;

    constructor(int _price, uint8 __decimals) {
        price = _price;
        _decimals = __decimals;
    }

    function setPrice(int _price, uint8 __decimals) public {
        price = _price;
        _decimals = __decimals;
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