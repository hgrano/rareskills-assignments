## Gas Usage Report

### Areas for improvement

Storage variables can be made immutable or compacted, as 256 bits is not necessary for most of these values:

```diff
-    IERC20 public rewardsToken;
-    IERC20 public stakingToken;
-    uint256 public periodFinish = 0;
-    uint256 public rewardRate = 0;
-    uint256 public rewardsDuration = 7 days;
-    uint256 public lastUpdateTime;
+    IERC20 public immutable rewardsToken;
+    IERC20 public immutable stakingToken;
+
+    uint152 public rewardRate = 0; // Max value is approx. 5.7 * 10**27 tokens per second (assuming 18 decimals)
+    uint24 public rewardsDuration = 7 days; // Max value is approx. 194 days
+    uint40 public periodFinish = 0; // Max value is approx. 34,800 years
+    uint40 public lastUpdateTime; // Max value is approx. 34,800 years
```

If assume the ERC20 contract used is trustworthy (since the owner sets this on deployment), the `ReentrancyGuard` is
not necessary. Also, unchecked arithmetic can be used as everything should stay under the supply cap of the ERC20
token:

```diff
-    function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender) {
+    function stake(uint256 amount) external notPaused updateReward(msg.sender) { // nonReentrant modifier not needed if we use trusted ERC20 tokens
         require(amount > 0, "Cannot stake 0");
-        _totalSupply = _totalSupply + amount;
-        _balances[msg.sender] = _balances[msg.sender] + amount;
         stakingToken.safeTransferFrom(msg.sender, address(this), amount);
+        unchecked { // msg.sender cannot own more than total supply of the staking token, so unchecked is safe
+            _totalSupply = _totalSupply + amount;
+            _balances[msg.sender] = _balances[msg.sender] + amount;
+        }
         emit Staked(msg.sender, amount);
     }
```

### Test results

Here is a comparison between the original `StakingRewards` contract and the optimized version. The default
optimization settings used by Foundry were not changed. Each reported gas value measures the execution cost of a single
invocation of the method as reported by `forge`.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `stake` | First time a user calls the `stake` function (at a time when no other users have deposited yet) | 101,698 | 95,105 |
| `stake` | Second time a user calls the `stake` function (within the same block as their first stake) | 14,320 | 11,979 |
| `stake` | Second time a user calls the `stake` function (within the same period but different block as their first stake) | 76,820 | 74,479 |
| `stake` | Second time a user calls the `stake` function (within a different period as their first stake) | 101,698 | 95,105 |
| `withdraw` | Withdraw part of the user's balance | 13,634 | 11,486 |
| `withdraw` | Withdraw all of the user's balance | 13,148 | 9,189 |
| `getReward` | Test getting rewards | 86,445 | 82,944 |
