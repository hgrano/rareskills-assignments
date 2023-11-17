// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {PrimeTokenIdsCounter} from "../src/PrimeTokenIdsCounter.sol";
import {EnumerableNFT} from "../src/EnumerableNFT.sol";

contract PrimeTokenIdsCounterTTest is Test {
    EnumerableNFT nft;
    PrimeTokenIdsCounter counter;

    function setUp() public {
        nft = new EnumerableNFT("name", "symbol", address(this));
        counter = new PrimeTokenIdsCounter();
    }

    function test_returnsPrimes() public {
        address to = address(1);
        nft.mint(to, 1);
        nft.mint(to, 2);
        nft.mint(to, 3);
        nft.mint(to, 4);

        assertEq(counter.primeTokenBalanceOf(address(nft), to), 3);
    }

    function test_returnsZeroForZeroBalance() public {
        assertEq(counter.primeTokenBalanceOf(address(nft), address(1)), 0);
    }

    function test_returnsZeroForZeroPrimes() public {
        address to = address(1);
        nft.mint(to, 4);
        assertEq(counter.primeTokenBalanceOf(address(nft), to), 0);
    }
}
