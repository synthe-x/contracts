// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Unlocker is Ownable {

    event UnlockRequested(address indexed user, bytes32 requestId, uint amount);
    event Unlocked(address indexed user, bytes32 requestId, uint amount);
    event SetLockPeriod(uint _lockPeriod);
    
    IERC20 public SEALED_SYN;
    IERC20 public SYN;

    uint public lockPeriod;

    mapping(bytes32 => Unlock) public unlockRequests;
    mapping(address => uint) public unlockRequestCount;

    struct Unlock {
        uint amount;
        uint requestTime;
    }

    constructor(address _SEALED_SYN, address _SYN) {
        SEALED_SYN = IERC20(_SEALED_SYN);
        SYN = IERC20(_SYN);
    }

    function setLockPeriod(uint _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(_lockPeriod);
    }

    function requestUnlock(uint _amount) external {
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, unlockRequestCount[msg.sender]));
        require(unlockRequests[requestId].amount == 0, "Unlock request already exists");

        SEALED_SYN.transferFrom(msg.sender, address(this), _amount);
        unlockRequests[requestId] = Unlock(_amount, block.timestamp);
        unlockRequestCount[msg.sender]++;

        emit UnlockRequested(msg.sender, requestId, _amount);
    }

    function unlock(bytes32 _requestId) external {
        Unlock memory unlockRequest = unlockRequests[_requestId];
        require(unlockRequest.amount > 0, "Unlock request does not exist");
        require(block.timestamp >= unlockRequest.requestTime + lockPeriod, "Unlock period has not passed");

        uint transferAmount = unlockRequest.amount;
        if(SYN.balanceOf(address(this)) < transferAmount){
            transferAmount = SYN.balanceOf(address(this));
        }
        SYN.transfer(msg.sender, transferAmount);
        unlockRequests[_requestId].amount -= transferAmount;

        emit Unlocked(msg.sender, _requestId, transferAmount);
    }


}