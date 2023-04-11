// SPDX-License-Identifier: BSL-1.1

import "../../pool/Pool.sol";

contract PoolV2 is Pool {
    function version() external pure returns (string memory) {
        return "v2";
    }
}