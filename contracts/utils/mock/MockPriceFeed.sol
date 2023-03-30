// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// import "../interfaces/IChainlinkAggregator.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract MockPriceFeed is Ownable /*is IChainlinkAggregator*/ {
    int public price;
    uint8 private _decimals;

    constructor(int _price, uint8 __decimals) {
        price = _price;
        _decimals = __decimals;
    }

    function setPrice(int _price, uint8 __decimals) public onlyOwner {
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