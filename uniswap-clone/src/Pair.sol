// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20 } from "solady/tokens/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pair is ERC20 {
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;

    address public _token0;
    address public _token1;

    uint112 private _reserve0;
    uint112 private _reserve1;

    uint256 private constant decimalMultiplier = 1000;
    uint256 private constant multiplerWithFee = 997;

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    constructor(string memory name_, string memory symbol_, address token0_, address token1_) {
        _name = name_;
        _symbol = symbol_;
        _token0 = token0_;
        _token1 = token1_;
    }

    function _swapExactTokenForToken(bool side, uint amountIn, uint amoutOutMin) private {
        address from;
        uint112 fromReserve;
        address to;
        uint112 toReserve;

        if (side) {
            from = _token1;
            fromReserve = _reserve1;
            to = _token0;
            toReserve = _reserve0;
        } else {
            from = _token0;
            fromReserve = _reserve0;
            to = _token1;
            toReserve = _reserve1;
        }

        uint256 initialBalanceFrom = IERC20(from).balanceOf(address(this));
        uint256 initialBalanceTo = IERC20(to).balanceOf(address(this));
        IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 finalBalanceFrom = IERC20(from).balanceOf(address(this));
        uint256 actualAmountIn = finalBalanceFrom - initialBalanceFrom;
        uint256 actualAmountInWithFee = actualAmountIn * multiplerWithFee;

        uint256 amountOut = actualAmountInWithFee * toReserve / (fromReserve * decimalMultiplier + actualAmountInWithFee);
        require(amountOut >= amoutOutMin, "Amount out must meet the slippage threshold");
        IERC20(to).safeTransfer(msg.sender, amountOut);
        uint256 finalBalanceTo = IERC20(to).balanceOf(address(this));
        uint256 actualAmountOut = finalBalanceTo - initialBalanceTo;

        if (side) {
            _reserve1 += uint112(actualAmountIn);
            _reserve0 -= uint112(actualAmountOut);
        } else {
            _reserve0 += uint112(actualAmountIn);
            _reserve1 -= uint112(actualAmountOut);
        }
    }
}
