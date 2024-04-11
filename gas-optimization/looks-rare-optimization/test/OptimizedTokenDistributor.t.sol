// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TokenDistributorTest} from "./TokenDistributor.t.sol";
import {OptimizedTokenDistributor} from "../src/OptimizedTokenDistributor.sol";
import {ITokenDistributor} from "../src/interfaces/ITokenDistributor.sol";

contract OptimizedTokenDistributorTest is TokenDistributorTest {
    uint112[] public rewardsPerBlockForStaking112;
    uint112[] public rewardsPerBlockForOthers112;
    uint32[] public periodLengthesInBlocks32;

    function createTokenDistributor() public override returns (ITokenDistributor) {
        for (uint i = 0; i < rewardsPerBlockForStaking.length; i++) {
            rewardsPerBlockForStaking112.push(uint112(rewardsPerBlockForStaking[i]));
            rewardsPerBlockForOthers112.push(uint112(rewardsPerBlockForOthers[i]));
            periodLengthesInBlocks32.push(uint32(periodLengthesInBlocks[i]));
        }

        return new OptimizedTokenDistributor(
            address(looksRareToken),
            tokenSplitter,
            uint40(startBlock),
            rewardsPerBlockForStaking112,
            rewardsPerBlockForOthers112,
            periodLengthesInBlocks32,
            uint16(numberPeriods)
        );
    }
}
