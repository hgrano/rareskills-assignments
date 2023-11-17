// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {NFTWithMerkleDiscount} from "../src/NFTWithMerkleDiscount.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract RewardDistributorTest is Test {
    NFTWithMerkleDiscount nft;
    RewardToken rewardToken;
    RewardDistributor rewardDistributor;
    address owner = address(1);
    address to0 = address(2);

    function setUp() public {
        nft = new NFTWithMerkleDiscount("name", "symbol", address(this), 0);
        rewardToken = new RewardToken("name", "symbol", address(this));
        rewardDistributor = new RewardDistributor(address(nft), address(rewardToken));
        rewardToken.setMinter(address(rewardDistributor));

        nft.mint(to0, 0);
    }

    function test_canClaimAfter24Hours() public {
        vm.prank(to0);
        nft.safeTransferFrom(to0, address(rewardDistributor), 0);
        skip(24 hours);
        rewardDistributor.claimRewards(0);
        assertEq(rewardToken.balanceOf(to0), 10, "Must have expected balance after 24 hours");
    }

    function test_cannotClaimBefore24Hours() public {
        vm.prank(to0);
        nft.safeTransferFrom(to0, address(rewardDistributor), 0);
        rewardDistributor.claimRewards(0);
        assertEq(rewardToken.balanceOf(to0), 0, "Must have expected balance before 24 hours have elapsed");
    }

    function test_multipleClaims() public {
        vm.prank(to0);
        nft.safeTransferFrom(to0, address(rewardDistributor), 0);
        skip(24 hours + 12 hours);
        rewardDistributor.claimRewards(0);
        assertEq(rewardToken.balanceOf(to0), 10, "Must have expected balance after a day and a half");
        skip(12 hours);
        rewardDistributor.claimRewards(0);
        assertEq(rewardToken.balanceOf(to0), 20, "Must have expected balance after two days");
        skip(12 hours);
        rewardDistributor.claimRewards(0);
        assertEq(rewardToken.balanceOf(to0), 20, "Must have expected balance after two and a half days");
    }

    function test_canWithdraw() public {
        vm.prank(to0);
        nft.safeTransferFrom(to0, address(rewardDistributor), 0);
        vm.prank(to0);
        rewardDistributor.withdraw(0);
        assertEq(nft.ownerOf(0), to0, "Must return the nft to the original owner");
        vm.expectRevert("RewardDistributor: token is not staked");
        vm.prank(to0);
        rewardDistributor.claimRewards(0);
    }
}
