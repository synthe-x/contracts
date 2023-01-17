// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Sealed.sol";
import "../System.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenUnlocker
 * @author SyntheX <prasad@chainscore.finance>
 * @notice This contract is used to unlock SYN tokens for users
 * @notice Users can request to unlock their SYN tokens after a lock period
 * @notice Tokens are released linearly over a period of time (unlock period)
 */
contract TokenUnlocker is Pausable {
    /// @notice SafeMath library is used for uint operations
    using SafeMath for uint;
    
    /// @notice Emitted when user requests to unlock their SYN tokens
    event UnlockRequested(address indexed user, bytes32 requestId, uint amount);
    /// @notice Emitted when user claims their unlocked SYN tokens
    event Unlocked(address indexed user, bytes32 requestId, uint amount);
    /// @notice Emitted when admin sets the lock period
    event SetLockPeriod(uint _lockPeriod);
    
    /// @notice Unlock data struct
    struct UnlockData {
        uint amount;
        uint claimed;
        uint requestTime;
    }

    /// @notice SEALED_TOKEN is the address of sealed token
    ERC20Sealed public SEALED_TOKEN;
    /// @notice TOKEN is the address of token be unlocked
    IERC20 public TOKEN;
    /// @notice Reserved for unlock is the amount of SYN that is reserved for unlock
    uint public reservedForUnlock;
    /// @notice Lock period is the time (in sec) that user must wait before they can claim their unlocked SYN
    uint public lockPeriod;
    /// @notice Unlock period is the time (in sec) over which tokens are unlocked
    uint public unlockPeriod;
    /// @notice PercUnlockAtRelease is the percentage of tokens that are unlocked at release. In Basis Points
    uint public percUnlockAtRelease;
    uint private constant BASIS_POINTS = 10000;
    /// @notice Request ID to Unlock struct mapping
    /// @notice Request ID is a hash of user address and request index
    mapping(bytes32 => UnlockData) public unlockRequests;
    /// @notice User address to request count mapping
    mapping(address => uint) public unlockRequestCount;
    /// @notice System contract
    System public system;

    /**
     * @notice Constructor
     * @param _SEALED_TOKEN Address of SEALED_SYN
     * @param _TOKEN Address of SYN
     */
    constructor(address _system, address _SEALED_TOKEN, address _TOKEN, uint _lockPeriod, uint _unlockPeriod, uint _percUnlockAtRelease) {
        system = System(_system);
        SEALED_TOKEN = ERC20Sealed(_SEALED_TOKEN);
        TOKEN = IERC20(_TOKEN);
        lockPeriod = _lockPeriod;
        unlockPeriod = _unlockPeriod;
        percUnlockAtRelease = _percUnlockAtRelease;
    }

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Gets remaining quota of SYN that can be set to be unlocked
     */
    function remainingQuota() public view returns (uint) {
        return TOKEN.balanceOf(address(this)) - reservedForUnlock;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    modifier onlyAdmin() {
        require(system.hasRole(system.L2_ADMIN_ROLE(), msg.sender), "Caller is not an admin");
        _;
    }
    /**
     * @notice Admin can update the lock period
     * @notice Lock period is the time that user must wait before they can claim their unlocked SYN
     * @notice Default lock period is 30 days. This function can be used to change the lock period in case delay/early is needed
     * @param _lockPeriod New lock period
     */
    function setLockPeriod(uint _lockPeriod) external onlyAdmin {
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(_lockPeriod);
    }

    /**
     * @notice Withdraw SYN from the contract
     * @param _amount Amount of SYN to withdraw
     * @dev This function is only used to withdraw extra SYN from the contract
     * @dev Reserved amount for unlock will not be withdrawn
     */
    function withdraw(uint _amount) external onlyAdmin {
        require(_amount <= remainingQuota(), "Not enough SYN to withdraw");
        TOKEN.transfer(msg.sender, _amount);
    }

    /**
     * @notice Pause the contract
     * @dev This function is used to pause the contract in case of emergency
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev This function is used to unpause the contract in case of emergency
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Public Functions                              */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Start unlocking of SYN tokens
     * @param _amount Amount of SYN to unlock
     */
    function startUnlock(uint _amount) external whenNotPaused {
        // check if user has enough SYN to unlock
        require(remainingQuota() >= _amount, "Not enough SYN to unlock");
        require(_amount > 0, "Amount must be greater than 0");

        // burn sealed tokens from user
        SEALED_TOKEN.burnFrom(msg.sender, _amount);

        // create unlock request
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, unlockRequestCount[msg.sender]));
        
        UnlockData storage _unlockRequest = unlockRequests[requestId];
        require(_unlockRequest.amount == 0, "Unlock request already exists");
        _unlockRequest.amount = _amount;
        _unlockRequest.requestTime = block.timestamp;
        _unlockRequest.claimed = 0;

        // increment request count
        unlockRequestCount[msg.sender]++;

        // reserve SYN for unlock
        reservedForUnlock = reservedForUnlock.add(_amount);

        emit UnlockRequested(msg.sender, requestId, _amount);
    }

    /**
     * @notice Claim unlocked SYN tokens
     * @param _requestId Request ID of unlock request
     */
    function _unlockInternal(bytes32 _requestId) internal whenNotPaused {
        // Check if unlock request exists
        UnlockData memory unlockRequest = unlockRequests[_requestId];
        require(unlockRequest.amount > 0, "Unlock request does not exist");
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
        unlockRequests[_requestId].claimed = unlockRequests[_requestId].claimed.add(amountToUnlock);

        // release reserved SYN
        reservedForUnlock = reservedForUnlock.sub(amountToUnlock);

        emit Unlocked(msg.sender, _requestId, amountToUnlock);
    }

    /**
     * @notice Claim all unlocked SYN tokens
     * @param _requestIds Request IDs of unlock requests
     */
    function unlock(bytes32[] calldata _requestIds) external {
        for(uint i = 0; i < _requestIds.length; i++){
            _unlockInternal(_requestIds[i]);
        }
    }

    /**
     * @notice Get request ID
     */
    function getRequestId(address _user, uint _unlockIndex) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _unlockIndex));
    }
}