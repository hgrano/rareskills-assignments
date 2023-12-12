## Slither

> Document true and false positives that you discovered with the tools

### Uniswap Assignment Analysis

#### True positives

```
Pair.removeLiquidity(uint256,uint256,uint256,address) (src/Pair.sol#163-195) ignores return value by IERC20(token0_).transfer(to,amount0) (src/Pair.sol#183)
Pair.removeLiquidity(uint256,uint256,uint256,address) (src/Pair.sol#163-195) ignores return value by IERC20(token1_).transfer(to,amount1) (src/Pair.sol#184)
```

Due to a typo - need to replace `transfer` with `safeTransfer`

#### False positives

```
Pair._updateReserves(uint256,uint256,uint112,uint112) (src/Pair.sol#321-341) uses a weak PRNG: "currentBlockTimestamp = uint32(block.timestamp % 2 ** 32) (src/Pair.sol#327)" 
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG
```

`_updateReserves` is not using `block.timestamp` as a PRNG.

```
Pair.constructor(address,address).token0_ (src/Pair.sol#67) lacks a zero-check on :
                - token0 = token0_ (src/Pair.sol#68)
Pair.constructor(address,address).token1_ (src/Pair.sol#67) lacks a zero-check on :
                - token1 = token1_ (src/Pair.sol#69)
```

If either of these is the zero address then we will not be able to add liquidity to the contract anyway.

```
Reentrancy in Pair.addLiquidity(uint256,uint256,uint256,uint256,address) (src/Pair.sol#79-154):
        External calls:
        - IERC20(token0_).safeTransferFrom(msg.sender,address(this),amount0Approved) (src/Pair.sol#91)
        - IERC20(token1_).safeTransferFrom(msg.sender,address(this),amount1Approved) (src/Pair.sol#92)
        State variables written after the call(s):
        - _updateReserves(IERC20(token0_).balanceOf(address(this)),IERC20(token1_).balanceOf(address(this)),0,0) (src/Pair.sol#100)
                - _reserve0 = uint112(newReserve0) (src/Pair.sol#339)
        - _updateReserves(IERC20(token0_).balanceOf(address(this)),IERC20(token1_).balanceOf(address(this)),0,0) (src/Pair.sol#100)
                - _reserve1 = uint112(newReserve1) (src/Pair.sol#340)
        - _updateReserves(IERC20(token0_).balanceOf(address(this)),IERC20(token1_).balanceOf(address(this)),0,0) (src/Pair.sol#100)
                - blockTimestampLast = currentBlockTimestamp (src/Pair.sol#338)
        - _updateReserves(IERC20(token0_).balanceOf(address(this)),IERC20(token1_).balanceOf(address(this)),0,0) (src/Pair.sol#100)
                - price0CumulativeLast += uint256(_asFixedPoint112(currentReserve1) / uint224(currentReserve0)) * timeSinceLastUpdate (src/Pair.sol#332-333)
        - _updateReserves(IERC20(token0_).balanceOf(address(this)),IERC20(token1_).balanceOf(address(this)),0,0) (src/Pair.sol#100)
                - price1CumulativeLast += uint256(_asFixedPoint112(currentReserve0) / uint224(currentReserve1)) * timeSinceLastUpdate (src/Pair.sol#334-335)
```

(Same error shown for the other external functions on the Pair)

OpenZeppelin re-entrancy guard used.
