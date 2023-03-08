// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SyntheXToken.sol";
import "../../synthex/SyntheX.sol";
import "./BaseTokenRedeemer.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Crowdsale contract that allows users to buy SYN tokens with ETH/ERC20 tokens
// Token release is based on TokenRedeemer contract
contract Crowdsale is BaseTokenRedeemer, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    SyntheX public synthex;

    // start and end timestamps
    uint256 public startTime;
    uint256 public endTime;

    // exchange rate
    mapping (address => uint) rate;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockPeriod,
        uint256 _unlockPeriod,
        uint256 _percUnlockAtRelease
    )
        BaseTokenRedeemer(
            _token,
            _lockPeriod,
            _unlockPeriod,
            _percUnlockAtRelease
        )
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @notice Start unlocking of SYN tokens
     */
    function buyWithETH() external payable whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= endTime);
        // start unlock
        _startUnlock(msg.sender, msg.value.mul(rate[ETH_ADDRESS]));
    }

    /**
     * @notice Start unlocking of SYN tokens
     */
    function buyWithToken(address _token, uint _amount) external whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= endTime);
        require(rate[ETH_ADDRESS] > 0, "Token not supported");
        // Transfer In
        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        ); 
        // start unlock
        _startUnlock(msg.sender, _amount.mul(rate[_token]));
    }

    /**
     * @notice Claim all unlocked SYN tokens
     * @param _requestIds Request IDs of unlock requests
     */
    function unlock(bytes32[] calldata _requestIds) external {
        for (uint256 i = 0; i < _requestIds.length; i++) {
            _unlockInternal(_requestIds[i]);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    modifier onlyL1Admin() {
        require(synthex.isL1Admin(msg.sender), "Not Authorized");
        _;
    }

    function updateRate(address _token, uint256 _rate) public onlyL1Admin {
        rate[_token] = _rate;
    }

    function endSale() external onlyL1Admin {
        require(block.timestamp < endTime);
        endTime = block.timestamp;
    }

    function pause() external onlyL1Admin {
        _pause();
    }

    function unpause() external onlyL1Admin {
        _unpause();
    }
}
