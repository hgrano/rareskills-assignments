// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import { ERC20 } from "solady/tokens/ERC20.sol";

contract Pair is ERC20 {
    string private _name;
    string private _symbol;

    address public _token0;
    address public _token1;

    uint112 private _reserve0;
    uint112 private _reserve1;

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

    function swap(uint amountIn, uint amoutOutMin) external {
        uint256 initialBalance0 =
    }
}
