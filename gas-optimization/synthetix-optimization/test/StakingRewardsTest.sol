// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IStakingRewards} from "../src/interfaces/IStakingRewards.sol";
import {RewardsDistributionRecipient} from "../src/RewardsDistributionRecipient.sol";
import {MockERC20} from "./MockERC20.sol";

abstract contract StakingRewardsTest is Test {
    IStakingRewards public stakingRewards;
    MockERC20 public rewardsToken;
    MockERC20 public stakingToken;

    function createStakingRewards(
        address owner,
        address rewardsDistribution,
        address rewardsToken,
        address stakingToken
    ) public virtual returns (IStakingRewards);

    function setUp() public {
        rewardsToken = new MockERC20(1000 ether, address(this));
        stakingToken = new MockERC20(1000 ether, address(this));
        stakingRewards = createStakingRewards(
            address(this), address(this), address(rewardsToken), address(stakingToken)
        );
        rewardsToken.transfer(address(stakingRewards), 1000 ether);
        stakingToken.approve(address(stakingRewards), type(uint256).max);
        RewardsDistributionRecipient(address(stakingRewards)).notifyRewardAmount(100 ether);
    }

    function testStake1() public {
        stakingRewards.stake(10 ether);
    }

    function testStake2InSameBlock() public {
        stakingRewards.stake(10 ether);
        stakingRewards.stake(10 ether);
    }

    function testStake2InSamePeriod() public {
        stakingRewards.stake(10 ether);
        vm.warp(block.timestamp + 3 days);
        stakingRewards.stake(10 ether);
    }

    function testStake2InDifferentPeriods() public {
        stakingRewards.stake(10 ether);
        vm.warp(block.timestamp + 10 days);
        stakingRewards.stake(10 ether);
    }

    function testWithdrawAll() public {
        stakingRewards.stake(10 ether);
        stakingRewards.withdraw(10 ether);
    }

    function testWithdrawPartial() public {
        stakingRewards.stake(10 ether);
        stakingRewards.withdraw(5 ether);
    }

    function testGetReward() public {
        stakingRewards.stake(10 ether);
        vm.warp(block.timestamp + 10 days);
        stakingRewards.getReward();
    }
}
