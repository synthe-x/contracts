// SPDX-License-Identifier: BSL-1.1

import "../../synth/ERC20X.sol";

contract ERC20XV2 is ERC20X {
    function version() external pure returns (string memory) {
        return "v2";
    }
}