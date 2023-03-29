// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OracleMock{
    constructor(){

    }
    
    mapping(address => uint256) public tokenToPrice;

    function setPrice(address _token, uint256 _price) external{
        tokenToPrice[_token] = _price;
    }
    
    function getAssetPrice(address _token) external returns(uint256){
        return tokenToPrice[_token];
    }

}