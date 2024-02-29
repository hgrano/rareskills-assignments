// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenDistributor} from "../src/TokenDistributor.sol";

abstract contract TokenDistributorTest is Test {
    TokenDistributor public tokenDistributor;

    function createTokenDistributor(
        address _looksRareToken,
        address _tokenSplitter,
        uint256 _startBlock,
        uint256[] memory _rewardsPerBlockForStaking,
        uint256[] memory _rewardsPerBlockForOthers,
        uint256[] memory _periodLengthesInBlocks,
        uint256 _numberPeriods
    ) public virtual returns (TokenDistributor);

    function setUp() public {
        // tokenDistributor = createTokenDistributor();
    }

    function testIncrement() public {
        
    }
}
