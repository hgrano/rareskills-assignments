// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title NFTWithMerkleDiscount
/// @author Huw Grano
/// @notice NFT which can be minted by addresses in a merkle tree
contract NFTWithMerkleDiscount is ERC721, ERC2981, Ownable2Step {
    bytes32 private merkleRoot;
    BitMaps.BitMap private mintedBitMap;

    /// @param name_ Descriptive name for this token
    /// @param symbol_ ERC721 symbol for this token
    /// @param owner_ The administrator of the contract who can mint tokens
    /// @param merkleRoot_ The markle root which allows other addresses to mint
    constructor(string memory name_, string memory symbol_, address owner_, bytes32 merkleRoot_)
        Ownable(owner_)
        ERC721(name_, symbol_)
    {
        merkleRoot = merkleRoot_;
        _setDefaultRoyalty(address(this), 250);
    }

    /// @notice Mint a token as the contract owner
    /// @dev emits a Transfer event
    /// @dev reverts if the msg.sender is not the contract owner
    /// @param to Address to mint to
    /// @param tokenId The token ID to mint
    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /// @notice Mint a token using merkle proof
    /// @dev emits a Transfer event
    /// @dev reverts if the msg.sender is not the contract owner
    /// @param index Index of the leaf within the merkle tree
    /// @param to Address to mint to
    /// @param tokenId The token ID to mint
    /// @param proof Proof of right to mint this token, encoded as the hash of each sibling node from the leaf to root.
    function mintFromMerkleProof(uint256 index, address to, uint256 tokenId, bytes32[] calldata proof) external {
        require(!BitMaps.get(mintedBitMap, index), "NFTWithMerkleDiscount: already minted");
        bytes32 leaf = keccak256(abi.encodePacked(index, to, tokenId));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "NFTWithMerkleDiscount: invalid proof");
        BitMaps.set(mintedBitMap, index);
        _safeMint(to, tokenId);
    }

    /// @notice Withdraw funds to the contract owner's address
    /// @dev reverts if the msg.sender is not the contract owner
    function withdrawFunds() external onlyOwner {
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "NFTWithMerkleDiscount: Failed to send funds to the owner");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
