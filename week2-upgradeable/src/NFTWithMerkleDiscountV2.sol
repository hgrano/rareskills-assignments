// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./NFTWithMerkleDiscount.sol";

/// @title NFTWithMerkleDiscount
/// @author Huw Grano
/// @notice NFT which can be minted by addresses in a merkle tree
contract NFTWithMerkleDiscountV2 is NFTWithMerkleDiscount {
    function initializeV2() external reinitializer(2) {}

    function forceTransferFrom(address from, address to, uint256 tokenId) external onlyOwner {
        _transfer(from, to, tokenId);
    }
}
