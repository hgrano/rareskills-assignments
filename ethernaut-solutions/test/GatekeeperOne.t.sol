pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/GatekeeperOne.sol";

contract GatekeeperOneTest is Test {
    GatekeeperOne public gateKeeper;

    function setUp() public {
        gateKeeper = new GatekeeperOne();
    }

    function testEnter() public {
        GatekeeperOneOpener opener = new GatekeeperOneOpener();
        opener.openGate(gateKeeper);
        assertEq(gateKeeper.entrant(), tx.origin);
    }
}