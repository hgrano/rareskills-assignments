// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { MerkleProof } from  "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTWithMerkleDiscount is ERC721, ERC2981, Ownable2Step {
    bytes32 private merkleRoot;
    BitMaps.BitMap private mintedBitMap;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_,
        bytes32 merkleRoot_
    ) Ownable(owner_) ERC721(name_, symbol_) {
        merkleRoot = merkleRoot_;
        _setDefaultRoyalty(address(this), 250);
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function mintFromMerkleProof(uint256 index, address to, uint256 tokenId, bytes32[] calldata proof) external {
        require(!BitMaps.get(mintedBitMap, index), "NFTWithMerkleDiscount: already minted");
        bytes32 leaf = keccak256(abi.encodePacked(index, to, tokenId));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "NFTWithMerkleDiscount: invalid proof");
        BitMaps.set(mintedBitMap, index);
        _safeMint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
