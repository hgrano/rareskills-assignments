// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TokenVestingTest} from "./TokenVesting.t.sol";
import {TokenVesting} from "../src/TokenVesting.sol";
import {ITokenVesting} from "../src/ITokenVesting.sol";

contract DefaultTokenVestingTest is TokenVestingTest {
    function createTokenVesting(
        address beneficiary_,
        uint256 start_,
        uint256 cliffDuration_,
        uint256 duration_,
        bool revocable_
    ) public override returns (ITokenVesting) {
        return new TokenVesting(beneficiary_, start_, cliffDuration_, duration_, revocable_);
    }
}
