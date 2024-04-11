// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(uint256 initialSupply, address recipient) ERC20("MockToken", "MOCK") {
        _mint(recipient, initialSupply);
    }
}
