// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract GaslessExchange is EIP712 {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

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

    IERC20 public immutable baseToken;
    IERC20 public immutable quoteToken; // Prices of the base token are measured in units of the quote token

    bytes32 public constant BUY_ORDER_TYPEHASH = keccak256("BuyOrder(address buyer,uint256 expiry,uint256 nonce,uint256 quantity,uint256 price)");
    bytes32 public constant SELL_ORDER_TYPEHASH = keccak256("SellOrder(address seller,uint256 expiry,uint256 nonce,uint256 quantity,uint256 price)");

    uint256 public constant DECIMALS_FACTOR = 10000;

    mapping(bytes32 => OrderStatus) public orders;

    constructor(address baseToken_, address quoteToken_) EIP712("GaslessExchange", "v1") {
        baseToken = IERC20(baseToken_);
        quoteToken = IERC20(quoteToken_);
    }

    function matchOrders(
        BuyOrder memory buyOrder,
        bytes calldata buyerSignature,
        SellOrder memory sellOrder,
        bytes calldata sellerSignature
    ) public {
        require(buyOrder.price >= sellOrder.price, "Orders must have compatible prices");
        require(buyOrder.expiry < block.timestamp, "Buy order cannot have expired");
        require(sellOrder.expiry < block.timestamp, "Sell order cannot have expired");

        bytes32 buyOrderHash = _hashTypedDataV4(hashBuyOrder(buyOrder));
        require(
            buyOrderHash.recover(buyerSignature) == buyOrder.buyer,
            "Buy order must be signed by the buyer"
        );

        bytes32 sellOrderHash = _hashTypedDataV4(hashSellOrder(sellOrder));
        require(
            sellOrderHash.recover(sellerSignature) == sellOrder.seller,
            "Buy order must be signed by the buyer"
        );

        uint256 buyOrderRemaining;
        {
            OrderStatus memory buyOrderStatus = orders[buyOrderHash];
            require(
                buyOrderStatus.ordered == 0 || (buyOrderStatus.cancelled == 0 && buyOrderStatus.remaining > 0),
                "Buy order must not have been cancelled or fully-filled already"
            );

            buyOrderRemaining = buyOrder.quantity;
            if (buyOrderStatus.ordered > 0) {
                buyOrderRemaining = uint256(buyOrderStatus.remaining);
            }
        }
        uint256 sellOrderRemaining;
        {
            OrderStatus memory sellOrderStatus = orders[sellOrderHash];
            require(
                sellOrderStatus.ordered == 0 || (sellOrderStatus.cancelled == 0 && sellOrderStatus.remaining > 0),
                "Sell order must not have been cancelled or fully-filled already"
            );
            sellOrderRemaining = sellOrder.quantity;
            if (sellOrderStatus.ordered > 0) {
                sellOrderRemaining = uint256(sellOrderStatus.remaining);
            }
        }
        uint256 maxBaseToken = Math.min(buyOrderRemaining, sellOrderRemaining);
        uint256 maxQuoteToken = (
            ((buyOrder.price + sellOrder.price) >> 1) * maxBaseToken
        ) / DECIMALS_FACTOR;

        unchecked {
            orders[buyOrderHash].ordered = 1;
            orders[buyOrderHash].remaining = uint248(buyOrderRemaining - maxBaseToken);

            orders[sellOrderHash].ordered = 1;
            orders[sellOrderHash].remaining = uint248(sellOrderRemaining - maxBaseToken);
        }

        quoteToken.safeTransferFrom(buyOrder.buyer, sellOrder.seller, maxQuoteToken);
        baseToken.safeTransferFrom(sellOrder.seller, buyOrder.buyer, maxBaseToken);
    }

    function hashBuyOrder(BuyOrder memory buyOrder) internal pure returns (bytes32) {
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

    function hashSellOrder(SellOrder memory sellOrder) internal pure returns (bytes32) {
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
