// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import {IVault} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@balancer-labs/v2-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../pool/IPool.sol";
import "../libraries/DataTypes.sol";
import "hardhat/console.sol";

// TODO: Extend Multicall, Permit
contract Router {
    using SafeERC20 for IERC20;

    IWETH private immutable _weth;
    address private constant _ETH = address(0);
    IVault private immutable vault;
   
    struct Swap {
        IVault.BatchSwapStep[] swap;
        int256[] limits;
        IAsset[] assets;
        bool isBalancerPool;
    }

    struct SwapData {
        IVault.SwapKind kind;
        Swap[] swaps;
        uint256 deadline;
        IVault.FundManagement funds;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Initialize                                */
    /* -------------------------------------------------------------------------- */
    constructor(IWETH weth, address _vault) {
        _weth = weth;
        vault = IVault(_vault);
    }

    // Sentinel value used to indicate WETH with wrapping/unwrapping semantics. The zero address is a good choice for
    // multiple reasons: it is cheap to pass as a calldata argument, it is a known invalid token and non-contract, and
    // it is an address Pools cannot register as a token.
    // TODO: Non reentrancy
    function swap(SwapData memory swapDatas) external returns (uint256) {
        uint amount;

        if (swapDatas.kind == IVault.SwapKind.GIVEN_IN) {
            amount = _swapGivenIn(swapDatas); // amountOut;
        }
        // else if (swapDatas.kind == IVault.SwapKind.GIVEN_OUT) {
        //     amount = _swapGivenOut(swapDatas);
        // }
        return amount;
    }

    function _swapGivenIn(
        SwapData memory swapDatas
    ) internal returns (uint256) {
        require(
            swapDatas.funds.fromInternalBalance == false,
            // Errors.INVALID_ETH_INTERNAL_BALANCE
            "INVALID_ETH_INTERNAL_BALANCE"
        );
        uint256 amountOut = swapDatas.swaps[0].swap[0].amount;

        address sender = msg.sender; // swapDatas.funds.sender;

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
                // console.log("asset", address(asset));
                // console.log("amountOut1", amountOut);
                IERC20(address(asset)).approve(address(vault), amountOut);
                // TODO: last -> recipient sender
                int256[] memory res = _swapInBalancer(
                    swapDatas.swaps[i],
                    swapDatas
                );
                uint256[2] memory res1 = _getMinMax(res);
                amountOut = res1[0];
                // console.log("amountOut", amountOut);
            } else {
                // inside synthex pool
                swapDatas.swaps[i].swap[0].amount = amountOut;
                // TODO: last -> recipient sender
                amountOut = _swapInSynthex(swapDatas.swaps[i], swapDatas);
            }

            // if (i == swapDatas.swaps.length - 1) {
            //     IAsset asset = swapDatas
            //         .swaps[swapDatas.swaps.length - 1]
            //         .assets[
            //             swapDatas
            //                 .swaps[swapDatas.swaps.length - 1]
            //                 .swap[
            //                     swapDatas
            //                         .swaps[swapDatas.swaps.length - 1]
            //                         .swap
            //                         .length - 1
            //                 ]
            //                 .assetOutIndex
            //         ];
            //     _sendAsset(asset, amountOut, recipient);
            // }
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
        // console.logBytes32(_swap.swap[0].poolId);
        // console.log(_swap.swap[0].amount);
        // console.logAddress(address(_swap.assets[0]));
        // (address add, IVault.PoolSpecialization spe) = vault.getPool(
        //     _swap.swap[0].poolId
        // );
        // console.log("address", add);
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
        console.logBytes32(_swap.swap[0].poolId);
        // console.log(
        //     "string",
        //     stringToAddress(slice(bytes32ToHexString(_swap.swap[0].poolId)))
        // );
        address poolAddress =  stringToAddress(slice(bytes32ToHexString(_swap.swap[0].poolId))); //(_swap.swap[0].poolId);
        console.log("poolAddress", poolAddress);
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
            (bool success,) = recipient.call{value: amount}("");
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

    function toHexString(uint8 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2);
        str[0] = alphabet[value >> 4];
        str[1] = alphabet[value & 0x0f];
        return string(str);
    }

    function concatenateStrings(
        string memory a,
        string memory b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function bytes32ToHexString(
        bytes32 value
    ) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        assembly {
            mstore(add(bytesArray, 32), value)
        }
        string memory hexString = "0x";
        for (uint i = 0; i < 32; i++) {
            hexString = concatenateStrings(
                hexString,
                toHexString(uint8(bytesArray[i]))
            );
        }
        return hexString;
    }

    function slice(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length >= 42, "String too short");
        bytes memory result = new bytes(42);
        for (uint i = 0; i < 42; i++) {
            result[i] = strBytes[i];
        }
        return string(result);
    }

    function stringToAddress(
        string memory _address
    ) public pure returns (address) {
        // Remove 0x prefix if it exists
        if (
            bytes(_address).length >= 2 &&
            bytes(_address)[0] == "0" &&
            (bytes(_address)[1] == "x" || bytes(_address)[1] == "X")
        ) {
            _address = substring(_address, 2, bytes(_address).length);
        }

        bytes memory _bytes = bytes(_address);
        uint160 _parsedBytes = 0;
        for (uint256 i = 0; i < _bytes.length; i += 2) {
            _parsedBytes = uint160(SafeMath.mul(_parsedBytes, 256));
            uint8 _byteValue = parseByteToUint8(_bytes[i]);
            _byteValue = uint8(SafeMath.mul(_byteValue, 16));
            _byteValue = uint8(
                SafeMath.add(_byteValue, parseByteToUint8(_bytes[i + 1]))
            );
            _parsedBytes = uint160(SafeMath.add(_parsedBytes, _byteValue));
        }
        return address(_parsedBytes);
    }

    function substring(
        string memory _str,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory _strBytes = bytes(_str);
        bytes memory _result = new bytes(_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _result[i - _start] = _strBytes[i];
        }
        return string(_result);
    }

    function parseByteToUint8(bytes1 _byte) internal pure returns (uint8) {
        if (uint8(_byte) >= 48 && uint8(_byte) <= 57) {
            return uint8(_byte) - 48;
        } else if (uint8(_byte) >= 65 && uint8(_byte) <= 70) {
            return uint8(_byte) - 55;
        } else if (uint8(_byte) >= 97 && uint8(_byte) <= 102) {
            return uint8(_byte) - 87;
        } else {
            revert(string(abi.encodePacked("Invalid byte value: ", _byte)));
        }
    }
}

//bytes32(uint256(uint160(addr)) << 96);

//  address(uint160(bytes20(b)))
