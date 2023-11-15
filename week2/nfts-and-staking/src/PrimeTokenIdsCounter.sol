// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract PrimeTokenIdsCounter {
    function primeTokenBalanceOf(address nft, address owner) external returns (uint256) {
        uint256 balance = IERC721Enumerable(nft).balanceOf(owner);
        uint256 tokenId;
        unchecked {
            uint256 primesCount = balance;
            for (uint256 i = 0; i < balance; ++i) {
                tokenId = IERC721Enumerable(nft).tokenOfOwnerByIndex(owner, i);
                for (uint256 divisor = 2; divisor < tokenId; ++divisor) { // We assume 1 and 2 are considered prime
                    if (tokenId % divisor == 0) {
                        --primesCount;
                        break;
                    }
                }
            }
            return primesCount;
        }
    }
}
