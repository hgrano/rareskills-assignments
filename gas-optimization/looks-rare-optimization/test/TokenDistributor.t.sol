// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {ITokenDistributor} from "../src/interfaces/ITokenDistributor.sol";
import {LooksRareToken} from "../src/LooksRareToken.sol";

abstract contract TokenDistributorTest is Test {
    ITokenDistributor public tokenDistributor;
    LooksRareToken public looksRareToken;
    address public tokenSplitter;
    uint256 public startBlock;
    uint256[] public rewardsPerBlockForStaking;
    uint256[] public rewardsPerBlockForOthers;
    uint256[] public periodLengthesInBlocks;
    uint256 public numberPeriods;

    function createTokenDistributor() public virtual returns (ITokenDistributor);

    function setUp() public {
        looksRareToken = new LooksRareToken(address(this), 1000 ether, 2000 ether);
        tokenSplitter = address(1);
        startBlock = block.number + 1;
        rewardsPerBlockForStaking.push(200 ether);
        rewardsPerBlockForStaking.push(75 ether);
        rewardsPerBlockForOthers.push(50 ether);
        rewardsPerBlockForOthers.push(50 ether);
        periodLengthesInBlocks.push(2);
        periodLengthesInBlocks.push(4);
        numberPeriods = 2;
        tokenDistributor = createTokenDistributor();
        looksRareToken.transferOwnership(address(tokenDistributor));
        looksRareToken.approve(address(tokenDistributor), type(uint256).max);

        // We setup an initial deposit and roll past the `lastRewardBlock`
        address initialDepositor = address(1);
        looksRareToken.transfer(initialDepositor, 10 ether);

        // Do the initial deposit
        vm.startPrank(initialDepositor);
        looksRareToken.approve(address(tokenDistributor), type(uint256).max);
        vm.roll(startBlock + 1);
        vm.pauseGasMetering();
        tokenDistributor.deposit(10 ether);
        vm.resumeGasMetering();
        vm.stopPrank();

        vm.roll(block.number + 1);
    }

    function testInitialDeposit() public {
        tokenDistributor.deposit(10 ether);
    }

    function testSecondDepositInSamePhase() public {
        vm.pauseGasMetering();
        tokenDistributor.deposit(10 ether);
        vm.resumeGasMetering();
        tokenDistributor.deposit(10 ether);
    }

    function testSecondDepositInNextPhase() public {
        vm.pauseGasMetering();
        tokenDistributor.deposit(10 ether);
        vm.roll(block.number + periodLengthesInBlocks[0] + 1);
        vm.resumeGasMetering();
        tokenDistributor.deposit(10 ether);
    }

    function testHarvestAndCompoundInSameBlock() public {
        tokenDistributor.deposit(10 ether);
        tokenDistributor.harvestAndCompound();
    }

    function testHarvestAndCompoundInSamePhase() public {
        tokenDistributor.deposit(10 ether);
        vm.roll(block.number + 1);
        tokenDistributor.harvestAndCompound();
    }

    function testWithdrawInSamePhase() public {
        tokenDistributor.deposit(10 ether);
        vm.roll(block.number + 1);
        tokenDistributor.withdraw(5 ether);
    }

    function testWithdrawAllInSamePhase() public {
        tokenDistributor.deposit(10 ether);
        vm.roll(block.number + 1);
        tokenDistributor.withdrawAll();
    }
}
