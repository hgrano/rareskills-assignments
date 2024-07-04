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

    address public alice2;
    uint256 public alicePk;

    address public bob;
    uint256 public bobPk;

    function setUp() public {
        baseToken = new TestERC20(10000 ether, address(this));
        quoteToken = new TestERC20(10000 ether, address(this));

        exchange = new GaslessExchange(address(baseToken), address(quoteToken));
        bytes32 domainTypeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        (,string memory name, string memory version, uint256 chainId, address verifyingContract, bytes32 salt,) = exchange.eip712Domain();
        exchangeDomainSeparator = keccak256(
            abi.encode(
                domainTypeHash,
                name,
                version,
                chainId,
                verifyingContract
            )
        );

        (alice, alicePk) = makeAddrAndKey("alice");
        (bob, bobPk) = makeAddrAndKey("bob");
    }

    function testIncrement() public {
        // exchange.eip712Domain();
    }
}
