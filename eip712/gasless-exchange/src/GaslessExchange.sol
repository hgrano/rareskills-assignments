// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {console2} from "forge-std/Test.sol";

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
        bool ordered;
        bool cancelled;
        uint248 remaining;
    }

    // TODO events
    // TODO order cancellation

    IERC20 public immutable baseToken;
    IERC20 public immutable quoteToken; // Prices of the base token are measured in units of the quote token

    uint256 public immutable decimalsFactor;

    bytes32 public constant BUY_ORDER_TYPEHASH = keccak256("BuyOrder(address buyer,uint256 expiry,uint256 nonce,uint256 quantity,uint256 price)");
    bytes32 public constant SELL_ORDER_TYPEHASH = keccak256("SellOrder(address seller,uint256 expiry,uint256 nonce,uint256 quantity,uint256 price)");

    mapping(bytes32 => OrderStatus) public orders;

    constructor(address baseToken_, address quoteToken_, uint256 decimalsFactor_) EIP712("GaslessExchange", "v1") {
        baseToken = IERC20(baseToken_);
        quoteToken = IERC20(quoteToken_);
        decimalsFactor = decimalsFactor_;
    }

    function matchOrders(
        BuyOrder memory buyOrder,
        bytes calldata buyerSignature,
        SellOrder memory sellOrder,
        bytes calldata sellerSignature
    ) public {
        require(buyOrder.price >= sellOrder.price, "Orders must have compatible prices");
        require(buyOrder.expiry > block.timestamp, "Buy order cannot have expired");
        require(sellOrder.expiry > block.timestamp, "Sell order cannot have expired");

        bytes32 buyOrderStructHash = hashBuyOrder(buyOrder);
        bytes32 buyOrderHash = _hashTypedDataV4(buyOrderStructHash);

        require(
            buyOrderHash.recover(buyerSignature) == buyOrder.buyer,
            "Buy order must be signed by the buyer"
        );

        bytes32 sellOrderHash = _hashTypedDataV4(hashSellOrder(sellOrder));
        require(
            sellOrderHash.recover(sellerSignature) == sellOrder.seller,
            "Sell order must be signed by the seller"
        );

        uint256 buyOrderRemaining;
        {
            OrderStatus memory buyOrderStatus = orders[buyOrderHash];
            require(
                !buyOrderStatus.ordered || (!buyOrderStatus.cancelled && buyOrderStatus.remaining > 0),
                "Buy order must not have been cancelled or fully-filled already"
            );

            buyOrderRemaining = buyOrder.quantity;
            if (buyOrderStatus.ordered) {
                buyOrderRemaining = uint256(buyOrderStatus.remaining);
            } else {
                require(buyOrder.quantity <= type(uint248).max, "Buy order quantity must not be larger than uint248");
            }
        }
        uint256 sellOrderRemaining;
        {
            OrderStatus memory sellOrderStatus = orders[sellOrderHash];
            require(
                !sellOrderStatus.ordered || (!sellOrderStatus.cancelled && sellOrderStatus.remaining > 0),
                "Sell order must not have been cancelled or fully-filled already"
            );
            sellOrderRemaining = sellOrder.quantity;
            if (sellOrderStatus.ordered) {
                sellOrderRemaining = uint256(sellOrderStatus.remaining);
            } else {
                require(sellOrder.quantity <= type(uint248).max, "Sell order quantity must not be larger than uint248");
            }
        }
        uint256 maxBaseToken = Math.min(buyOrderRemaining, sellOrderRemaining);
        uint256 maxQuoteToken = ((buyOrder.price + sellOrder.price) >> 1) * maxBaseToken;

        unchecked {
            orders[buyOrderHash] = OrderStatus(true, false, uint248(buyOrderRemaining - maxBaseToken));
            orders[sellOrderHash] = OrderStatus(true, false, uint248(sellOrderRemaining - maxBaseToken));
        }

        quoteToken.safeTransferFrom(buyOrder.buyer, sellOrder.seller, maxQuoteToken / decimalsFactor);
        baseToken.safeTransferFrom(sellOrder.seller, buyOrder.buyer, maxBaseToken);
    }

    function hashBuyOrder(BuyOrder memory buyOrder) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                BUY_ORDER_TYPEHASH,
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
