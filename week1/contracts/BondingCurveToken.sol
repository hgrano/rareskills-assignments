// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Bonding Curve Token
/// @author Huw Grano
/// @notice Fungible token with price increasing in relation to total supply, where price = m * s + c, for the constants
/// m, c and current total supply s.
contract BondingCurveToken is ERC20 {
    uint256 private m;
    uint256 private c;

    event TokenPurchase(address indexed buyer, uint256 quantity, uint256 cost);
    event TokenSale(address indexed seller, uint256 quantity, uint256 proceeds);

    /// @param name Descriptive name for this token
    /// @param symbol ERC20 symbol for this token
    /// @param _m The slope constant
    /// @param _c The offset constant
    constructor(
        string memory name,
        string memory symbol,
        uint256 _m,
        uint256 _c
    ) ERC20(name, symbol) {
        m = _m;
        c = _c;
    }

    /// @notice Purchase the specified quantity of tokens. If the amount of Ether sent is more than required for this
    /// quantity then a refund is issued to the sender
    /// @dev emits a TokenPurchase event
    /// @dev reverts if the msg.value is not enough to buy the requested number of tokens
    /// @param quantity The quantity of tokens to buy
    function buy(uint256 quantity) external payable {
        uint256 mq = m * quantity;
        uint256 mq2_over2 = (mq * quantity) >> 1;
        uint256 cost = totalSupply() * mq + mq2_over2 + c * quantity;
        require(msg.value >= cost, "BondingCurveToken: Insufficient funds");
        uint256 leftOver;
        unchecked {
            leftOver = msg.value - cost;
        }
        _mint(msg.sender, quantity);
        if (leftOver > 0) {
            (bool sent,) = msg.sender.call{value: leftOver}("");
            require(sent, "BondingCurveToken: Failed to send refund");
        }
        emit TokenPurchase(msg.sender, quantity, cost);
    }

    /// @notice Sell a given quantity of tokens with a floor price
    /// @dev emits a TokenSale event
    /// @dev reverts if the proceeds of sale are less than the `minProceeds`
    /// @param quantity The quantity of tokens to sell
    /// @param minProceeds The minimum required proceeds of the sale
    function sell(uint256 quantity, uint256 minProceeds) external {
        uint256 mq = m * quantity;
        uint256 mq2_over2 = (mq * quantity) >> 1;
        uint256 proceeds = totalSupply() * mq - mq2_over2 + c * quantity;
        require(proceeds >= minProceeds, "BondingCurveToken: Must meet minimum allowed proceeds");
        _burn(msg.sender, quantity);
        (bool sent,) = msg.sender.call{value: proceeds}("");
        require(sent, "BondingCurveToken: Failed to send proceeds");
        emit TokenSale(msg.sender, quantity, proceeds);
    }
}
