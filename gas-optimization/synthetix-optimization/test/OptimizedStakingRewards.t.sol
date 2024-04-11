// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IStakingRewards} from "../src/interfaces/IStakingRewards.sol";
import {OptimizedStakingRewards} from "../src/OptimizedStakingRewards.sol";
import {MockERC20} from "./MockERC20.sol";
import {StakingRewardsTest} from "./StakingRewardsTest.sol";

contract OptimizedStakingRewardsTest is StakingRewardsTest {
    function createStakingRewards(
        address owner_,
        address rewardsDistribution_,
        address rewardsToken_,
        address stakingToken_
    ) public override returns (IStakingRewards) {
        return new OptimizedStakingRewards(owner_, rewardsDistribution_, rewardsToken_, stakingToken_);
    }
}
