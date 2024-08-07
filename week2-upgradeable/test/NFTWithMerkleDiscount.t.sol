// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {NFTWithMerkleDiscount} from "../src/NFTWithMerkleDiscount.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract NFTWithMerkleDiscountTest is Test {
    NFTWithMerkleDiscount nft;
    address owner = address(1);
    address to0 = address(2);
    address to1 = address(3);
    address to2 = address(4);
    address to3 = address(5);

    uint256 tokenId0 = 100;
    uint256 tokenId1 = 101;
    uint256 tokenId2 = 102;
    uint256 tokenId3 = 103;

    bytes32 leaf0 = keccak256(abi.encodePacked(int256(0), to0, tokenId0));
    bytes32 leaf1 = keccak256(abi.encodePacked(int256(1), to1, tokenId1));
    bytes32 leaf2 = keccak256(abi.encodePacked(int256(2), to2, tokenId2));
    bytes32 leaf3 = keccak256(abi.encodePacked(int256(3), to3, tokenId3));
    bytes32 parent0 = hashPair(leaf0, leaf1);
    bytes32 parent1 = hashPair(leaf2, leaf3);
    bytes32 root = hashPair(parent0, parent1);

    function setUp() public {
        address proxy = Upgrades.deployUUPSProxy(
            "NFTWithMerkleDiscount.sol",
            abi.encodeCall(NFTWithMerkleDiscount.initialize, (root, owner))
        );
        nft = NFTWithMerkleDiscount(proxy);
    }

    function test_mintFromValidMerkleProof() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaf1;
        proof[1] = parent1;
        // Gas: 73436
        nft.mintFromMerkleProof(0, to0, tokenId0, proof);
        assertEq(nft.balanceOf(to0), 1);
        assertEq(nft.ownerOf(tokenId0), to0);
    }

    function test_standardMint() public {
        vm.prank(owner);
        // Gas: 49652
        nft.mint(to0, tokenId0);
        assertEq(nft.balanceOf(to0), 1);
        assertEq(nft.ownerOf(tokenId0), to0);
    }

    function test_mintFromInvalidMerkleProof() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaf1;
        proof[1] = parent0;
        vm.expectRevert("NFTWithMerkleDiscount: invalid proof");
        nft.mintFromMerkleProof(0, to0, tokenId0, proof);
    }

    function test_DoubleMint() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaf1;
        proof[1] = parent1;
        nft.mintFromMerkleProof(0, to0, tokenId0, proof);
        vm.expectRevert("NFTWithMerkleDiscount: already minted");
        nft.mintFromMerkleProof(0, to0, tokenId0, proof);
    }

    function test_supportsERC2981() public {
        assertTrue(nft.supportsInterface(0x2a55205a));
        address receiver;
        uint256 royaltyAmount;
        (receiver, royaltyAmount) = nft.royaltyInfo(99, 2000);
        assertEq(receiver, address(nft));
        assertEq(royaltyAmount, 50);
    }

    function test_withdawFunds() public {
        vm.prank(owner);
        nft.withdrawFunds();
    }

    // TODO
    // function test_withdrawFundsWithCallFailure() public {
    //     vm.prank(owner);
    //     nft.transferOwnership(address(this));
    //     nft
    // }

    function hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encodePacked(a, b));
        } else {
            return keccak256(abi.encodePacked(b, a));
        }
    }
}
