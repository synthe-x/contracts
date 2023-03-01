// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SyntheXToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EscrowedSYN.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Crowdsale contract that allows users to buy SYN tokens with ETH
// Issued tokens are released after 180 days
contract Crowdsale is Ownable, ReentrancyGuard {
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
    uint256 totalTokensPurchased;

    // Duration for which tokens will be locked
    uint256 lockInDuration;

    // no of token unlock intervals
    uint256 unlockIntervals;

    struct BuyRequest {
        uint amount;
        uint requestTime;
    }
    // mapping(address => uint) public buyRequestCount;

    // IERC20 token;
    // IERC20 sealedToken;
    // mapping(address=> uint256) public tokenMapping;
    // mapping(address=> uint256) public tokenBal;
    IERC20 token;
    IERC20 sealedToken;
    mapping(bytes32 => uint256) public tokenMapping; // mapping of request with amount and time
    // mapping(bytes32 => mapping(uint256 => BuyRequest)) public tokenMapping;  // mapping of requesr with amount and time
    mapping(bytes32 => uint256) public tokenBal; // token balance
    mapping(address => uint256) public timeDuration; //
    mapping(address => uint) public noOfRequests; // mapping of request Id and no of requests

    // mapping(uint256 => BuyRequest) public buyRequests;  // mapping of request Id and no of requests

    // Events
    event TokenPurchase(
        address purchaser,
        uint256 ethValue,
        uint256 tokenAmount
    );
    event TokenUnlocked(address purchaser, uint256 tokenAmount);
    // Errors
    error InvalidTime(uint256 startTime, uint256 endTime);

    constructor(
        address _token,
        address payable _adminWallet,
        uint256 _rate,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _duration,
        uint256 _intervals
    ) {
        token = IERC20(_token);
        wallet = _adminWallet;
        rate = _rate;
        startTime = _startTime;
        endTime = _endTime;
        lockInDuration = _duration;
        unlockIntervals = _intervals;
    }

    // token purchase function
    function buyTokens() public payable {
        require(msg.sender != address(0) && msg.value != 0);

        // require(block.timestamp >= startTime && block.timestamp <= endTime && msg.value != 0);
        if (block.timestamp < startTime && block.timestamp > endTime)
            revert InvalidTime(startTime, endTime);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());
        // update state
        weiRaised = weiRaised.add(weiAmount);

        totalTokensPurchased = totalTokensPurchased.add(tokens);
        require(
            totalTokensPurchased < token.balanceOf(wallet),
            "low token balance"
        );
        uint requestCount = uint(noOfRequests[msg.sender]).add(1);
        bytes32 requestId = keccak256(
            abi.encodePacked(msg.sender, requestCount)
        );

        // keeps total amount of tokens bought in a perticular request
        tokenMapping[requestId] = tokens;
        // tokenMapping[requestId][requestCount].amount  =tokens;
        // tokenMapping[requestId][requestCount].requestTime  = block.timestamp;

        // keeps total amount of tokens left against a perticular request
        tokenBal[requestId] = tokens;

        timeDuration[msg.sender] = block.timestamp;

        // keeps total buy request executed by a user
        noOfRequests[msg.sender] = requestCount;

        wallet.transfer(msg.value);
        emit TokenPurchase(msg.sender, msg.value, tokens);
    }

    function updateRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function closeSale() external onlyOwner {
        require(block.timestamp < endTime);
        endTime = block.timestamp;
    }

    // TODO: intervals and duration logic  4 intervals duration 4 months

    function unlockTokens(bytes32 _requestId) public nonReentrant {
        require(tokenMapping[_requestId] != 0);
        require(
            (timeDuration[msg.sender] - block.timestamp) >
                (lockInDuration / unlockIntervals),
            "cannot unlock before lockInPeriod"
        );
        // 3.5 months
        //   3.5/6 = 0.58
        //   (6/3)= 2
        //  total interval

        uint totalRewardsForIntervalPassed = uint(
            timeDuration[msg.sender] - block.timestamp
        ).div(lockInDuration); // 3.5/ 6 = 0.58
        uint calculatedUnlockAmt = uint(tokenMapping[_requestId]).mul(
            totalRewardsForIntervalPassed
        ); // 3.5/ 6 = 0.58 * 100 tokens = 58

        require(calculatedUnlockAmt > 0 && tokenBal[_requestId] != 0);

        token.transferFrom(wallet, msg.sender, calculatedUnlockAmt);
        timeDuration[msg.sender] = block.timestamp;
        tokenBal[_requestId] = tokenBal[_requestId] - calculatedUnlockAmt;

        emit TokenUnlocked(msg.sender, calculatedUnlockAmt);
    }

    function getRate() public view returns (uint256) {
        return rate;
    }
}
