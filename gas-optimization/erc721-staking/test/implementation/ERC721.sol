// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Impl is ERC721 {
    constructor() ERC721("MockNFT", "MOCK") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}
