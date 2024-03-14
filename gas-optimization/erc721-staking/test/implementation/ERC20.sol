// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Impl is ERC20 {
    constructor() ERC20("MockERC20", "MOCK") {}

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}
