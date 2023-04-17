// SPDX-License-Identifier: BSL-1.1

import "../../synthex/SyntheX.sol";

contract SyntheXV2 is SyntheX {
    function version() external pure returns (string memory) {
        return "v2";
    }
}