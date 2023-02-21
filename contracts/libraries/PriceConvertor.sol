// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../oracle/IPriceOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PriceConvertor {
    using SafeMath for uint256;
    
    uint constant public PRICE_PRECISION = 1e8;
    
    function t1t2(uint amount, uint t1Price, uint t2Price) internal pure returns(uint) {
        return amount.mul(t1Price).div(t2Price);
    }

    function toUSD(uint amount, uint price) internal pure returns(uint){
        return amount.mul(price).div(PRICE_PRECISION);
    }

    function toToken(uint amount, uint price) internal pure returns(uint){
        return amount.mul(PRICE_PRECISION).div(price);
    }
}