// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {GaslessExchange} from "../src/GaslessExchange.sol";
import {TestERC20} from "./TestERC20.sol";

contract GaslessExchangeTest is Test {
    GaslessExchange public exchange;
    TestERC20 public baseToken;
    TestERC20 public quoteToken;

    bytes32 exchangeDomainSeparator;

    address public alice;
    uint256 public alicePk;
    uint256 public aliceBaseInitialBalance = 5000 ether;
    uint256 public aliceQuoteInitialBalance = 5000 ether;

    address public bob;
    uint256 public bobPk;
    uint256 public bobBaseInitialBalance = 5000 ether;
    uint256 public bobQuoteInitialBalance = 5000 ether;

    uint256 public buy1Expiry = 1720228758;
    bytes32 public buy1Hash = 0x8403727610361155a43f13fde7113d2421014cd3d748485684e0b16a993a50d0;

    uint256 public sell1Expiry = 1722907158;
    bytes32 public sell1Hash = 0x4deded458ddda90d261676dbc108c27213f69af8e1cdabb5079274e8e9c3b61d;

    function setUp() public {
        baseToken = new TestERC20(10000 ether, address(this));
        quoteToken = new TestERC20(10000 ether, address(this));

        exchange = new GaslessExchange(address(baseToken), address(quoteToken), 1 ether);
        bytes32 domainTypeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        (,string memory name, string memory version, uint256 chainId, address verifyingContract,,) = exchange.eip712Domain();
        exchangeDomainSeparator = keccak256(
            abi.encode(
                domainTypeHash,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );

        alicePk = vm.deriveKey("test test test test test test test test test test test junk", 0);
        alice = vm.addr(alicePk);

        bobPk = vm.deriveKey("test test test test test test test test test test test absent", 0);
        bob = vm.addr(bobPk);

        baseToken.transfer(alice, aliceBaseInitialBalance);
        baseToken.transfer(bob, bobBaseInitialBalance);

        quoteToken.transfer(alice, aliceQuoteInitialBalance);
        quoteToken.transfer(bob, bobQuoteInitialBalance);

        vm.startPrank(alice);
        baseToken.approve(address(exchange), type(uint256).max);
        quoteToken.approve(address(exchange), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        baseToken.approve(address(exchange), type(uint256).max);
        quoteToken.approve(address(exchange), type(uint256).max);
        vm.stopPrank();
    }

    function testSimple() public {
        bytes memory aliceSig = sign(alicePk, keccak256(abi.encodePacked("\x19\x01", exchangeDomainSeparator, buy1Hash)));
        bytes memory bobSig = sign(bobPk, keccak256(abi.encodePacked("\x19\x01", exchangeDomainSeparator, sell1Hash)));
        vm.warp(buy1Expiry - 1 hours);

        GaslessExchange.BuyOrder memory buy1 = GaslessExchange.BuyOrder(alice, buy1Expiry, 0, 10 ether, 2 ether + (1 ether) / 100);
        GaslessExchange.SellOrder memory sell1 = GaslessExchange.SellOrder(bob, sell1Expiry, 0, 5 ether, 1 ether + (99 ether) / 100);
        exchange.matchOrders(buy1, aliceSig, sell1, bobSig);

        assertEq(baseToken.balanceOf(alice), aliceBaseInitialBalance + 5 ether);
        assertEq(quoteToken.balanceOf(alice), aliceQuoteInitialBalance - 10 ether);

        assertEq(baseToken.balanceOf(bob), bobBaseInitialBalance - 5 ether);
        assertEq(quoteToken.balanceOf(bob), bobQuoteInitialBalance + 10 ether);
    }

    function sign(uint256 pk, bytes32 data) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, data);
        return abi.encodePacked(r, s, v);
    }
}
