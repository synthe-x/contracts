// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SyntheXToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SealedSYN.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


// Crowdsale contract that allows users to buy SYN tokens with ETH
// Issued tokens are released after 180 days
contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // start and end timestamps 
    uint256 public startTime;

    uint256 public endTime;

    // address where funds are collected
    address payable wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of tokens purchased
    uint256  totalTokensPurchased ;
 
    // Duration for which tokens will be locked
    uint256 lockInDuration;

    // no of token unlock intervals 
    uint256 unlockIntervals;



    IERC20 token;
    IERC20 sealedToken;
    mapping(address=> uint256) public tokenMapping;
    mapping(address=> uint256) public timeDuration;


    constructor(address _token, address payable _adminWallet, uint256 _rate, uint256 _startTime,uint256  _endTime, uint256 _duration, uint256 _intervals) {
     token = IERC20(_token);
     wallet = _adminWallet;
     rate = _rate;
     startTime= _startTime;
     endTime = _endTime;
     lockInDuration = _duration;
     unlockIntervals = _intervals;
    }



     // token purchase function
    function buyTokens() public payable {

        //require for token limit
        require(msg.sender != address(0));
     
        require(block.timestamp >= startTime && block.timestamp <= endTime && msg.value != 0);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());
        // update state
        weiRaised = weiRaised.add(weiAmount);

        totalTokensPurchased = totalTokensPurchased.add(tokens);
        require(totalTokensPurchased < token.balanceOf(wallet), "low token balance" );

        tokenMapping[msg.sender] = tokens; 
        timeDuration[msg.sender] = block.timestamp;
        wallet.transfer(msg.value);

    }

     function getRate() public view returns(uint256){
         return rate;
     }

    function updateRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }


  // TODO: intervals and duration logic
   function unlockTokens() public {
     require(tokenMapping[msg.sender] != 0 );
     require((timeDuration[msg.sender] - block.timestamp)/ 60 / 60 / 24 > 180, "can not unlock before 180 days");
     token.transferFrom(wallet, msg.sender, tokenMapping[msg.sender]);
   }




}