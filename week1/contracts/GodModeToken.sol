// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

// TODO fix version
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract GodModeToken is ERC20, Ownable2Step {
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(initialOwner) {
        _mint(initialOwner, initialSupply);
    }

    function transferFrom(address from, address to, uint256 value) override public returns (bool) {
        if (msg.sender == owner()) {
            _transfer(from, to, value);
            return true;
        } else {
            return ERC20.transferFrom(from, to, value);
        }
    }
}
