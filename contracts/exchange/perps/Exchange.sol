// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

import "@aave/core-v3/contracts/interfaces/IPool.sol";

import "../../ERC20X.sol";
import "./CrossPosition.sol";
import "../../interfaces/IPriceOracle.sol";
import "../../interfaces/IDebtPool.sol";
import "../../libraries/PriceConvertor.sol";

import "./IsolatedPosition.sol";

import "hardhat/console.sol";

contract Exchange is FlashLoanSimpleReceiverBase {
    using PriceConvertor for uint;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IDebtPool public immutable DEBT_POOL;

    uint public constant BASIS_POINTS = 10000e18;

    mapping(address => address) public crossAccount;
    mapping(bytes32 => address) public isolatedAccount;

    enum Action {
        LONG,
        SHORT
    }

    constructor(
        IPoolAddressesProvider provider,
        IDebtPool debtPool
    ) FlashLoanSimpleReceiverBase(provider) {
        DEBT_POOL = debtPool;
    }

    function long(
        address asset,
        uint amount,
        address base,
        uint8 leverage
    ) external {
        // args check
        require(leverage >= 2, "leverage must be greater than or equal to 2");
        require(amount > 0, "amount must be greater than 0");

        POOL.flashLoanSimple(
            address(this),
            asset,
            amount * (leverage - 1),
            abi.encodePacked(Action.LONG, base, leverage),
            0
        );

        // post sanity check
    }

    function executeOperation(
        address reserve,
        uint256 reserveAmount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        
        require(initiator == address(this), "Unauthorized");

        (Action action, address base,) = decodeParams(
            params
        );
        
        if(action == Action.LONG){
            handleLong(reserve, reserveAmount, premium, base);
            return true;
        } else if(action == Action.SHORT){

        }
        // Invalid action
        return false;
    }

    function handleLong(
        address reserve,
        uint256 reserveAmount,
        uint256 premium,
        address base
    ) internal {
        // get prices
        address[] memory assets = new address[](2);
        assets[0] = reserve;
        assets[1] = base;
        uint[] memory prices = IPriceOracle(ADDRESSES_PROVIDER.getPriceOracle()).getAssetsPrices(assets);

        uint baseAmount = reserveAmount.t1t2(prices[0], prices[1]);

        // supply synth
        POOL.supply(
            reserve,
            reserveAmount.sub(reserveAmount.mul(DEBT_POOL.swapFee()).div(BASIS_POINTS)).add(premium),
            crossAccount[msg.sender],
            0
        );
        // borrow synthBase
        CrossPosition(crossAccount[msg.sender]).borrowAndTransfer(POOL, base, baseAmount, address(this));
        // swap borrowed base asset to reserve
        ERC20X(base).swap(baseAmount, reserve);
        // repay flash loan
        IERC20(reserve).safeTransfer(address(POOL), reserveAmount.add(premium));
    }

    function decodeParams(
        bytes memory _params
    ) internal pure returns (Action, address, uint8) {
        Action action;
        address synthBase;
        uint8 leverage;
        assembly {
            action := mload(add(_params, 0x20))
            synthBase := mload(add(_params, 0x40))
            leverage := mload(add(_params, 0x60))
        }
        return (action, synthBase, leverage);
    }
}