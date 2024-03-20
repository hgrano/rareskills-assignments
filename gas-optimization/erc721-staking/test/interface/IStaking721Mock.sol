// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IStaking721} from "../../src/interface/IStaking721.sol";

interface IStaking721Mock is IStaking721 {
    function setStakingCondition(uint32 _timeUnit, uint128 _rewardsPerUnitTime) external;
}
