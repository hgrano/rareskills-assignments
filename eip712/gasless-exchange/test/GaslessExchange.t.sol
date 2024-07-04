// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {GaslessExchange} from "../src/GaslessExchange.sol";
import {TestERC20} from "./TestERC20.sol";

contract GaslessExchangeTest is Test {
    GaslessExchange public exchange;
    TestERC20 public baseToken;
    TestERC20 public quoteToken;

    address public alice;
    uint256 public alicePk;

    address public bob;
    uint256 public bobPk;

    function setUp() public {
        baseToken = new TestERC20(10000 ether, address(this));
        quoteToken = new TestERC20(10000 ether, address(this));

        exchange = new GaslessExchange(address(baseToken), address(quoteToken));

        (alice, alicePk) = makeAddrAndKey("alice");
        (bob, bobPk) = makeAddrAndKey("bob");
    }

    function testIncrement() public {
        
    }
}
