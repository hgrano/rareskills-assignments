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
        pair = new Pair(address(token0), address(token1));
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

    function test_addLiquidityUnderMinimumAmounts() public {
        pair.addLiquidity(5 ether, 20 ether, 0, 0, address(this));

        vm.expectRevert(Pair.AddLiquidityDoesNotMeetMinimumAmount0.selector);
        pair.addLiquidity(1 ether, 4 ether - 1, 1 ether, 0, address(this));

        vm.expectRevert(Pair.AddLiquidityDoesNotMeetMinimumAmount1.selector);
        pair.addLiquidity(1 ether - 1, 4 ether, 0, 4 ether - 3, address(this));
    }

    function test_addLiquidityOverMinimumAmount0() public {
        pair.addLiquidity(5 ether, 20 ether, 0, 0, address(this));

        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));
        pair.addLiquidity(1 ether, 4 ether - 1, 1 ether - 1, 0, address(this));
        assertEq(
            token0.balanceOf(address(this)),
            initialToken0Balance - (1 ether - 1),
            "Must have expected decrease in LP's token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            initialToken1Balance - (4 ether - 1),
            "Must have expected decrease in LP's token1 balance"
        );
    }

    function test_addLiquidityOverMinimumAmount1() public {
        pair.addLiquidity(5 ether, 20 ether, 0, 0, address(this));

        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));
        pair.addLiquidity(1 ether - 1, 4 ether, 0, 4 ether - 4, address(this));
        assertEq(
            token0.balanceOf(address(this)),
            initialToken0Balance - (1 ether - 1),
            "Must have expected decrease in LP's token0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            initialToken1Balance - (4 ether - 4),
            "Must have expected decrease in LP's token1 balance"
        );
    }

    function test_removeLiquidity() public {
        uint256 token0In = 5 ether;
        uint256 token1In = 20 ether;
        pair.addLiquidity(token0In, token1In, 0, 0, address(this));
        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));
        pair.removeLiquidity(2 ether, 0, 0, address(this));
        assertEq(pair.balanceOf(address(this)), 8 ether - 1000, "Must have expected reduction in LP's balance");
        assertEq(
            token0.balanceOf(address(this)),
            initialToken0Balance + 1 ether,
            "Must have expected increase in LP's token 0 balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            initialToken1Balance + 4 ether,
            "Must have expected increase in LP's token 1 balance"
        );
    }

    function test_removeLiquidityUnderMinimumAmounts() public {
        pair.addLiquidity(5 ether, 20 ether, 0, 0, address(this));

        vm.expectRevert(Pair.RemoveLiquidityDoesNotMeetMinimum0Out.selector);
        pair.removeLiquidity(2 ether, 1 ether + 1, 0, address(this));

        vm.expectRevert(Pair.RemoveLiquidityDoesNotMeetMinimum1Out.selector);
        pair.removeLiquidity(2 ether, 0, 4 ether + 1, address(this));
    }

    function test_swap() public {
        pair.addLiquidity(50 ether, 200 ether, 0, 0, address(this));
        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));
        pair.swapExactTokenForToken(false, 1 ether, 0, address(this));
        uint256 expectedToken0BalanceAfterFirstSwap = initialToken0Balance - 1 ether;
        uint256 expectedToken1BalanceAfterFirstSwap = initialToken1Balance + 3910033923564131223;
        assertEq(
            token0.balanceOf(address(this)),
            expectedToken0BalanceAfterFirstSwap,
            "Must have expected reduction in token 0 balance after first swap"
        );
        assertEq(
            token1.balanceOf(address(this)),
            expectedToken1BalanceAfterFirstSwap,
            "Must have expected increase in token 1 balance after first swap"
        );

        pair.swapExactTokenForToken(true, 1 ether, 0, address(this));
        assertEq(
            token0.balanceOf(address(this)),
            expectedToken0BalanceAfterFirstSwap + 257992707545561908,
            "Must have expected increase in token 0 balance after second swap"
        );
        assertEq(
            token1.balanceOf(address(this)),
            expectedToken1BalanceAfterFirstSwap - 1 ether,
            "Must have expected decrease in token 1 balance after second swap"
        );
    }

    function test_swapUnderMinimumAmounts() public {
        pair.addLiquidity(50 ether, 200 ether, 0, 0, address(this));

        vm.expectRevert(Pair.SwapDoesNotMeetMinimumOut.selector);
        pair.swapExactTokenForToken(false, 1 ether, 3910033923564131224, address(this));

        vm.expectRevert(Pair.SwapDoesNotMeetMinimumOut.selector);
        pair.swapExactTokenForToken(true, 20 ether, 4533054469400745658, address(this));
    }
}
