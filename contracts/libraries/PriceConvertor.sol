// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PriceConvertor {
    using SafeMath for uint256;
    
    function t1t2(uint amount, IPriceOracle.Price memory t1Price, IPriceOracle.Price memory t2Price) internal pure returns(uint) {
        return amount.mul(t1Price.price).mul(10**t2Price.decimals).div(t2Price.price).div(10**t2Price.decimals);
    }

    function toUSD(uint amount, IPriceOracle.Price memory price) internal pure returns(uint){
        return amount.mul(price.price).div(10**price.decimals);
    }

    function toToken(uint amount, IPriceOracle.Price memory price) internal pure returns(uint){
        return amount.mul(10**price.decimals).div(price.price);
    }
}