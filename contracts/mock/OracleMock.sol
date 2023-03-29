// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OracleMock{
    constructor(){

    }
    
    mapping(address => uint256) public tokenToPrice;

    function setPrice(address _token, uint256 _price) external{
        tokenToPrice[_token] = _price;
    }
    
    function getAssetPrice(address _token) public view returns(uint256){
        return tokenToPrice[_token];
    }

    function getAssetsPrices(address[] calldata assets) external view returns (uint[] memory){
        uint256[] memory res  = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++){
            res[i] = getAssetPrice(assets[i]);
        }

        return res;
    }

}