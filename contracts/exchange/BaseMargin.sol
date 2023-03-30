// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./position/MarginPosition.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "hardhat/console.sol";

abstract contract BaseMargin {
    mapping(address => mapping(uint => address)) public position;
    mapping(address => uint) public totalPositions;

    function createPosition(address[] memory markets) external {
        position[msg.sender][totalPositions[msg.sender]] = Create2.deploy(
                0,
                keccak256(abi.encodePacked(msg.sender)),
                abi.encodePacked(
                    type(MarginPosition).creationCode,
                    abi.encode(msg.sender, address(this), markets)
                )
            );
        totalPositions[msg.sender] += 1;
    }

    function addMarketToPosition(uint positionId, address[] memory markets) external {
        MarginPosition(position[msg.sender][positionId]).supportTokens(markets);
    }
}