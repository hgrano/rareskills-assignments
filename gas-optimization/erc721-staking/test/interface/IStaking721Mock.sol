// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IStaking721} from "../../src/interface/IStaking721.sol";

interface IStaking721Mock is IStaking721 {
    function setStakingCondition(uint256 _timeUnit, uint256 _rewardsPerUnitTime) external;
}
