// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TokenVestingTest} from "./TokenVesting.t.sol";
import {OptimizedTokenVesting} from "../src/OptimizedTokenVesting.sol";
import {ITokenVesting} from "../src/ITokenVesting.sol";

contract OptimizedTokenVestingTest is TokenVestingTest {
    function createTokenVesting(
        address beneficiary_,
        uint256 start_,
        uint256 cliffDuration_,
        uint256 duration_,
        bool revocable_
    ) public override returns (ITokenVesting) {
        return new OptimizedTokenVesting(beneficiary_, start_, cliffDuration_, duration_, revocable_);
    }
}
