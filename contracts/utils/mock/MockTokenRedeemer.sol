// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../token/redeem/BaseTokenRedeemer.sol";

import "../../synthex/SyntheX.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TokenRedeemer
 * @author SyntheX <prasad@chainscore.finance>
 * @notice This contract is used to unlock SYN tokens for users
 * @notice Users can request to unlock their SYN tokens after a lock period
 * @notice Tokens are released linearly over a period of time (unlock period)
 */
contract MockTokenRedeemer is BaseTokenRedeemer, Pausable {
    /// @notice SafeMath library is used for uint operations
    using SafeMath for uint;
    /// @notice SafeERC20 library is used for ERC20 operations
    using SafeERC20 for IERC20;

    /// @notice LOCKED_TOKEN is the token to be unlocked
    IERC20 public LOCKED_TOKEN;
    /// @notice System contract
    SyntheX public synthex;

    /**
     * @notice Constructor
     * @param _LOCKED_TOKEN Address of SEALED_SYN
     * @param _TOKEN Address of SYN
     */
    constructor(
        address _system, 
        address _LOCKED_TOKEN, 
        address _TOKEN, 
        uint _lockPeriod, 
        uint _unlockPeriod, 
        uint _percUnlockAtRelease
    ) {
        __BaseTokenRedeemer_init(_TOKEN, _lockPeriod, _unlockPeriod, _percUnlockAtRelease);
        synthex = SyntheX(_system);
        LOCKED_TOKEN = IERC20(_LOCKED_TOKEN);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */

    modifier onlyAdmin() {
        require(synthex.isL2Admin(msg.sender), "Caller is not an admin");
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
        IERC20(address(TOKEN)).safeTransfer(msg.sender, _amount);
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
    /*                             Unlock and Claim                               */
    /* -------------------------------------------------------------------------- */
    function lock(uint _amount) external whenNotPaused {
        // transfer tokens from user to contract
        IERC20(address(TOKEN)).safeTransferFrom(msg.sender, address(this), _amount);
        // mint sealed tokens
        LOCKED_TOKEN.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Start unlocking of SYN tokens
     * @param _amount Amount of SYN to unlock
     */
    function startUnlock(uint _amount) external whenNotPaused {
        // burn sealed tokens from user
        LOCKED_TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        // start unlock
        _startUnlock(msg.sender, _amount);
    }

    /**
     * @notice Claim all unlocked SYN tokens
     * @param _requestIds Request IDs of unlock requests
     */
    function unlock(bytes32[] calldata _requestIds) external whenNotPaused {
        for(uint i = 0; i < _requestIds.length; i++){
            _unlockInternal(msg.sender, _requestIds[i]);
        }
    }
}