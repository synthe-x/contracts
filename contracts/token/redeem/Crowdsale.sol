// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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

/**
 * @title Crowdsale contract
 * @author Prasad prasad@chainscore.finance
 * @notice Crowdsale contract that allows users to buy SYX tokens with ETH/ERC20 tokens at a fixed rate
 * @notice Also has whitelisting functionality
 * @dev Token release is based on TokenRedeemer contract
 */
contract Crowdsale is BaseTokenRedeemer, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    SyntheX public synthex;
    bytes32 public immutable merkleRoot;

    // start and end timestamps
    uint256 public whitelistDuration;
    uint256 public startTime;
    uint256 public endTime;

    // whitelist cap: max amount of SYX tokens that can be purchased by whitelisted users
    uint256 public whitelistCap;

    // exchange rate
    mapping (address => uint) rate;
    uint public constant RATE_PRECISION = 1e18;
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
        uint256 _whitelistDuration,
        uint256 _whitelistCap
    )
        BaseTokenRedeemer(
            _token,
            _lockPeriod,
            _unlockPeriod,
            _percUnlockAtRelease
        )
    {
        require(_startTime >= block.timestamp, Errors.INVALID_TIME);
        require(_endTime >= _startTime, Errors.INVALID_TIME);
        require(_synthex != address(0), Errors.INVALID_ADDRESS);
        require(_token != address(0), Errors.INVALID_ADDRESS);

        whitelistDuration = _whitelistDuration;
        startTime = _startTime;
        endTime = _endTime;

        whitelistCap = _whitelistCap;

        synthex = SyntheX(_synthex);
        merkleRoot = _merkleRoot;
    }

    // Receive ETH
    receive() external payable {
        buyWithETH();
    }

    fallback() external payable {
        buyWithETH();
    }

    /**
     * @notice Buy in whitelist period with ETH
     * @param _proof Merkle proof
     */
    function buyWithETH_w(bytes32[] calldata _proof) external payable whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= startTime.add(whitelistDuration), Errors.INVALID_TIME);
        // verify merkle proof 
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), Errors.INVALID_MERKLE_PROOF);
        
        require(buyWithETHInternal() < whitelistCap, Errors.EXCEEDED_MAX_CAPACITY);
    }

    /**
     * @notice Buy in whitelist period with ERC20 token
     * @param _token Token address
     * @param _amount Amount of token to spend for buying SYX
     * @param _proof Merkle proof
     */
    function buyWithToken_w(address _token, uint _amount, bytes32[] calldata _proof) external whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= startTime.add(whitelistDuration), Errors.INVALID_TIME);
        require(rate[ETH_ADDRESS] > 0, Errors.TOKEN_NOT_SUPPORTED);
        // verify merkle proof
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), Errors.INVALID_MERKLE_PROOF);

        require(buyWithTokenInternal(_token, _amount) < whitelistCap, Errors.EXCEEDED_MAX_CAPACITY);
    }

    /**
     * @notice Buy SYX tokens with ETH
     * @dev Only available after whitelist period
     */
    function buyWithETH() public payable whenNotPaused {
        require(block.timestamp >= startTime.add(whitelistDuration) && block.timestamp <= endTime, Errors.INVALID_TIME);
        buyWithETHInternal();
    }

    /**
     * @notice Internal function to buy SYX tokens with ETH
     * @dev Returns amount of SYX tokens bought
     */
    function buyWithETHInternal() internal returns (uint amount) {
        // start unlock
        amount = msg.value.mul(rate[ETH_ADDRESS]).div(RATE_PRECISION);
        require(amount > 0, Errors.ZERO_AMOUNT);
        _startUnlock(msg.sender, amount);
    }

    /**
     * @notice Buy SYX tokens with ERC20 token
     * @dev Only available after whitelist period
     * @param _token Token address to buy SYX
     * @param _amount Amount of token to spend for buying SYX
     */
    function buyWithToken(address _token, uint _amount) external whenNotPaused {
        require(block.timestamp >= startTime && block.timestamp <= endTime, Errors.INVALID_TIME);
        buyWithTokenInternal(_token, _amount);
    }

    /**
     * @notice Internal function to buy SYX tokens with ERC20 token
     * @dev Returns amount of SYX tokens bought
     */
    function buyWithTokenInternal(address _token, uint _amount) internal returns (uint amount) {
        require(rate[_token] > 0, Errors.TOKEN_NOT_SUPPORTED);
        // Transfer In
        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        // start unlock
        amount = _amount.mul(rate[_token]).div(RATE_PRECISION);
        require(amount > 0, Errors.ZERO_AMOUNT);
        _startUnlock(msg.sender, amount);
    }

    /**
     * @notice Claim all unlocked SYN tokens
     * @param _requestIds Request IDs of unlock requests
     */
    function unlock(bytes32[] calldata _requestIds) external whenNotPaused {
        for (uint256 i = 0; i < _requestIds.length; i++) {
            _unlockInternal(msg.sender, _requestIds[i]);
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
        require(block.timestamp < endTime, Errors.INVALID_TIME);
        endTime = block.timestamp;
    }

    /**
     * @notice Withdraw ETH/ERC20 tokens from contract
     * @param _token Token address
     * @param _amount Amount of token to withdraw
     */
    function withdraw(address _token, uint256 _amount) external onlyL1Admin {
        if (_token == ETH_ADDRESS) {
            Address.sendValue(payable(msg.sender), _amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
    }

    function pause() external onlyL2Admin {
        _pause();
    }

    function unpause() external onlyL2Admin {
        _unpause();
    }
}