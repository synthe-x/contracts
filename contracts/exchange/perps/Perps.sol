// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

import "@aave/core-v3/contracts/interfaces/IPool.sol";

import "../../ERC20X.sol";
import "../CrossPosition.sol";
import "../../interfaces/IPriceOracle.sol";
import "../../interfaces/IDebtPool.sol";
import "../../libraries/PriceConvertor.sol";

import "../IsolatedPosition.sol";

import "hardhat/console.sol";

contract Perps is IERC3156FlashBorrower {
    using PriceConvertor for uint;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IPool public immutable POOL;
    IPoolAddressesProvider public immutable POOL_ADDRESSES_PROVIDER;

    IDebtPool public immutable DEBT_POOL;

    uint public constant BASIS_POINTS = 10000e18;

    mapping(address => address) public crossPosition;
    mapping(bytes32 => address) public isolatedAccount;

    constructor(
        IPoolAddressesProvider provider,
        IDebtPool debtPool
    ) {
        DEBT_POOL = debtPool;
        POOL = IPool(provider.getPool());
        POOL_ADDRESSES_PROVIDER = provider;
    }

    function createCrossPosition() external {
        require(crossPosition[msg.sender] == address(0), "Already created");
        crossPosition[msg.sender] = Create2.deploy(
            0,
            keccak256(abi.encodePacked(msg.sender)),
            abi.encodePacked(type(CrossPosition).creationCode, abi.encode(msg.sender, address(this)))
        );
    }

    function openPosition(
        address asset,
        uint amount,
        address base,
        uint8 leverage
    ) external {
        // args check
        require(leverage >= 2, "leverage must be greater than or equal to 2");
        require(amount > 0, "amount must be greater than 0");

        require(IERC3156FlashLender(asset).flashLoan(
            this,
            asset,
            amount * (leverage - 1),
            abi.encode(base, msg.sender)
        ), "Flash loan failed");

        // TODO: post sanity check
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        
        require(initiator == address(this), "Unauthorized");

        (address base, address sender) = decodeParams(
            data
        );

        handler(HandlerParams({
                    reserve: token,
                    reserveAmount: amount,
                    premium: fee,
                    base: base,
                    sender: sender
                }));

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    struct HandlerParams {
        address reserve;
        uint256 reserveAmount;
        uint256 premium;
        address base;
        address sender;
    }

    function handler(
        HandlerParams memory params
    ) internal {
        // get prices
        // get prices
        address[] memory assets = new address[](2);
        assets[0] = params.reserve;
        assets[1] = params.base;
        uint[] memory prices = IPriceOracle(POOL_ADDRESSES_PROVIDER.getPriceOracle()).getAssetsPrices(assets);


        uint baseAmount = params.reserveAmount.t1t2(prices[0], prices[1]);

        IERC20(params.reserve).safeIncreaseAllowance(address(POOL), params.reserveAmount);
        
        // supply synth
        POOL.supply(
            params.reserve,
            params.reserveAmount.sub(params.reserveAmount.mul(DEBT_POOL.swapFee()).div(BASIS_POINTS)).sub(params.premium),
            crossPosition[params.sender],
            0
        );
        // borrow synthBase
        CrossPosition(crossPosition[params.sender]).borrowAndTransfer(POOL, params.base, baseAmount, address(this));
        // swap borrowed base asset to reserve
        ERC20X(params.base).swap(baseAmount, params.reserve);
        // repay borrowed base asset
        IERC20(params.reserve).safeIncreaseAllowance(params.reserve, params.reserveAmount.add(params.premium));
    }

    function decodeParams(
        bytes memory _params
    ) internal pure returns (address base, address sender) {
        assembly {
            base := mload(add(_params, 32))
            sender := mload(add(_params, 64))
        }
    }
}