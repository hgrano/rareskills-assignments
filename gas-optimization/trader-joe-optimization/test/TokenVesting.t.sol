// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {MockERC20} from "./MockERC20.sol";
import {ITokenVesting} from "../src/ITokenVesting.sol";

abstract contract TokenVestingTest is Test {
    ITokenVesting public tokenVesting;
    uint256 public start;
    uint256 public cliffDuration;
    uint256 public duration;
    address public beneficiary = address(1);
    MockERC20 public erc20;

    function createTokenVesting(
        address beneficiary_,
        uint256 start_,
        uint256 cliffDuration_,
        uint256 duration_,
        bool revocable_
    ) public virtual returns (ITokenVesting);

    function setUp() public {
        start = block.timestamp + 1 days;
        cliffDuration = 5 days;
        duration = 7 days;
        tokenVesting = createTokenVesting(
            beneficiary,
            start,
            cliffDuration,
            duration,
            true
        );
        erc20 = new MockERC20(1000 ether, address(this));
    }

    function testReleaseAfterCliffButBeforeEnd1x() public {
        vm.warp(start + cliffDuration);
        uint256 amount = 10 ether;
        erc20.transfer(address(tokenVesting), amount);
        tokenVesting.release(erc20);
        // Sanity check we are hitting the right code path
        assertEq(erc20.balanceOf(beneficiary), (amount * cliffDuration) / duration);
    }

    function testReleaseAfterCliffButBeforeEnd2x() public {
        vm.warp(start + cliffDuration);
        uint256 amount = 10 ether;
        erc20.transfer(address(tokenVesting), amount);
        vm.pauseGasMetering();
        tokenVesting.release(erc20); // released amount from zero to non-zero
        vm.resumeGasMetering();

        // Sanity check we are hitting the right code paths
        uint256 expectedInitialRelease = (amount * cliffDuration) / duration;
        assertEq(erc20.balanceOf(beneficiary), expectedInitialRelease);

        vm.warp(start + cliffDuration + 1 days);
        tokenVesting.release(erc20); // released amount from non-zero to non-zero

        // Sanity check
        assertEq(erc20.balanceOf(beneficiary), expectedInitialRelease + (amount * 1 days) / duration);
    }

    function testReleaseAfterEnd1x() public {
        vm.warp(start + duration);
        uint256 amount = 10 ether;
        erc20.transfer(address(tokenVesting), amount);
        tokenVesting.release(erc20);
        // Sanity check we are hitting the right code path
        assertEq(erc20.balanceOf(beneficiary), amount);
    }

    function testReleaseAfterEnd2x() public {
        vm.warp(start + cliffDuration);
        uint256 amount = 10 ether;
        erc20.transfer(address(tokenVesting), amount / 2);
        vm.pauseGasMetering();
        tokenVesting.release(erc20);
        vm.resumeGasMetering();

        vm.warp(start + duration);
        erc20.transfer(address(tokenVesting), amount / 2);
        tokenVesting.release(erc20);
        // Sanity check we are hitting the right code path
        assertEq(erc20.balanceOf(beneficiary), amount);
    }
}
