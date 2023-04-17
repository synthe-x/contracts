// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/Create2.sol";
// import "@openzeppelin/contracts/utils/Multicall.sol";
// import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
// import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

// import "@aave/core-v3/contracts/interfaces/IPool.sol";

// import "./position/MarginPosition.sol";
// import "../synth/IERC20X.sol";
// import "../utils/oracle/IPriceOracle.sol";
// import {IPool as IDebtPool} from "../pool/IPool.sol";
// import "./../libraries/PriceConvertor.sol";
// import "./BaseMargin.sol";

// contract Perps is BaseMargin, IERC3156FlashBorrower {
//     using PriceConvertor for uint;
//     using SafeMath for uint;
//     using SafeERC20 for IERC20;

//     IPool public immutable POOL;
//     IPoolAddressesProvider public immutable POOL_ADDRESSES_PROVIDER;
//     IDebtPool public immutable DEBT_POOL;

//     uint256 public constant BASIS_POINTS = 10000e18;

//     enum Action {
//         OPEN,
//         CLOSE
//     }

//     struct ParamsHandler {
//         address token0;
//         uint256 token0Amount;
//         uint256 fee;
//         address token1;
//         address position;
//         uint[] prices;
//     }

//     constructor(
//         IPoolAddressesProvider provider,
//         IDebtPool debtPool
//     ) {
//         DEBT_POOL = debtPool;
//         POOL = IPool(provider.getPool());
//         POOL_ADDRESSES_PROVIDER = provider;
//     }

//     function openPosition(
//         address supplyAsset,
//         uint supplyAmount,
//         address borrowAsset,
//         uint leverage,
//         uint _positionId
//     ) external {
//         // args check
//         require(leverage >= 2, "leverage must be greater than or equal to 2");
//         require(supplyAmount > 0, "amount must be greater than 0");

//         address _position = position[msg.sender][_positionId];
//         require(_position != address(0), "Position not created");

//         IERC20(supplyAsset).safeTransferFrom(msg.sender, address(this), supplyAmount);
//         IERC20(supplyAsset).safeApprove(address(POOL), supplyAmount);
//         POOL.supply(
//             supplyAsset,
//             supplyAmount,
//             _position,
//             0
//         );

//         require(IERC3156FlashLender(supplyAsset).flashLoan(
//             this,
//             supplyAsset,
//             supplyAmount * (leverage - 1),
//             abi.encode(Action.OPEN, borrowAsset, _position)
//         ), "Flash loan failed");
//     }

//     /**
//       @notice Close position
//       @param repayAsset Borrowed asset
//       @param repayAmount Amount of borrowed asset to close
//       @param withdrawAsset Supplied base asset
//      */
//     function closePosition(
//         address repayAsset,
//         uint repayAmount,
//         address withdrawAsset,
//         uint _positionId
//     ) external {
//         // args check
//         require(repayAmount > 0, "amount must be greater than 0");

//         address _position = position[msg.sender][_positionId];
//         require(_position != address(0), "Position not created");

//         require(IERC3156FlashLender(repayAsset).flashLoan(
//             this,
//             repayAsset,
//             repayAmount,
//             abi.encode(Action.CLOSE, withdrawAsset, _position)
//         ), "Flash loan failed");
//     }

//     function onFlashLoan(
//         address initiator,
//         address asset,
//         uint256 amount,
//         uint256 fee,
//         bytes calldata data
//     ) external override returns (bytes32) {
        
//         require(initiator == address(this), "Unauthorized");
//         require(msg.sender == asset, "Unauthorized");

//         ParamsHandler memory params;
//         params.token0 = asset;
//         params.token0Amount = amount;
//         params.fee = fee;

//         Action action;
//         (action, params.token1, params.position) = abi.decode(data, (Action, address, address));

//         // get prices
//         address[] memory assets = new address[](2);
//         assets[0] = params.token0;
//         assets[1] = params.token1;
//         params.prices = IPriceOracle(POOL_ADDRESSES_PROVIDER.getPriceOracle()).getAssetsPrices(assets);

//         if(action == Action.OPEN){
//             openHandler(params);
//         } else if(action == Action.CLOSE){
//             closeHandler(params);
//         } else {
//             return bytes32(0);
//         }

//         return keccak256("ERC3156FlashBorrower.onFlashLoan");
//     }

//     function openHandler(
//         ParamsHandler memory params
//     ) internal {
        
//         IERC20(params.token0).safeIncreaseAllowance(address(POOL), params.token0Amount);
        
//         (,, uint mintFee,) = DEBT_POOL.synths(params.token1);
//         (,, uint burnFee,) = DEBT_POOL.synths(params.token0);

//         // supply synth 
//         POOL.supply(
//             params.token0,
//             params.token0Amount.sub(params.token0Amount.mul(mintFee.add(burnFee)).div(BASIS_POINTS)).sub(params.fee),
//             params.position,
//             0
//         );
//         // borrow synthBase
//         uint baseAmount = params.token0Amount.t1t2(params.prices[0], params.prices[1]); // prices[supplyAsset, borrowAsset]
//         MarginPosition(params.position).borrowAndTransfer(POOL, params.token1, baseAmount, address(this));
//         // swap borrowed base asset to reserve 
//         IERC20X(params.token1).swap(baseAmount, params.token0);
//         // repay borrowed base asset
//         IERC20(params.token0).safeIncreaseAllowance(params.token0, params.token0Amount.add(params.fee));
//     }

//     function closeHandler(
//         ParamsHandler memory params
//     ) internal {
//         // repay borrowed asset
//         IERC20(params.token0).safeIncreaseAllowance(address(POOL), params.token0Amount);

//         (,, uint mintFee,) = DEBT_POOL.synths(params.token1);
//         (,, uint burnFee,) = DEBT_POOL.synths(params.token0);


//         POOL.repay(
//             params.token0,
//             params.token0Amount.sub(params.token0Amount.mul(mintFee.add(burnFee)).div(BASIS_POINTS)).sub(params.fee),
//             2,
//             params.position
//         );

//         // withdraw supplied asset
//         uint withdrawAmount = params.token0Amount.t1t2(params.prices[0], params.prices[1]); // prices[borrowAsset, supplyAsset]
//         require(
//             MarginPosition(params.position).withdrawAndTransfer(POOL, params.token1, withdrawAmount, address(this)) == withdrawAmount,
//             "Withdraw failed"
//         );

//         // swap supplied asset 
//         IERC20X(params.token1).swap(withdrawAmount, params.token0);

//         // repay supplied asset
//         IERC20(params.token0).safeIncreaseAllowance(params.token0, params.token0Amount.add(params.fee));
//     }

//     function decodeParams(
//         bytes memory _params
//     ) internal pure returns (Action action, address base, address sender) {
//         assembly {
//             action := mload(add(_params, 32))
//             base := mload(add(_params, 64))
//             sender := mload(add(_params, 96))
//         }
//     }
// }