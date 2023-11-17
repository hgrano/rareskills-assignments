// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {RewardToken} from "./RewardToken.sol";

/// @title RewardDistributor
/// @author Huw Grano
/// @notice A contract which allows NFT holders to stake tokens and receive rewards
contract RewardDistributor is IERC721Receiver {
    struct StakeInfo {
        address owner;
        uint256 lastCheckpoint;
    }

    mapping(uint256 => StakeInfo) private stakes;
    IERC721 private nft;
    RewardToken private rewardToken;

    /// @param nft_ The NFT which can be deposited for staking
    /// @param rewardToken_ ERC20 token used to pay rewards
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

    /// @notice Claim rewards owed to the address which staked the token
    /// @param tokenId The token to claim rewards for
    function claimRewards(uint256 tokenId) external {
        StakeInfo memory stake = stakes[tokenId];
        require(stake.owner != address(0), "RewardDistributor: token is not staked");
        unchecked {
            uint256 elapsed = block.timestamp - stake.lastCheckpoint;
            uint256 numDays = elapsed / (1 days);
            uint256 nextCheckPoint = block.timestamp - (elapsed % (1 days));
            stakes[tokenId].lastCheckpoint = nextCheckPoint;
            rewardToken.mint(stake.owner, numDays * 10);
        }
    }

    /// @notice Claim rewards owed to the address whcih of the token
    /// @dev Reverts if the msg.sender is not the staker of the token
    /// @param tokenId The token to withdraw
    function withdraw(uint256 tokenId) external {
        require(stakes[tokenId].owner == msg.sender, "RewardDistributor: only the owner can withdraw");
        delete stakes[tokenId];
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
    }
}
