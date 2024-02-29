// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "./MockERC20.sol";
import {TokenVesting} from "../src/TokenVesting.sol";

contract TokenVestingTest is Test {
    TokenVesting public tokenVesting;
    uint256 public start;
    uint256 public cliffDuration;
    uint256 public duration;
    address public beneficiary = address(1);
    MockERC20 public erc20;

    function setUp() public {
        start = block.timestamp + 1 days;
        cliffDuration = 5 days;
        duration = 7 days;
        tokenVesting = new TokenVesting(
            beneficiary,
            start,
            cliffDuration,
            duration,
            true
        );
        erc20 = new MockERC20(1000 ether, address(this));
    }

    function testReleaseAfterCliffButBeforeEnd() public {
        vm.warp(start + cliffDuration);
        uint256 amount = 10 ether;
        erc20.transfer(address(tokenVesting), amount);
        tokenVesting.release(erc20);
        // Sanity check we are hitting the right code path
        assertEq(erc20.balanceOf(beneficiary), (amount * cliffDuration) / duration);
    }
}
