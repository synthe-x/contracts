// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/Create2.sol";
// import "@openzeppelin/contracts/utils/Multicall.sol";
// import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
// import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

// import "@aave/core-v3/contracts/interfaces/IPool.sol";

// import "./../ERC20X.sol";
// import "./position/CrossPosition.sol";
// import "./position/IsolatedPosition.sol";
// import "./../interfaces/IPriceOracle.sol";
// import "./../interfaces/IDebtPool.sol";
// import "./../libraries/PriceConvertor.sol";
// import "../storage/MarginStorage.sol";

// contract Perps is IERC3156FlashBorrower {
//     using PriceConvertor for uint;
//     using SafeMath for uint;
//     using SafeERC20 for IERC20;

//     IPool public immutable POOL;
//     IPoolAddressesProvider public immutable POOL_ADDRESSES_PROVIDER;

//     IDebtPool public immutable DEBT_POOL;

//     uint public constant BASIS_POINTS = 10000e18;

//     mapping(address => address) public crossPosition;
//     mapping(bytes32 => address) public isolatedAccount;

//     enum Action {
//         OPEN,
//         CLOSE
//     }

//     struct Params_OpenHandler {
//         address supplyAsset;
//         uint256 supplyAmount;
//         uint256 fee;
//         address borrowAsset;
//         address sender;
//         uint[] prices;
//     }

//     struct Params_CloseHandler {
//         address borrowAsset;
//         uint256 borrowAmount;
//         uint256 fee;
//         address supplyAsset;
//         address sender;
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

//     function createCrossPosition() external {
//         require(crossPosition[msg.sender] == address(0), "Already created");
//         crossPosition[msg.sender] = Create2.deploy(
//             0,
//             keccak256(abi.encodePacked(msg.sender)),
//             abi.encodePacked(type(CrossPosition).creationCode, abi.encode(msg.sender, address(this)))
//         );
//     }

//     function openPosition(
//         address supplyAsset,
//         uint supplyAmount,
//         address borrowAsset,
//         uint8 leverage
//     ) external {
//         // args check
//         require(leverage >= 2, "leverage must be greater than or equal to 2");
//         require(supplyAmount > 0, "amount must be greater than 0");

//         require(crossPosition[msg.sender] != address(0), "Cross position not created");

//         IERC20(supplyAsset).safeTransferFrom(msg.sender, address(this), supplyAmount);
//         IERC20(supplyAsset).safeApprove(address(POOL), supplyAmount);
//         POOL.supply(
//             supplyAsset,
//             supplyAmount,
//             crossPosition[msg.sender],
//             0
//         );

//         require(IERC3156FlashLender(supplyAsset).flashLoan(
//             this,
//             supplyAsset,
//             supplyAmount * (leverage - 1),
//             abi.encode(Action.OPEN, borrowAsset, msg.sender)
//         ), "Flash loan failed");
//     }

//     /**
//       @notice Close position
//       @param borrowAsset Borrowed asset
//       @param borrowAmount Amount of borrowed asset to close
//       @param supplyAsset Supplied base asset
//      */
//     function closePosition(
//         address borrowAsset,
//         uint borrowAmount,
//         address supplyAsset
//     ) external {
//         // args check
//         require(borrowAmount > 0, "amount must be greater than 0");

//         require(IERC3156FlashLender(borrowAsset).flashLoan(
//             this,
//             borrowAsset,
//             borrowAmount,
//             abi.encode(Action.CLOSE, supplyAsset, msg.sender)
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

//         (Action action, address base, address sender) = abi.decode(data, (Action, address, address));

//         // get prices
//         address[] memory assets = new address[](2);
//         assets[0] = asset;
//         assets[1] = base;
//         uint[] memory prices = IPriceOracle(POOL_ADDRESSES_PROVIDER.getPriceOracle()).getAssetsPrices(assets);

//         if(action == Action.OPEN){
//             openHandler(
//                 Params_OpenHandler({
//                     supplyAsset: asset,
//                     supplyAmount: amount,
//                     fee: fee,
//                     borrowAsset: base,
//                     sender: sender,
//                     prices: prices
//                 })
//             );
//         } else if(action == Action.CLOSE){
//             closeHandler(
//                 Params_CloseHandler({
//                     borrowAsset: asset,
//                     borrowAmount: amount,
//                     fee: fee,
//                     supplyAsset: base,
//                     sender: sender,
//                     prices: prices
//                 })
//             );
//         } else {
//             return bytes32(0);
//         }

//         return keccak256("ERC3156FlashBorrower.onFlashLoan");
//     }

//     function openHandler(
//         Params_OpenHandler memory params
//     ) internal {
        
//         IERC20(params.supplyAsset).safeIncreaseAllowance(address(POOL), params.supplyAmount);
        
//         // supply synth
//         POOL.supply(
//             params.supplyAsset,
//             params.supplyAmount.sub(params.supplyAmount.mul(DEBT_POOL.swapFee()).div(BASIS_POINTS)).sub(params.fee),
//             crossPosition[params.sender],
//             0
//         );
//         // borrow synthBase
//         uint baseAmount = params.supplyAmount.t1t2(params.prices[0], params.prices[1]); // prices[supplyAsset, borrowAsset]
//         CrossPosition(crossPosition[params.sender]).borrowAndTransfer(POOL, params.borrowAsset, baseAmount, address(this));
//         // swap borrowed base asset to reserve 
//         ERC20X(params.borrowAsset).swap(baseAmount, params.supplyAsset);
//         // repay borrowed base asset
//         IERC20(params.supplyAsset).safeIncreaseAllowance(params.supplyAsset, params.supplyAmount.add(params.fee));
//     }

//     function closeHandler(
//         Params_CloseHandler memory params
//     ) internal {
//         // repay borrowed asset
//         IERC20(params.borrowAsset).safeIncreaseAllowance(address(POOL), params.borrowAmount);

//         POOL.repay(
//             params.borrowAsset,
//             params.borrowAmount.sub(params.borrowAmount.mul(DEBT_POOL.swapFee()).div(BASIS_POINTS)).sub(params.fee),
//             2,
//             crossPosition[params.sender]
//         );

//         // withdraw supplied asset
//         uint withdrawAmount = params.borrowAmount.t1t2(params.prices[0], params.prices[1]); // prices[borrowAsset, supplyAsset]
//         require(
//             CrossPosition(crossPosition[params.sender]).withdrawAndTransfer(POOL, params.supplyAsset, withdrawAmount, address(this)) == withdrawAmount,
//             "Withdraw failed"
//         );

//         // swap supplied asset 
//         ERC20X(params.supplyAsset).swap(withdrawAmount, params.borrowAsset);

//         // repay supplied asset
//         IERC20(params.borrowAsset).safeIncreaseAllowance(params.borrowAsset, params.borrowAmount.add(params.fee));
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