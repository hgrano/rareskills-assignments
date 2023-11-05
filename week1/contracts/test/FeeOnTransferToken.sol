// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeOnTranserToken is ERC20 {
    uint256 feePercent;
    address owner;

    constructor(uint256 _feePercent) ERC20("FeeOnTransferToken", "FOTT") {
        feePercent = _feePercent;
        owner = msg.sender;
    }

    function mint(address recipient, uint256 amount) public {
        _mint(recipient, amount);
    }

    function _update(address from, address to, uint256 value) override internal {
        uint256 fee = (value * feePercent) / 100;
        ERC20._update(from, to, value - fee);
        ERC20._update(from, owner, fee);
    }
}
