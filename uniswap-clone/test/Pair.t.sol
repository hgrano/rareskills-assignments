// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Pair} from "../src/Pair.sol";
import {TestERC20} from "./TestERC20.sol";

contract PairTest is Test {
    Pair public pair;

    function setUp() public {
        TestERC20 token0 = new TestERC20(1000 ether, address(this));
        TestERC20 token1 = new TestERC20(1000 ether, address(this));
        pair = new Pair("", "", address(token0), address(token1));
        token0.approve(address(pair), 10_000 ether);
        token1.approve(address(pair), 10_000 ether);
    }

    function test_addInitialLiquidity() public {
        pair.addLiquidity(5 ether, 20 ether, 0, 0, address(this));
        assertEq(pair.balanceOf(address(0)), 1000);
        assertEq(pair.balanceOf(address(this)), 10 ether - 1000);
    }
}
