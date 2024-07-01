// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {recover} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GaslessExchange {
    struct BuyOrder {
        address buyer;
        uint256 expiry;
        uint256 nonce;
        uint256 quantity;
        uint256 price;
    }

    struct SellOrder {
        address seller;
        uint256 expiry;
        uint256 nonce;
        uint256 quantity;
        uint256 price;
    }

    struct OrderStatus {
        uint8 ordered;
        uint8 cancelled;
        uint248 remaining;
    }

    address public immutable token0;
    address public immutable token1;

    bytes32 public constant BUY_ORDER_TYPEHASH = keccak256("BuyOrder()");
    bytes32 public constant SELL_ORDER_TYPEHASH = keccak256("SellOrder()");

    mapping(bytes32 => OrderStatus) public orders;

    constructor(address token0_, address token1_) {
        token0 = token0_;
        token1 = token1_;
    }

    function matchOrders(
        BuyOrder calldata buyOrder,
        bytes calldata buyerSignature,
        SellOrder calldata sellOrder,
        bytes calldata sellerSignature
    ) public {
        bytes32 buyOrderHash = hash(buyOrder);
        address buyOrderSigner = recover(buyOrderHash, buyerSignature);
        // Firstly we must verify signatures of buyer/seller

        // Then we check to see if there exists a partially filled order or not for the buyer/seller
        // If yes, then we update the existing order accordingly

        // We need to determine final amounts remaining
    }

    function hash(BuyOrder calldata buyOrder) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                SELL_ORDER_TYPEHASH,
                buyOrder.buyer,
                buyOrder.expiry,
                buyOrder.nonce,
                buyOrder.quantity,
                buyOrder.price
            )
        );
    }

    function hash(SellOrder calldata sellOrder) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                SELL_ORDER_TYPEHASH,
                sellOrder.seller,
                sellOrder.expiry,
                sellOrder.nonce,
                sellOrder.quantity,
                sellOrder.price
            )
        );
    }
}
