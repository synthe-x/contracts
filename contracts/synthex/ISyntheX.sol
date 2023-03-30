// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "../utils/oracle/IPriceOracle.sol";
import "./SyntheXStorage.sol";

abstract contract ISyntheX is SyntheXStorage {

    function claimReward(
        address[] memory _rewardTokens,
        address holder,
        address[] memory _pools
    ) external virtual;

    function getRewardsAccrued(
        address[] memory _rewardTokens,
        address holder,
        address[] memory _pools
    ) external virtual returns (uint256[] memory);

    function distribute(uint256 _totalSupply)
        external 
        virtual;

    function distribute(
        address _account,
        uint256 _totalSupply,
        uint256 _balance
    ) external virtual;

    event SetPoolRewardSpeed(
        address indexed rewardToken,
        address indexed pool,
        uint256 speed
    );
    event DistributedReward(
        address[] rewardTokens,
        address indexed pool,
        address _account,
        uint256[] accountDelta,
        uint256[] rewardIndex
    );
}
