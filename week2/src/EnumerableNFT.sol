// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title EnumerableNFT
/// @author Huw Grano
/// @notice Simple enumerable NFT implementation, where the contract owner can mint tokens
contract EnumerableNFT is ERC721Enumerable, Ownable2Step {
    /// @param name_ Descriptive name for this token
    /// @param symbol_ ERC721 symbol for this token
    /// @param owner_ The administrator of the contract who can mint tokens
    constructor(string memory name_, string memory symbol_, address owner_) Ownable(owner_) ERC721(name_, symbol_) {}

    /// @notice Mint a token as the contract owner
    /// @dev emits a Transfer event
    /// @dev reverts if the msg.sender is not the contract owner
    /// @param to Address to mint to
    /// @param tokenId The token ID to mint
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}
