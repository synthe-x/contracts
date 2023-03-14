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

// MerkleProof
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Crowdsale contract that allows users to buy SYN tokens with ETH/ERC20 tokens
// Token release is based on TokenRedeemer contract
contract Crowdsale is BaseTokenRedeemer, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    SyntheX public synthex;
    bytes32 public immutable merkleRoot;

    // start and end timestamps
    uint256 public whitelistDuration;
    uint256 public startTime;
    uint256 public endTime;

    // exchange rate
    mapping (address => uint) rate;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(
        address _synthex,
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockPeriod,
        uint256 _unlockPeriod,
        uint256 _percUnlockAtRelease,
        bytes32 _merkleRoot,
        uint256 _whitelistDuration
    )
        BaseTokenRedeemer(
            _token,
            _lockPeriod,
            _unlockPeriod,
            _percUnlockAtRelease
        )
    {
        require(_startTime >= block.timestamp, Errors.INVALID_ARGUMENT);
        require(_endTime >= _startTime, Errors.INVALID_ARGUMENT);
        require(_synthex != address(0), Errors.INVALID_ARGUMENT);
        require(_token != address(0), Errors.INVALID_ARGUMENT);

        whitelistDuration = _whitelistDuration;
        startTime = _startTime;
        endTime = _endTime;

        synthex = SyntheX(_synthex);
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Buy in whitelist period with ETH
     * @param _proof Merkle proof
     */
    function buyWithETH_w(bytes32[] calldata _proof) external payable whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= startTime.add(whitelistDuration));
        // make sure address is not a contract
        require(!Address.isContract(msg.sender), Errors.ADDRESS_IS_CONTRACT);
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), Errors.INVALID_MERKLE_PROOF);
        // start unlock
        _startUnlock(msg.sender, msg.value.mul(rate[ETH_ADDRESS]));
    }

    /**
     * @notice Buy in whitelist period with ERC20 token
     * @param _token Token address
     * @param _amount Amount of token to spend for buying SYX
     * @param _proof Merkle proof
     */
    function buyWithToken_w(address _token, uint _amount, bytes32[] calldata _proof) external whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= startTime.add(whitelistDuration));
        require(rate[ETH_ADDRESS] > 0, Errors.TOKEN_NOT_SUPPORTED);
        // make sure address is not a contract
        require(!Address.isContract(msg.sender), Errors.ADDRESS_IS_CONTRACT);
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), Errors.INVALID_MERKLE_PROOF);
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
     * @notice Buy SYX tokens with ETH
     * @dev Only available after whitelist period
     */
    function buyWithETH() external payable whenNotPaused {
        require(block.timestamp >= startTime.add(whitelistDuration) && block.timestamp <= endTime);
        // start unlock
        _startUnlock(msg.sender, msg.value.mul(rate[ETH_ADDRESS]));
    }

    /**
     * @notice Buy SYX tokens with ERC20 token
     * @dev Only available after whitelist period
     * @param _token Token address to buy SYX
     * @param _amount Amount of token to spend for buying SYX
     */
    function buyWithToken(address _token, uint _amount) external whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= endTime);
        require(rate[ETH_ADDRESS] > 0, Errors.TOKEN_NOT_SUPPORTED);
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
    function unlock(bytes32[] calldata _requestIds) external whenNotPaused {
        for (uint256 i = 0; i < _requestIds.length; i++) {
            _unlockInternal(_requestIds[i]);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    modifier onlyL1Admin() {
        require(synthex.isL1Admin(msg.sender), Errors.CALLER_NOT_L1_ADMIN);
        _;
    }

    modifier onlyL2Admin() {
        require(synthex.isL2Admin(msg.sender), Errors.CALLER_NOT_L2_ADMIN);
        _;
    }

    function updateRate(address _token, uint256 _rate) public onlyL1Admin {
        rate[_token] = _rate;
    }

    function endSale() external onlyL1Admin {
        require(block.timestamp < endTime);
        endTime = block.timestamp;
    }

    function pause() external onlyL2Admin {
        _pause();
    }

    function unpause() external onlyL2Admin {
        _unpause();
    }
}
