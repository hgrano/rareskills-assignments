// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TokenVesting} from "../src/TokenVesting.sol";

contract TokenVestingTest is Test {
    TokenVesting public tokenVesting;
    uint256 public start;
    uint256 public cliffDuration;
    uint256 public duration;
    address public beneficiary = address(1);

    function setUp() public {
        start = block.timestamp + 1 days;
        cliffDuration = 2 days;
        duration = 7 days;
        tokenVesting = new TokenVesting(
            beneficiary,
            start,
            cliffDuration,
            duration,
            true
        );
    }

    function testIncrement() public {
        
    }
}
