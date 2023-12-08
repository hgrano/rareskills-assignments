// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";
import {Pair} from "./Pair.sol";

contract Factory {
    using SafeERC20 for IERC20;

    error InvalidTokenOrder();
    error ZeroTokenAddress();
    error PairAlreadyExists();

    mapping(address => mapping(address => address)) private _pairs;

    function createPair(address token0, address token1) external returns (address) {
        if (token0 > token1) {
            revert InvalidTokenOrder();
        }
        if (token0 == address(0)) {
            revert ZeroTokenAddress();
        }
        if (_pairs[token0][token1] != address(0)) {
            revert PairAlreadyExists();
        }
        address pair = address(new Pair{salt: keccak256(abi.encodePacked(token0, token1))}(token0, token1));
        _pairs[token0][token1] = pair;
        return pair;
    }

    function getPair(address token0, address token1) external view returns (address) {
        return _pairs[token0][token1];
    }
}
