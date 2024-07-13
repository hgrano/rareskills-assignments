// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FuzzyIdentityChallenge, FuzzyIdentityAttacker} from "../src/FuzzyIdentityChallenge.sol";

contract FuzzyIdentityChallengeTest is Test {
    FuzzyIdentityChallenge public challenge;

    function setUp() public {
        challenge = new FuzzyIdentityChallenge();
    }

    function testAttack() public {
        vm.prank(0x1f2AFBd9C55AB4eb5bBC1c8e8239e7839223CE74);
        FuzzyIdentityAttacker attacker = new FuzzyIdentityAttacker{salt: 0x29ff1868c7ad7af7985b88415fb2b5465dfa02b84c6a319111c7a4393b1eb4d6}();
        console.log("byte code:");
        console.logBytes(type(FuzzyIdentityAttacker).creationCode);
        console.log("attacker address = %s", address(attacker));
        attacker.attack(address(challenge));
        require(challenge.isComplete());
    }
}
