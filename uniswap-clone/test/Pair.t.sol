// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {Pair} from "../src/Pair.sol";
import {TestERC20} from "./TestERC20.sol";

contract PairTest is Test {
    Pair pair;
    TestERC20 token0;
    TestERC20 token1;

    function setUp() public {
        token0 = new TestERC20(10_000 ether, address(this));
        token1 = new TestERC20(10_000 ether, address(this));
        pair = new Pair("", "", address(token0), address(token1));
        token0.approve(address(pair), 10_000 ether);
        token1.approve(address(pair), 10_000 ether);
    }

    function test_addInitialLiquidity() public {
        uint256 token0In = 5 ether;
        uint256 token1In = 20 ether;
        pair.addLiquidity(token0In, token1In, 0, 0, address(this));
        assertEq(pair.balanceOf(address(0)), 1000, "Must mint minimum liquidity to the zero address");
        assertEq(pair.balanceOf(address(this)), 10 ether - 1000, "Must mint correct liquidity to the LP");
        assertEq(token0.balanceOf(address(pair)), token0In, "Must transfer token0 tokens to the pair");
        assertEq(token1.balanceOf(address(pair)), token1In, "Must transfer token1 tokens to the pair");
    }

    function test_swap() public {
        pair.addLiquidity(50 ether, 200 ether, 0, 0, address(this));
        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));
        pair.swapExactToken0ForToken1(1 ether, 0, address(this));
        assertEq(
            token0.balanceOf(address(this)),
            initialToken0Balance - 1 ether,
            "Must have expected reduction in token 0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            initialToken1Balance + 3910033923564131223,
            "Must have expected increase in token 1 balance"
        );
    }
}
