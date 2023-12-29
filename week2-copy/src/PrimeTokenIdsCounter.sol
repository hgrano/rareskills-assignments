// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title PrimeTokenIdsCounter
/// @author Huw Grano
/// @notice Token which can calculate how many NFTs an address owns which are prime numbers
contract PrimeTokenIdsCounter {
    /// @notice Count how many token IDs the address owns which are prime numbers where 1 and 2 are considered prime
    // numbers
    /// @param nft The NFT contract to calculate balance for which must implement IERC721Enumerable
    /// @param owner The address whose balance we want to check
    function primeTokenBalanceOf(address nft, address owner) external returns (uint256) {
        uint256 balance = IERC721Enumerable(nft).balanceOf(owner);
        uint256 tokenId;
        unchecked {
            uint256 primesCount = balance;
            for (uint256 i = 0; i < balance; ++i) {
                tokenId = IERC721Enumerable(nft).tokenOfOwnerByIndex(owner, i);
                for (uint256 divisor = 2; divisor < tokenId; ++divisor) {
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
