// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {NFTWithMerkleDiscount} from "../src/NFTWithMerkleDiscount.sol";
import {RewardDistributor} from "../src/RewardDistributor.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract NFTWithMerkleDiscountTest is Test {
    NFTWithMerkleDiscount nft;
    RewardToken rewardToken;
    RewardDistributor rewardDistributor;
    address owner = address(1);
    address to0 = address(2);
    address to1 = address(3);
    address to2 = address(4);
    address to3 = address(5);

    function setUp() public {
        nft = new NFTWithMerkleDiscount("name", "symbol", owner, 0);
        rewardToken = new RewardToken("name", "symbol", msg.sender);
        rewardDistributor = new RewardDistributor(address(nft), address(rewardToken));
        rewardToken.setMinter(rewardDistributor);
    }

    function test_canClaimAfter24Hours() {
        
    }
}