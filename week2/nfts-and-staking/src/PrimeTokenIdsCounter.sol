// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract PrimeTokenIdsCounter {
    function primeTokenBalanceOf(address nft, address owner) external returns (uint256) {
        uint256 balance = IERC721Enumerable(nft).balanceOf(owner);
        unchecked {
            uint256 primesCount;
            for (uint256 i = 0; i < balance; i++) {
                if (_isPrime(IERC721Enumerable(nft).tokenOfOwnerByIndex(owner, i))) {
                    primesCount++;
                }
            }
            return primesCount;
        }
    }

    function _isPrime(uint256 number) private pure returns (bool) {
        uint256 divisor = 1;
        do {
            unchecked {
                if (number % divisor == 0) {
                    return false;
                }
                ++divisor;
            }
        } while (divisor < number);

        return true;
    }
}
