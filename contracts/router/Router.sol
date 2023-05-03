// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import {IVault} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@balancer-labs/v2-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../pool/IPool.sol";
import "../libraries/DataTypes.sol";
import "hardhat/console.sol";

// TODO: Extend Multicall, Permit
contract Router is ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;

    IWETH _weth;
    address private constant _ETH = address(0);
    IVault vault;

    struct Swap {
        IVault.BatchSwapStep[] swap;
        int256[] limits;
        IAsset[] assets;
        bool isBalancerPool;
    }

    struct SwapData {
        IVault.SwapKind kind;
        Swap[] swaps;
        IVault.FundManagement funds;
        uint256 deadline;
    }

    struct Approval {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Initialize                                */
    /* -------------------------------------------------------------------------- */
    constructor(IWETH weth, address _vault) {
        _weth = weth;
        vault = IVault(_vault);
    }

    function swap(
        SwapData memory swapDatas
    ) public nonReentrant returns (uint256) {
        
        require(swapDatas.kind == IVault.SwapKind.GIVEN_IN, "SWAP_KIND_GIVEN_IN_ONLY_ALLOWED");

        // if (swapDatas.kind == IVault.SwapKind.GIVEN_IN) {
            return _swapGivenIn(swapDatas); // amountOut;
        // }
        // else if (swapDatas.kind == IVault.SwapKind.GIVEN_OUT) {
        //     return _swapGivenOut(swapDatas);
        // }
        
    }

    function permitRouter(
        uint256 amount,
        uint256 deadline,
        address asset,
        Approval memory approval
    ) public {
        IERC20Permit(asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            approval.v,
            approval.r,
            approval.s
        );
    }

    function _swapGivenIn(
        SwapData memory swapDatas
    ) internal returns (uint256) {
        require(
            swapDatas.funds.fromInternalBalance == false,
            "INVALID_ETH_INTERNAL_BALANCE"
        );
        uint256 amountOut = swapDatas.swaps[0].swap[0].amount;

        address sender = msg.sender; 

        address payable recipient = swapDatas.funds.recipient;
        // change recipient and sender to router contract for swaping stages.
        swapDatas.funds.sender = address(this);

        swapDatas.funds.recipient = payable(address(this));

        for (uint i = 0; i < swapDatas.swaps.length; i++) {
            if (i == 0) {
                IAsset asset = swapDatas.swaps[0].assets[
                    swapDatas.swaps[0].swap[0].assetInIndex
                ];

                _receiveAsset(asset, amountOut, sender);
            }

            if (swapDatas.swaps[i].isBalancerPool == true) {
                // inside balancer function
                swapDatas.swaps[i].swap[0].amount = amountOut;
                IAsset asset = swapDatas.swaps[i].assets[
                    swapDatas.swaps[i].swap[0].assetInIndex
                ];

                IERC20(address(asset)).approve(address(vault), amountOut);

                if (i == swapDatas.swaps.length - 1) {
                    swapDatas.funds.recipient = recipient;
                }
                int256[] memory res = _swapInBalancer(
                    swapDatas.swaps[i],
                    swapDatas
                );
                uint256[2] memory res1 = _getMinMax(res);
                amountOut = res1[0];
               
            } else {
                // inside synthex pool
                swapDatas.swaps[i].swap[0].amount = amountOut;

                if (i == swapDatas.swaps.length - 1) {
                    swapDatas.funds.recipient = recipient;
                }
                amountOut = _swapInSynthex(swapDatas.swaps[i], swapDatas);
            }
        }
        return amountOut;
    }

    // function _swapGivenOut(
    //     SwapData memory swapDatas
    // ) internal returns (uint256) {
    //     uint256 amountIn = swapDatas.swaps[0].swap[0].amount;

    //     for (uint i = 0; i < swapDatas.swaps.length; i++) {
    //         if (swapDatas.swaps[i].isBalancerPool == true) {
    //             // inside balancer function
    //             swapDatas.swaps[i].swap[0].amount = amountIn;
    //             int256[] memory res = _swapInBalancer(
    //                 swapDatas.swaps[i],
    //                 swapDatas
    //             );
    //             uint256[2] memory res1 = _getMinMax(res);
    //             amountIn = res1[1];
    //         } else {
    //             // inside synthex pool
    //         }
    //     }

    //     return amountIn;
    // }

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

    function _swapInSynthex(
        Swap memory _swap,
        SwapData memory swapDatas
    ) internal returns (uint256) {
        address _synthOut = address(_swap.assets[_swap.swap[0].assetOutIndex]);

        address _synthIn = address(_swap.assets[_swap.swap[0].assetInIndex]);

        uint _amount = uint(_swap.swap[0].amount);

        DataTypes.SwapKind kind = swapDatas.kind == IVault.SwapKind.GIVEN_IN
            ? DataTypes.SwapKind.GIVEN_IN
            : DataTypes.SwapKind.GIVEN_OUT;

        address poolAddress = bytes32ToAddress(_swap.swap[0].poolId);

        uint256[2] memory res = IPool(poolAddress).swap(
            _synthIn,
            _amount,
            _synthOut,
            kind,
            swapDatas.funds.recipient
        );

        if (swapDatas.kind == IVault.SwapKind.GIVEN_IN) {
            return res[1];
        }
        return res[0];
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

    function _WETH() internal view returns (IWETH) {
        return _weth;
    }

    /**
     * @dev Returns true if `asset` is the sentinel value that represents ETH.
     */
    function _isETH(IAsset asset) internal pure returns (bool) {
        return address(asset) == _ETH;
    }

    /**
     * @dev Interprets `asset` as an IERC20 token. This function should only be called on `asset` if `_isETH` previously
     * returned false for it, that is, if `asset` is guaranteed not to be the ETH sentinel value.
     */
    function _asIERC20(IAsset asset) internal pure returns (IERC20) {
        return IERC20(address(asset));
    }

    /**
     * @dev Receives `amount` of `asset` from `sender`. If `fromInternalBalance` is true, it first withdraws as much
     * as possible from Internal Balance, then transfers any remaining amount.
     *
     * If `asset` is ETH, `fromInternalBalance` must be false (as ETH cannot be held as internal balance), and the funds
     * will be wrapped into WETH.
     *
     * WARNING: this function does not check that the contract caller has actually supplied any ETH - it is up to the
     * caller of this function to check that this is true to prevent the Vault from using its own ETH (though the Vault
     * typically doesn't hold any).
     */
    function _receiveAsset(
        IAsset asset,
        uint256 amount,
        address sender
    ) internal {
        if (amount == 0) {
            return;
        }

        if (_isETH(asset)) {
            // The ETH amount to receive is deposited into the WETH contract, which will in turn mint WETH for
            // the Vault at a 1:1 ratio.

            // A check for this condition is also introduced by the compiler, but this one provides a revert reason.
            // Note we're checking for the Vault's total balance, *not* ETH sent in this transaction.
            _require(address(this).balance >= amount, Errors.INSUFFICIENT_ETH);
            _WETH().deposit{value: amount}();
        } else {
            IERC20 token = _asIERC20(asset);
            if (amount > 0) {
                token.safeTransferFrom(sender, address(this), amount);
            }
        }
    }

    /**
     * @dev Sends `amount` of `asset` to `recipient`. If `toInternalBalance` is true, the asset is deposited as Internal
     * Balance instead of being transferred.
     *
     * If `asset` is ETH, `toInternalBalance` must be false (as ETH cannot be held as internal balance), and the funds
     * are instead sent directly after unwrapping WETH.
     */
    function _sendAsset(
        IAsset asset,
        uint256 amount,
        address payable recipient
    ) internal {
        if (amount == 0) {
            return;
        }

        if (_isETH(asset)) {
            // First, the Vault withdraws deposited ETH from the WETH contract, by burning the same amount of WETH
            // from the Vault. This receipt will be handled by the Vault's `receive`.
            _WETH().withdraw(amount);

            // Then, the withdrawn ETH is sent to the recipient.
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Errors.ETH_TRANSFER_FAILED");
        } else {
            IERC20 token = _asIERC20(asset);
            token.safeTransfer(recipient, amount);
        }
    }

    /**
     * @dev Enables the Vault to receive ETH. This is required for it to be able to unwrap WETH, which sends ETH to the
     * caller.
     *
     * Any ETH sent to the Vault outside of the WETH unwrapping mechanism would be forever locked inside the Vault, so
     * we prevent that from happening. Other mechanisms used to send ETH to the Vault (such as being the recipient of an
     * ETH swap, Pool exit or withdrawal, contract self-destruction, or receiving the block mining reward) will result
     * in locked funds, but are not otherwise a security or soundness issue. This check only exists as an attempt to
     * prevent user error.
     */
    receive() external payable {
        _require(msg.sender == address(_WETH()), Errors.ETH_TRANSFER);
    }

    function bytes32ToAddress(bytes32 poolId) public pure returns (address) {
        return address(uint160(uint256(poolId)));
    }
}
