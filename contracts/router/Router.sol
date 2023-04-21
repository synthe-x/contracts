// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "../pool/IPool.sol";

contract Router {
    struct BatchSwapStep {
        bytes32 pair;
        bytes userData;
        uint128 assetInIndex;
        uint128 assetOutIndex;
        uint256 amount;
    }

    struct FundManagement {
        address sender;
        address payable recipient;
        bool toInternalBalance;
        bool fromInternalBalance;
    }

    struct Fee {
        uint128 burnFee;
        uint128 mintFee;
    }

    struct TokenPrice {
        uint256 tokenIn;
        uint256 tokenOut;
    }

    struct Swap {
        IVault.BatchSwapStep[] swap;
        int256[] limits;
        Fee fee;
        TokenPrice price;
        IAsset[] assets;
        bool isBalancerPool;
    }

    struct SwapData {
        IVault.SwapKind kind;
        Swap[] swaps;
        uint256 deadline;
        IVault.FundManagement funds;
    }

    // enum SwapKind {
    //     GIVEN_IN,
    //     GIVEN_OUT
    // }

    IPool public pool;

    IVault private constant vault =
        IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    // IERC20X private constant pool = IERC20X(interfaceAddress);

    function swap(SwapData memory swapDatas) external  returns (uint256) {
        uint amount;
        if (swapDatas.kind == IVault.SwapKind.GIVEN_IN) {
            amount = _swapGivenIn(swapDatas); // amountOut;
        } else if (swapDatas.kind == IVault.SwapKind.GIVEN_OUT) {
            amount = _swapGivenOut(swapDatas);
        }
        return amount;
    }

    function _swapGivenIn(
        SwapData memory swapDatas
    ) internal  returns (uint256) {
        uint256 amountOut = swapDatas.swaps[0].swap[0].amount;

        for (uint i = 0; i < swapDatas.swaps.length; i++) {
            if (swapDatas.swaps[i].isBalancerPool == true) {
                // inside balancer function
                swapDatas.swaps[i].swap[0].amount = amountOut;
                int256[] memory res = _swapInBalancer(
                    swapDatas.swaps[i],
                    swapDatas
                );
                uint256[2] memory res1 = _getMinMax(res);
                amountOut = res1[0];
            } else {
                // inside synthex pool
                amountOut = _swapInSynthex(swapDatas.swaps[i]);
            }
        }
        return amountOut;
    }

    function _swapGivenOut(
        SwapData memory swapDatas
    ) internal  returns (uint256) {
        uint256 amountIn = swapDatas.swaps[0].swap[0].amount;

        for (uint i = 0; i < swapDatas.swaps.length; i++) {
            if (swapDatas.swaps[i].isBalancerPool == true) {
                // inside balancer function
                swapDatas.swaps[i].swap[0].amount = amountIn;
                int256[] memory res = _swapInBalancer(
                    swapDatas.swaps[i],
                    swapDatas
                );
                uint256[2] memory res1 = _getMinMax(res);
                amountIn = res1[1];
            } else {
                // inside synthex pool
            }
        }

        return amountIn;
    }

    function _swapInBalancer(
        Swap memory _swap,
        SwapData memory swapDatas
    ) internal returns (int256[] memory) {
        return
            vault.batchSwap(
                swapDatas.kind,
                _swap.swap,
                _swap.assets,
                swapDatas.funds,
                _swap.limits,
                swapDatas.deadline
            );
    }

    function _swapInSynthex(Swap memory _swap) internal returns (uint256) {

            _swap;
        // address assetOutAddress = _swap.assets[_swap.swap[0].assetOutIndex];

        // IPool(_swap.swap[0].pair).swap(_swap.swap[0].amount, assetOutAddress);

        return
            (_swap.price.tokenIn * _swap.swap[0].amount) / _swap.price.tokenOut;
    }

    function _getMinMax(
        int256[] memory res
    ) internal pure returns (uint256[2] memory) {
        int256 max = -2 ** 255;
        int256 min = 2 ** 255 - 1;
        for (uint j = 0; j < res.length; j++) {
            if (res[j] > max) {
                max = res[j];
            }
            if (res[j] < min) {
                min = res[j];
            }
        }
        min = min * -1;
        uint256 min1 = uint256(min);
        uint256 max1 = uint256(max);
        return [min1, max1];
    }
}
