// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { MerkleProof } from  "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTWithMerkleDiscount is ERC721, Ownable2Step {
    bytes32 private merkleRoot;
    BitsMap.BitMap private mintedBitMap;

    constructor(uint256 _owner, bytes32 _merkleRoot) Ownable(_owner) {
        merkleRoot = _merkleRoot;
    }

    function mintFromMerkleProof(uint256 index, address to, uint256 tokenId, bytes32[] calldata proof) external {
        require(!mintedBitMap.get(index), "NFTWithMerkleDiscount: already minted");
        bytes32 leaf = keccak256(abi.encodePacked(index, to, tokenId));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "NFTWithMerkleDiscount: invalid proof");
        mintedBitMap.set(index);
        _safeMint(to, tokenId);
    }
}
