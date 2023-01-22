// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../System.sol";
import "./ERC20Sealed.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";


// Crowdsale contract that allows users to buy SYN tokens with ETH
contract Crowdsale is ReentrancyGuard, Pausable{

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
    uint256 public lockPeriod;
     /// @notice Unlock period is the time (in sec) over which tokens are unlocked
    uint public unlockPeriod;
        /// @notice PercUnlockAtRelease is the percentage of tokens that are unlocked at release. In Basis Points
    uint public percUnlockAtRelease;
    uint private constant BASIS_POINTS = 10000;

    System public system;

    uint lockedTill;

    /// @notice SEALED_TOKEN is the address of sealed token
    ERC20Sealed public SEALED_TOKEN;
    /// @notice TOKEN is the address of token be unlocked
    IERC20 public TOKEN;



    mapping(address => uint256) public tokenMapping;  // mapping of request with token
    mapping(address => uint256) public tokenBal; // token balance 
    mapping(address => uint256) public timeDuration; //   
    // mapping(address => uint256) public noOfRequests;  // mapping of request Id and no of requests 

// unlock 

   struct UnlockData {
        uint amount;
        uint claimed;
        uint requestTime; 
    }
    mapping(address => UnlockData) public unlockRequests;
    /// @notice User address to request count mapping
    // mapping(address => uint) public unlockRequestCount;

    uint public reservedForUnlock;


    // Events
    event TokenPurchase(address purchaser, uint256 ethValue, uint256 tokenAmount);
    event RateUpdated(address updatedBy, uint256 newRate);
    event SetLockPeriod(uint _lockPeriod);
       /// @notice Emitted when user requests to unlock their SYN tokens
    event UnlockRequested(address indexed user, bytes32 requestId, uint amount);
    /// @notice Emitted when user claims their unlocked SYN tokens
    event Unlocked(address indexed user, uint amount);


    // Errors 
    error InvalidTime(uint256 startTime, uint256 endTime);


    constructor(
     uint256 _rate, 
     uint256 _startTime,
     uint256 _endTime, 
     uint256 _lockPeriod,
     uint256 _unlockPeriod,
     uint _lockedTill,
     uint256 _percUnlockAtRelease,
     address _SEALED_TOKEN,
     address _TOKEN,
     address _system
     )
    {
     rate = _rate;
     startTime= _startTime;
     endTime = _endTime;
     lockPeriod = _lockPeriod;
     unlockPeriod = _unlockPeriod;
     lockedTill = _lockedTill;
     percUnlockAtRelease = _percUnlockAtRelease;
     system = System(_system);
     SEALED_TOKEN = ERC20Sealed(_SEALED_TOKEN);
     TOKEN = IERC20(_TOKEN);
    }


    modifier onlyL1Admin() {
        require(system.hasRole(system.L1_ADMIN_ROLE(), msg.sender), "Caller is not an admin");
        _;
    }

      modifier onlyL2Admin() {
        require(system.hasRole(system.L2_ADMIN_ROLE(), msg.sender), "Caller is not an admin");
        _;
    }


    /**
     * @notice Pause the contract
     * @dev This function is used to pause the contract in case of emergency
     */
    function pause() external onlyL2Admin {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev This function is used to unpause the contract in case of emergency
     */
    function unpause() external onlyL2Admin {
        _unpause();
    }

    // withdraw L1 role
    function withdrawFunds(address payable _adminWallet) external onlyL1Admin nonReentrant{
     require(address(this).balance > 0, "Zero Balance");
     _adminWallet.transfer(address(this).balance);

    }

    function setLockPeriod(uint _lockPeriod) external onlyL2Admin {
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(_lockPeriod);
    }

    // This fallback function 
    receive() external payable {
      buyTokens();
    }
  
    function buyTokens() public payable nonReentrant {

        require(msg.sender != address(0) && msg.value != 0);
     
        if(block.timestamp < startTime && block.timestamp > endTime) revert InvalidTime(startTime, endTime ) ;

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(getRate());

        // update state
        weiRaised = weiRaised.add(weiAmount);

        totalTokensPurchased = totalTokensPurchased.add(tokens);
    
        // keeps total amount of tokens bought in a perticular request
         tokenMapping[msg.sender]  = tokens; 

        // keeps total amount of tokens left against a perticular request
        tokenBal[msg.sender] = tokens;
        timeDuration[msg.sender] = block.timestamp;

        emit TokenPurchase(msg.sender, msg.value, tokens);
    }


    function unlock(uint _amount) external whenNotPaused {

        require(block.timestamp > lockedTill, "Cannot unlock at this stage.");
        // check if user has enough SYN to unlock
        require(remainingQuota() >= _amount && tokenBal[msg.sender] >= _amount, "Not enough SYN to unlock");
        require(_amount > 0, "Amount must be greater than 0");

        // Check if unlock request exists
     
         UnlockData storage unlockRequest = unlockRequests[msg.sender];
        require(unlockRequest.amount == 0, "Unlock request already exists");
        unlockRequest.amount = _amount;
        unlockRequest.requestTime = lockedTill;// buy request time + lockedTill period
        unlockRequest.claimed = 0;

        // Check if unlock period has passed
       
        require(block.timestamp >= unlockRequest.requestTime.add(lockPeriod), "Unlock period has not passed");

        // Calculate amount to unlock
        // Time since unlock date will give: percentage of total to unlock
        uint timeSinceUnlock = block.timestamp.sub(unlockRequest.requestTime.add(lockPeriod));
        uint percentUnlock = timeSinceUnlock.mul(1e18).div(unlockPeriod);
            
        // If unlock period has passed, unlock 100% of tokens
        if(percentUnlock > 1e18){
            percentUnlock = 1e18;
        }

        percentUnlock = percentUnlock.mul(BASIS_POINTS);

        // Calculate amount to unlock
        // Amount to unlock = (percentUnlock - (percentUnlock * percUnlockAtRelease) + percUnlockAtRelease) * unlockRequest.amount
        uint amountToUnlock = unlockRequest.amount
        .mul(
            percentUnlock.add(percUnlockAtRelease).sub(percentUnlock.mul(percUnlockAtRelease).div(BASIS_POINTS).div(1e18))
        ).div(1e18).div(BASIS_POINTS)
        .sub(unlockRequest.claimed);
        
        // If total amount to unlock is 0, return
        if(amountToUnlock == 0){
            return;
        }
        
        // Check if contract has enough SYN to unlock
        if(TOKEN.balanceOf(address(this)) < amountToUnlock){
            amountToUnlock = TOKEN.balanceOf(address(this));
        }
        TOKEN.transfer(msg.sender, amountToUnlock);

        // Increment claimed amount
        unlockRequests[msg.sender].claimed = unlockRequests[msg.sender].claimed.add(amountToUnlock);

        // release reserved SYN
        reservedForUnlock = reservedForUnlock.sub(amountToUnlock);

        emit Unlocked(msg.sender, amountToUnlock);
    }

  
    function updateRate(uint256 _rate) external onlyL2Admin {
        rate = _rate;
        emit RateUpdated(msg.sender, rate);
    }

    function closeSale() external onlyL2Admin {
      require(block.timestamp < endTime);
      endTime = block.timestamp;
    }




// View Functions
    function getRate() public view returns(uint256){
        return rate;
    }

    function remainingQuota() public view returns (uint) {
        return TOKEN.balanceOf(address(this)) - reservedForUnlock;
    }
  
    function getRequestId(address _user, uint _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _index));
    }

    function getEtherBalance(address _address) public view returns(uint256){
        return  _address.balance;
    }
}