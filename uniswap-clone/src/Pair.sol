// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "solady/tokens/ERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
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
    error FlashSwapReceiverFailure();
    error FlashSwapNotPaidBack();
    error FlashSwapExceedsMaxRepayment();

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 shares);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        bool indexed side,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );
    uint256 public constant MIN_LIQUIDITY = 1000;

    string public constant NAME = "Uniswap Pair Token";
    string public constant SYMBOL = "UNI";

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

    bytes32 private constant _FLASHSWAP_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    function name() public view override returns (string memory) {
        return NAME;
    }

    function symbol() public view override returns (string memory) {
        return SYMBOL;
    }

    constructor(address token0_, address token1_) {
        token0 = token0_;
        token1 = token1_;
    }

    /// @notice Add liquidity to the pool by transferring tokens in
    /// @dev emits a Mint event
    /// @param amount0Approved Max amount of token0 the sender is willing to transfer out of their account
    /// @param amount1Approved Max amount of token1 the sender is willing to transfer out of their account
    /// @param amount0Min Min amount of token0 the sender is willing to transfer out of their account
    /// @param amount1Min Min amount of token01the sender is willing to transfer out of their account
    /// @param to Address to mint liquidity tokens to
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
            IERC20(token0_).safeTransferFrom(msg.sender, address(this), amount0Approved);
            IERC20(token1_).safeTransferFrom(msg.sender, address(this), amount1Approved);

            uint256 shares = FixedPointMathLib.sqrt(amount0Approved * amount1Approved) - MIN_LIQUIDITY;
            _mint(to, shares);
            emit Mint(msg.sender, amount0Approved, amount1Approved, shares);
            _mint(address(0), MIN_LIQUIDITY);
            emit Mint(address(0), amount0Approved, amount1Approved, MIN_LIQUIDITY);

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
        uint256 actualAmount0;
        unchecked {
            // Unchecked is safe as the Pair's balance can only increase
            actualAmount0 = IERC20(token0_).balanceOf(address(this)) - initialBalance0;
        }

        uint256 initialBalance1 = IERC20(token1_).balanceOf(address(this));
        IERC20(token1_).safeTransferFrom(msg.sender, address(this), amount1ToUse);

        uint256 actualAmount1;
        unchecked {
            // Unchecked is safe as the Pair's balance can only increase
            actualAmount1 = IERC20(token1_).balanceOf(address(this)) - initialBalance1;
        }

        unchecked {
            // Unchecked as the balance of this contract could not overflow, as otherwise the total supply of token0
            // or token1 would have to overlfow
            _updateReserves(reserve0_ + actualAmount0, reserve1_ + actualAmount1, reserve0_, reserve1_);
        }
        uint256 liquidity0 = (actualAmount0 * totalSupply_) / reserve0_;
        uint256 liquidity1 = (actualAmount1 * totalSupply_) / reserve1_;
        if (liquidity0 < liquidity1) {
            _mint(to, liquidity0);
            emit Mint(msg.sender, actualAmount0, actualAmount1, liquidity0);
        } else {
            _mint(to, liquidity1);
            emit Mint(msg.sender, actualAmount0, actualAmount1, liquidity1);
        }
    }

    /// @notice Remove liquidity from the Pair
    /// @dev emits a Burn event
    /// @dev reverts if the sender does not have sufficient balance
    /// @param liquidity Number of liquidity tokens to withdraw
    /// @param amount0Min Minimum amount of token0 the user is willing to receive
    /// @param amount1Min Minimum amount of token1 the user is willing to receive
    /// @param to Address to receive token0 and token1
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
        IERC20(token0_).transfer(to, amount0);
        IERC20(token1_).transfer(to, amount1);

        uint112 reserve0_ = _reserve0;
        uint112 reserve1_ = _reserve1;

        unchecked {
            // Unchecked is safe as the user can't withdraw more than our reserves
            _updateReserves(reserve0_ - amount0, reserve1_ - amount1, reserve0_, reserve1_);
        }

        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @notice Flash swap one token for the other token: `to` receives the requested amount of tokens first, after
    /// which their callback function will be invoked which must repay the required quantity of the other token.
    /// @dev `to` must implement `IERC3156FlashBorrower`
    /// @dev emits a Swap event
    /// @dev reverts if `to` does not pay back at least the required value of tokens
    /// @param side If true, then the swap is from token1 to token0, otherwise the swap is from token0 to token1
    /// @param amount Amount of tokens to transfer out of the Pair
    /// @param maxRepayment Maximum number of tokens the caller is willing to use to payback the Pair
    /// @param to Address to receive the tokens
    function flashSwap(bool side, uint256 amount, uint256 maxRepayment, address to) external nonReentrant {
        address tokenIn;
        address tokenOut;
        uint112 reserveIn;
        uint112 reserveOut;
        if (side) {
            tokenIn = token1;
            tokenOut = token0;
            reserveIn = _reserve1;
            reserveOut = _reserve0;
        } else {
            tokenIn = token0;
            tokenOut = token1;
            reserveIn = _reserve0;
            reserveOut = _reserve1;
        }

        uint256 initialToBalanceOut = IERC20(tokenOut).balanceOf(to);
        IERC20(tokenOut).safeTransfer(to, amount);
        uint256 actualAmount = initialToBalanceOut - IERC20(tokenOut).balanceOf(to);
        uint256 initialBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 owedIn = (DECIMAL_MULTIPLIER * amount * reserveIn) / (FEE_MULTIPLIER * (reserveOut - amount));
        if (owedIn > maxRepayment) {
            revert FlashSwapExceedsMaxRepayment();
        }
        bytes32 callbackResult =
            IERC3156FlashBorrower(to).onFlashLoan(
                msg.sender,
                tokenOut,
                actualAmount,
                0,
                abi.encodePacked(tokenIn, owedIn) // Tell the flash borrower what token they owe back and how much
            );
        if (callbackResult != _FLASHSWAP_CALLBACK_SUCCESS) {
            revert FlashSwapReceiverFailure();
        }
        uint256 finalBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        unchecked {
            // Unchecked as it is not possible for the Pair's balance to decrease
            if (finalBalanceIn - initialBalanceIn < owedIn) {
                revert FlashSwapNotPaidBack();
            }
        }

        if (side) {
            _updateReserves(IERC20(tokenOut).balanceOf(address(this)), finalBalanceIn, reserveOut, reserveIn);
        } else {
            _updateReserves(finalBalanceIn, IERC20(tokenOut).balanceOf(address(this)), reserveIn, reserveOut);
        }

        // Prevent stack too deep errors by copying variables to memory
        uint256 amount_ = amount;
        emit Swap(msg.sender, side, owedIn, amount_, to);
    }

    /// @notice Swap one token for the other token
    /// @dev emits a Swap event
    /// @dev reverts if sender has not already approved at least `amountIn`
    /// @param side If true, then the swap is from token1 to token0, otherwise the swap is from token0 to token1
    /// @param amountIn Amount of tokens to transfer out of the sender's account
    /// @param amountOutMin Minimum number of tokens the user is willing to receive in return
    /// @param to Address to receive the tokens
    function swapExactTokenForToken(bool side, uint256 amountIn, uint256 amountOutMin, address to)
        external
        nonReentrant
    {
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
        uint256 actualAmountIn;
        unchecked {
            actualAmountIn = finalBalanceIn - initialBalanceIn;
        }
        uint256 actualAmountInSubFee = actualAmountIn * FEE_MULTIPLIER;

        uint256 amountOut =
            (actualAmountInSubFee * outReserve) / (inReserve * DECIMAL_MULTIPLIER + actualAmountInSubFee);
        if (amountOut < amountOutMin) {
            revert SwapDoesNotMeetMinimumOut();
        }
        IERC20(outToken).safeTransfer(to, amountOut);
        uint256 finalBalanceOut = IERC20(outToken).balanceOf(address(this));

        unchecked {
            if (side) {
                _updateReserves(outReserve - amountOut, inReserve + actualAmountIn, outReserve, inReserve);
            } else {
                _updateReserves(inReserve + actualAmountIn, outReserve - amountOut, inReserve, outReserve);
            }
        }

        // Prevent stack too deep errors by copying variables to memory
        bool side_ = side;
        uint256 amountIn_ = amountIn;
        emit Swap(msg.sender, side_, amountIn_, amountOut, to);
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
