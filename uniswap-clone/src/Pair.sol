// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";

contract Pair is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error SwapDoesNotMeetMinimumOut();
    error InsufficientBalanceToRemoveLiquidity();
    error RemoveLiquidityDoesNotMeetMinimum0Out();
    error RemoveLiquidityDoesNotMeetMinimum1Out();
    error AddLiquidityDoesNotMeetMinimumAmount0();
    error AddLiquidityDoesNotMeetMinimumAmount1();
    error OverflowReserves();

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    uint256 public constant MIN_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    string private _name;
    string private _symbol;

    uint112 private _reserve0;
    uint112 private _reserve1;
    uint32 private blockTimestampLast;

    uint256 private constant DECIMAL_MULTIPLIER = 1000;
    uint256 private constant FEE_MULTIPLIER = 997;

    uint256 private constant MAX_UINT_112 = 2 ** 112 - 1;

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    constructor(string memory name_, string memory symbol_, address token0_, address token1_) {
        _name = name_;
        _symbol = symbol_;
        token0 = token0_;
        token1 = token1_;
    }

    function addLiquidity(
        uint256 amount0Approved,
        uint256 amount1Approved,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant {
        uint256 totalSupply_ = totalSupply();
        address token0_ = token0;
        address token1_ = token1;

        if (totalSupply_ == 0) {
            _mint(to, FixedPointMathLib.sqrt(amount0Approved * amount1Approved) - MIN_LIQUIDITY);
            _mint(address(0), MIN_LIQUIDITY);
            emit Mint(msg.sender, amount0Approved, amount1Approved);
            IERC20(token0_).safeTransferFrom(msg.sender, address(this), amount0Approved);
            IERC20(token1_).safeTransferFrom(msg.sender, address(this), amount1Approved);
            _updateReserves(IERC20(token0_).balanceOf(address(this)), IERC20(token1_).balanceOf(address(this)), 0, 0);
            return;
        }

        uint112 reserve0_ = _reserve0;
        uint112 reserve1_ = _reserve1;
        uint256 amount1ImpliedByApproval = (reserve1_ * amount0Approved) / reserve0_;
        uint256 amount0ToUse;
        uint256 amount1ToUse;
        if (amount1ImpliedByApproval > amount1Approved) {
            amount0ToUse = (reserve0_ * amount1Approved) / reserve1_;
            if (amount0ToUse < amount0Min) {
                revert AddLiquidityDoesNotMeetMinimumAmount0();
            }
            amount1ToUse = amount1Approved;
        } else {
            amount1ToUse = amount1ImpliedByApproval;
            if (amount1ToUse < amount1Min) {
                revert AddLiquidityDoesNotMeetMinimumAmount1();
            }
            amount0ToUse = amount0Approved;
        }

        uint256 initialBalance0 = IERC20(token0_).balanceOf(address(this));
        IERC20(token0_).safeTransferFrom(msg.sender, address(this), amount0ToUse);
        uint256 actualAmount0 = IERC20(token0_).balanceOf(address(this)) - initialBalance0;

        uint256 initialBalance1 = IERC20(token1_).balanceOf(address(this));
        IERC20(token1_).safeTransferFrom(msg.sender, address(this), amount1ToUse);
        uint256 actualAmount1 = IERC20(token1_).balanceOf(address(this)) - initialBalance1;

        _updateReserves(reserve0_ + actualAmount0, reserve1_ + actualAmount1, reserve0_, reserve1_);
        uint256 liquidity0 = (actualAmount0 * totalSupply_) / reserve0_;
        uint256 liquidity1 = (actualAmount1 * totalSupply_) / reserve1_;
        if (liquidity0 < liquidity1) {
            _mint(to, liquidity0);
        } else {
            _mint(to, liquidity1);
        }

        emit Mint(msg.sender, actualAmount0, actualAmount1);
    }

    function removeLiquidity(uint256 liquidity, uint256 amount0Min, uint256 amount1Min, address to)
        external
        nonReentrant
    {
        uint256 balance = balanceOf(msg.sender);
        if (balance < liquidity) {
            revert InsufficientBalanceToRemoveLiquidity();
        }
        uint256 totalSupply_ = totalSupply();
        address token0_ = token0;
        uint256 amount0 = (liquidity * IERC20(token0_).balanceOf(address(this))) / totalSupply_;
        if (amount0 < amount0Min) {
            revert RemoveLiquidityDoesNotMeetMinimum0Out();
        }
        address token1_ = token1;
        uint256 amount1 = (liquidity * IERC20(token1_).balanceOf(address(this))) / totalSupply_;
        if (amount1 < amount1Min) {
            revert RemoveLiquidityDoesNotMeetMinimum1Out();
        }
        _burn(msg.sender, liquidity);
        uint112 reserve0_ = _reserve0;
        uint112 reserve1_ = _reserve1;
        _updateReserves(reserve0_ - amount0, reserve1_ - amount1, reserve0_, reserve1_);
        IERC20(token0_).transfer(to, amount0);
        IERC20(token1_).transfer(to, amount1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swapExactToken0ForToken1(uint256 amountIn, uint256 amountOutMin, address to) external nonReentrant {
        _swapExactTokenForToken(false, amountIn, amountOutMin, to);
    }

    function swapExactToken1ForToken0(uint256 amountIn, uint256 amountOutMin, address to) external nonReentrant {
        _swapExactTokenForToken(true, amountIn, amountOutMin, to);
    }

    function _swapExactTokenForToken(bool side, uint256 amountIn, uint256 amountOutMin, address to) private {
        address inToken;
        uint112 inReserve;
        address outToken;
        uint112 outReserve;

        if (side) {
            inToken = token1;
            inReserve = _reserve1;
            outToken = token0;
            outReserve = _reserve0;
        } else {
            inToken = token0;
            inReserve = _reserve0;
            outToken = token1;
            outReserve = _reserve1;
        }

        uint256 initialBalanceIn = IERC20(inToken).balanceOf(address(this));
        uint256 initialBalanceOut = IERC20(outToken).balanceOf(address(this));
        IERC20(inToken).safeTransferFrom(msg.sender, address(this), amountIn);
        uint256 finalBalanceIn = IERC20(inToken).balanceOf(address(this));
        uint256 actualAmountIn = finalBalanceIn - initialBalanceIn;
        uint256 actualAmountInSubFee = actualAmountIn * FEE_MULTIPLIER;

        uint256 amountOut =
            (actualAmountInSubFee * outReserve) / (inReserve * DECIMAL_MULTIPLIER + actualAmountInSubFee);
        if (amountOut < amountOutMin) {
            revert SwapDoesNotMeetMinimumOut();
        }
        IERC20(outToken).safeTransfer(to, amountOut);
        uint256 finalBalanceOut = IERC20(outToken).balanceOf(address(this));
        uint256 actualAmountOut = initialBalanceOut - finalBalanceOut;

        if (side) {
            _updateReserves(outReserve - actualAmountOut, inReserve + actualAmountIn, outReserve, inReserve);

            emit Swap(msg.sender, 0, actualAmountIn, amountOut, 0, to);
        } else {
            _updateReserves(inReserve + actualAmountIn, outReserve - actualAmountOut, inReserve, outReserve);

            emit Swap(msg.sender, actualAmountIn, 0, 0, amountOut, to);
        }
    }

    function _updateReserves(uint256 newReserve0, uint256 newReserve1, uint112 currentReserve0, uint112 currentReserve1)
        private
    {
        if (newReserve0 > MAX_UINT_112 || newReserve1 > MAX_UINT_112) {
            revert OverflowReserves();
        }
        uint32 currentBlockTimestamp = uint32(block.timestamp % 2 ** 32);
        unchecked {
            uint32 timeSinceLastUpdate = currentBlockTimestamp - blockTimestampLast;

            if (timeSinceLastUpdate > 0 && currentReserve0 != 0 && currentReserve1 != 0) {
                price0CumulativeLast +=
                    uint256(_asFixedPoint112(currentReserve1) / uint224(currentReserve0)) * timeSinceLastUpdate;
                price1CumulativeLast +=
                    uint256(_asFixedPoint112(currentReserve0) / uint224(currentReserve1)) * timeSinceLastUpdate;
            }
        }
        blockTimestampLast = currentBlockTimestamp;
        _reserve0 = uint112(newReserve0);
        _reserve1 = uint112(newReserve1);
    }

    function _asFixedPoint112(uint112 x) private pure returns (uint224) {
        return uint224(x) << 112;
    }
}
