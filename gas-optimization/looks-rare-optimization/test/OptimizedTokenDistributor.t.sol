// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TokenDistributorTest} from "./TokenDistributor.t.sol";
import {OptimizedTokenDistributor} from "../src/OptimizedTokenDistributor.sol";
import {ITokenDistributor} from "../src/interfaces/ITokenDistributor.sol";

contract OptimizedTokenDistributorTest is TokenDistributorTest {
    function createTokenDistributor() public override returns (ITokenDistributor) {
        return new OptimizedTokenDistributor(
            address(looksRareToken),
            tokenSplitter,
            startBlock,
            rewardsPerBlockForStaking,
            rewardsPerBlockForOthers,
            periodLengthesInBlocks,
            numberPeriods
        );
    }
}
