// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Test, console2} from "forge-std/Test.sol";
import {IStaking721Mock} from "./interface/IStaking721Mock.sol";
import {ERC721Impl} from "./implementation/ERC721.sol";
import {ERC20Impl} from "./implementation/ERC20.sol";

import "forge-std/console.sol";

abstract contract Staking721Test is Test, IERC721Receiver {
    IStaking721Mock public staking721;
    ERC721Impl public erc721; // Staking token
    ERC20Impl public erc20; // Rewards token
    uint256 initialERC20Balance = 1;

    function createStaking721() public virtual returns (IStaking721Mock);

    function withdrawAll(uint256[] memory tokenIds) public virtual;

    function setUp() public {
        erc721 = new ERC721Impl();
        erc20 = new ERC20Impl();
        staking721 = createStaking721();
        for (uint256 tokenId = 1; tokenId <= 20; tokenId++) {
            erc721.mint(tokenId);
        }
        erc721.setApprovalForAll(address(staking721), true);
        // Set to non-zero so that gas reporting is not affected too much by setting the balance from zero to non-zero
        erc20.mint(address(this), initialERC20Balance);
    }

    function testInitialStake() public {
        staking721.setStakingCondition(1 days, 10 ether);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        staking721.stake(tokenIds);
    }

    function testSecondStakeInSameCondition() public {
        staking721.setStakingCondition(1 days, 10 ether);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.pauseGasMetering();
        staking721.stake(tokenIds);
        vm.resumeGasMetering();
        vm.warp(block.timestamp + 1 days);
        tokenIds[0] = 2;
        staking721.stake(tokenIds);

        // Sanity checking
        vm.warp(block.timestamp + 1 days);
        staking721.claimRewards();
        assertEq(erc20.balanceOf(address(this)) - initialERC20Balance, 30 ether);
    }

    function testSecondStakeInNextCondition() public {
        staking721.setStakingCondition(1 days, 10 ether);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.pauseGasMetering();
        staking721.stake(tokenIds);
        vm.resumeGasMetering();
        vm.warp(block.timestamp + 1 days);
        staking721.setStakingCondition(1 days, 5 ether);
        tokenIds[0] = 2;
        staking721.stake(tokenIds);
        vm.warp(block.timestamp + 1 days);

        // Sanity checking
        staking721.claimRewards();
        assertEq(erc20.balanceOf(address(this)) - initialERC20Balance, 20 ether);
    }

    function testSecondStakersInitialStake() public {
        staking721.setStakingCondition(1 days, 10 ether);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.pauseGasMetering();
        staking721.stake(tokenIds);
        vm.resumeGasMetering();
        vm.startPrank(address(1));
        erc721.setApprovalForAll(address(staking721), true);
        uint256 secondStakersToken = 99;
        erc721.mint(secondStakersToken);
        tokenIds[0] = secondStakersToken;
        staking721.stake(tokenIds);
    }

    function testWithdrawAllTokensInSameCondition() public {
        staking721.setStakingCondition(1 days, 5 ether);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        staking721.stake(tokenIds);
        vm.warp(block.timestamp + 1 days);
        withdrawAll(tokenIds);

        // Sanity checking
        vm.warp(block.timestamp + 1 days);
        staking721.claimRewards();
        assertEq(erc20.balanceOf(address(this)) - initialERC20Balance, 10 ether);
        (uint256[] memory finalTokensStaked,) = staking721.getStakeInfo(address(this));
        assertEq(finalTokensStaked.length, 0);
    }

    function testLargeWithdrawAllTokensInSameCondition() public {
        staking721.setStakingCondition(1 days, 5 ether);
        uint256 numTokens = 20;
        uint256[] memory tokenIds = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            tokenIds[i] = i + 1;
        }
        staking721.stake(tokenIds);
        vm.warp(block.timestamp + 1 days);
        withdrawAll(tokenIds);

        // Sanity checking
        vm.warp(block.timestamp + 1 days);
        staking721.claimRewards();
        assertEq(erc20.balanceOf(address(this)) - initialERC20Balance, numTokens * 5 ether);
        (uint256[] memory finalTokensStaked,) = staking721.getStakeInfo(address(this));
        assertEq(finalTokensStaked.length, 0);
    }

    function testWithdrawPartialTokensInSameCondition() public {
        staking721.setStakingCondition(1 days, 5 ether);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        staking721.stake(tokenIds);
        vm.warp(block.timestamp + 1 days);
        uint256[] memory tokenIdsToWithdraw = new uint256[](1);
        tokenIdsToWithdraw[0] = 1;
        staking721.withdraw(tokenIdsToWithdraw);

        // Sanity checking
        vm.warp(block.timestamp + 1 days);
        staking721.claimRewards();
        assertEq(erc20.balanceOf(address(this)) - initialERC20Balance, 15 ether);
    }

    function testClaimRewardsInSameCondition() public {
        staking721.setStakingCondition(1 days, 10 ether);
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        staking721.stake(tokenIds);
        vm.warp(block.timestamp + 1 days);
        staking721.claimRewards();

        // Sanity checking
        assertEq(erc20.balanceOf(address(this)) - initialERC20Balance, 10 ether);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
