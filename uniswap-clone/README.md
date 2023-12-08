## Uniswap Clone Assignment

## TWAP Oracle

> Why does the price0CumulativeLast and price1CumulativeLast never decrement?

They never decrement because the user of these values is expected to regularly record a snapshot of them. At any given
time they can subtract the snapshotted values from the current values, and divide by the time since the last snapshot.
This will provide the TWAP. As price0CumulativeLast and price1CumulativeLast never decrement, they may overflow. This
means they wrap back around to zero i.e. the values are just modulo (2^256 - 1). If we denote the snapshotted value as
`y` and the current value as `x`, and `M = 2^256 - 1`, then difference used to calculate the TWAP is:

```
(x % M - y) % M             (modulo M because all arithmetic uses a fixed number of bits)

= ((y + d) % M - y) % M     (Denote the difference between x and y as d)

= ((y + d - M) - y) % M     (Assuming d is not more than M)

= (d - M) % M

= d
```

Therefore due to the rules of modular arithmetic the fact that these values overflow does not matter.

> How do you write a contract that uses the oracle?

As described above, you need to snap shot the values and record the block timestamp at the time. Then at times after
this, we subract the current cumulative values from the Pair from the snapshotted values and divide by the time elapsed.
This gives the time-weighted average. We should regularly refresh the snapshot to provide a more accurate TWAP
reflective of more recent prices.

> Why are price0CumulativeLast and price1CumulativeLast stored separately? Why not just calculate `price1CumulativeLast = 1/price0CumulativeLast?

Let's say we only store price0CumulativeLast which is currently has a value of 10. And we need to add 1 to to calculate
the new value:

```
price0CumulativeLast = 10 + 1 = 11

price1CumulativeLast (inferred as the inverse) = 1/11

price1CumulativeLast (actual) = 1/10 + 1/1 = 11/10
```

So clearly we cannot infer the price1CumulativeLast as the inverse of price0CumulativeLast.
