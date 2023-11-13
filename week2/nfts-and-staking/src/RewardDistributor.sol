// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {RewardToken} from "./RewardToken.sol";

contract RewardDistributor is IERC721Receiver {
    struct StakeInfo {
        address owner;
        uint256 lastCheckpoint;
    }

    mapping(uint256 => StakeInfo) private stakes;
    IERC721 private nft;
    RewardToken private rewardToken;

    constructor(address nft_, address rewardToken_) {
        nft = IERC721(nft_);
        rewardToken = RewardToken(rewardToken_);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        require(msg.sender == address(nft), "RewardDistributor: can only receive NFTs from the expected contract");
        stakes[tokenId] = StakeInfo(from, block.timestamp);
        return IERC721Receiver.onERC721Received.selector;
    }

    function claimRewards(uint256 tokenId) external {
        StakeInfo memory stake = stakes[tokenId];
        uint256 elapsed = block.timestamp - stake.lastCheckpoint;
        uint256 numDays = elapsed / (1 days);
        uint256 nextCheckPoint = block.timestamp - (elapsed % (1 days));
        stakes[tokenId].lastCheckpoint = nextCheckPoint;
        rewardToken.mint(stake.owner, numDays * 10);
    }

    function withdraw(uint256 tokenId) external {
        require(stakes[tokenId].owner == msg.sender, "RewardDistributor: only the owner can withdraw");
        delete stakes[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }
}
