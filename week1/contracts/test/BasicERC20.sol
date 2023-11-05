// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BasicERC20 is ERC20 {
    constructor(uint256 initialSupply, address recipient) ERC20("BasicToken", "TKN") {
        _mint(recipient, initialSupply);
    }
}
