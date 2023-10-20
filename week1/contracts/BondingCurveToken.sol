// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BondingCurveToken is ERC20 {
    uint256 private slope;

    event TokenPurchase(address indexed buyer, uint256 quantity, uint256 cost);
    event TokenSale(address indexed seller, uint256 quantity, uint256 proceeds);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _slope
    ) ERC20(name, symbol) {
        slope = _slope;
    }

    function buy(uint256 quantity) external payable {
        uint256 mq = slope * quantity;
        uint256 msq = totalSupply() * mq;
        uint256 mq2_over2 = (mq * quantity) >> 1;
        uint256 cost = msq + mq2_over2;
        require(msg.value >= cost, "Insufficient funds");
        uint256 leftOver;
        unchecked {
            leftOver = msg.value - cost;
        }
        _mint(msg.sender, quantity);
        if (leftOver > 0) {
            (bool sent,) = msg.sender.call{value: leftOver}("");
            require(sent, "Failed to send refund");
        }
        emit TokenPurchase(msg.sender, quantity, cost);
    }

    function sell(uint256 quantity, uint256 minProceeds) external {
        // TODO gas cost optimization
        uint256 proceeds = slope * (2 * totalSupply() * quantity - quantity * quantity) / 2;
        require(proceeds >= minProceeds, "Must meet minimum allowed proceeds");
        _burn(msg.sender, quantity);
        (bool sent,) = msg.sender.call{value: proceeds}("");
        require(sent, "Failed to send proceeds");
        emit TokenSale(msg.sender, quantity, proceeds);
    }
}
