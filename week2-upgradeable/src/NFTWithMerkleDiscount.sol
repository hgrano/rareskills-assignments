// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title NFTWithMerkleDiscount
/// @author Huw Grano
/// @notice NFT which can be minted by addresses in a merkle tree
contract NFTWithMerkleDiscount is ERC721Upgradeable, ERC2981Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    bytes32 public merkleRoot;
    BitMaps.BitMap internal mintedBitMap;

    function initialize(bytes32 merkleRoot_, address owner_) initializer public {
        __ERC721_init("MyNFT", "NFT42");
        __ERC2981_init();
        __Ownable_init(owner_);

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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC2981Upgradeable) returns (bool) {
        return ERC721Upgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
