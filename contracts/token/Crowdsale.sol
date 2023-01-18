// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TokenUnlocker.sol";


// Crowdsale contract that allows users to buy SYN tokens with ETH
contract Crowdsale is ReentrancyGuard, TokenUnlocker{

   using SafeMath for uint256;

    // start and end timestamps 
    uint256 public startTime;
    uint256 public endTime;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // amount of tokens purchased
    uint256  totalTokensPurchased ;

    // Duration for which tokens will be locked
    uint256 lockInDuration;


    mapping(bytes32 => uint256) public tokenMapping;  // mapping of request with amount and time
    mapping(bytes32 => uint256) public tokenBal; // token balance 
    mapping(address => uint256) public timeDuration; //   
    mapping(address => uint) public noOfRequests;  // mapping of request Id and no of requests 

    // Events
    event TokenPurchase(address purchaser, uint256 ethValue, uint256 tokenAmount);
    event RateUpdated(address updatedBy, uint256 newRate);

    // Errors 
    error InvalidTime(uint256 startTime, uint256 endTime);


    constructor(
     uint256 _rate, 
     uint256 _startTime,
     uint256 _endTime, 
     uint256 _duration,
     address _SEALED_TOKEN,
     address _TOKEN,
     address _system
     )TokenUnlocker(_system, _SEALED_TOKEN, _TOKEN, lockPeriod, unlockPeriod, percUnlockAtRelease){
     rate = _rate;
     startTime= _startTime;
     endTime = _endTime;
     lockInDuration = _duration;
    }


    modifier onlyL1Admin() {
        require(system.hasRole(system.L1_ADMIN_ROLE(), msg.sender), "Caller is not an admin");
        _;
    }

      modifier onlyL2Admin() {
        require(system.hasRole(system.L2_ADMIN_ROLE(), msg.sender), "Caller is not an admin");
        _;
    }

    // withdraw L2 role
    function withdrawFunds(address payable _adminWallet) external onlyL1Admin nonReentrant{
     require(address(this).balance > 0, "Zero Balance");
     _adminWallet.transfer(address(this).balance);
    }

    // This fallback function 
    receive() external payable {
      buyTokens();
    }
  
    function buyTokens() public payable nonReentrant {

        require(msg.sender != address(0) && msg.value != 0);
     
        // require(block.timestamp >= startTime && block.timestamp <= endTime && msg.value != 0);
        if(block.timestamp < startTime && block.timestamp > endTime) revert InvalidTime(startTime, endTime ) ;

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());
        // update state
        weiRaised = weiRaised.add(weiAmount);

        totalTokensPurchased = totalTokensPurchased.add(tokens);
        // require(totalTokensPurchased < remainingQuota(), "low token balance" );
        uint requestCount = uint(noOfRequests[msg.sender]).add(1);
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, requestCount));

         // mint sealed tokens
         SEALED_TOKEN.mint(msg.sender, tokens);

        // keeps total amount of tokens bought in a perticular request
         tokenMapping[requestId]  = tokens; 

        
        // keeps total amount of tokens left against a perticular request
        tokenBal[requestId] = tokens;

        timeDuration[msg.sender] = block.timestamp;

       // keeps total buy request executed by a user
        noOfRequests[msg.sender] = requestCount;

        // wallet.transfer(msg.value);
        emit TokenPurchase(msg.sender, msg.value, tokens);
    }
  
    function updateRate(uint256 _rate) external onlyL2Admin {
        rate = _rate;
        emit RateUpdated(msg.sender, rate);
    }

    function closeSale() external onlyL2Admin {
      require(block.timestamp < endTime);
      endTime = block.timestamp;
    }

    function getRate() public view returns(uint256){
        return rate;
    }

}