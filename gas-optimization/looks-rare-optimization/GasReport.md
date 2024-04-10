## Gas Usage Report

### Areas for improvement

Storage variables:

```diff
     struct StakingPeriod {
-        uint256 rewardPerBlockForStaking;
-        uint256 rewardPerBlockForOthers;
-        uint256 periodLengthInBlock;
+        // Single slot
+        uint32 periodLengthInBlock; // Given 12 seconds per block, this can go up to a maximum of ~1600 years
+        uint112 rewardPerBlockForOthers;
+        uint112 rewardPerBlockForStaking;
     }
 
     struct UserInfo {
-        uint256 amount; // Amount of staked tokens provided by user
-        uint256 rewardDebt; // Reward debt
+        uint128 amount; // Amount of staked tokens provided by user
+        uint128 rewardDebt; // Reward debt
     }
 
     // Precision factor for calculating rewards
@@ -35,31 +36,41 @@ contract TokenDistributor is ReentrancyGuard, ITokenDistributor {
     address public immutable tokenSplitter;
 
+    // BEGIN SLOT
     // Accumulated tokens per share
-    uint256 public accTokenPerShare;
+    // Assuming the token has 18 decimal places, coupled with the 12 decimal places for the PRECISION_FACTOR we can
+    // store a max value of ~1.46 * 10**18 tokens in this variable
+    uint160 public accTokenPerShare; 
 
     // Current phase for rewards
-    uint256 public currentPhase;
+    uint16 public currentPhase; // Max of ~65,000
 
     // Block number when rewards end
-    uint256 public endBlock;
+    uint40 public endBlock;
 
     // Block number of the last update
-    uint256 public lastRewardBlock;
+    uint40 public lastRewardBlock;
+    // END SLOT
 
+    // BEGIN SLOT
     // Tokens distributed per block for other purposes (team + treasury + trading rewards)
-    uint256 public rewardPerBlockForOthers;
+    // Assuming the token has 18 decimal places, then this variable can store at most ~5.2 * 10**18 tokens
+    uint112 public rewardPerBlockForOthers;
 
     // Tokens distributed per block for staking
-    uint256 public rewardPerBlockForStaking;
+    // Assuming the token has 18 decimal places, then this variable can store at most ~5.2 * 10**18 tokens
+    uint112 public rewardPerBlockForStaking;
+    // END SLOT
```

`deposit` function should use variable caching:

```diff
     function deposit(uint256 amount) external nonReentrant {
+        // To make the tests compile `uint256` is used as the parameter type so it is the same signature as the
+        // original contract, but in practice it should be changed to uint128
         require(amount > 0, "Deposit: Amount must be > 0");
 
         // Update pool information
@@ -150,17 +163,24 @@ contract TokenDistributor is ReentrancyGuard, ITokenDistributor {
         looksRareToken.safeTransferFrom(msg.sender, address(this), amount);
 
         uint256 pendingRewards;
+        uint256 userAmount = userInfo[msg.sender].amount;
+        uint256 accTokenPerShare_ = accTokenPerShare;
 
         // If not new deposit, calculate pending rewards (for auto-compounding)
-        if (userInfo[msg.sender].amount > 0) {
+        if (userAmount > 0) {
             pendingRewards =
-                ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
-                userInfo[msg.sender].rewardDebt;
+                ((userAmount * accTokenPerShare_) / PRECISION_FACTOR) - userInfo[msg.sender].rewardDebt;
         }
 
+        uint256 newAmount = userAmount + amount + pendingRewards;
+        require(newAmount <= type(uint128).max, "Deposit: New amount must be within range of uint128");
+
         // Adjust user information
-        userInfo[msg.sender].amount += (amount + pendingRewards);
-        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;
+        userInfo[msg.sender].amount = uint128(newAmount);
+
+        uint256 newRewardDebt = (newAmount * accTokenPerShare_) / PRECISION_FACTOR;
+        require(newRewardDebt <= type(uint128).max, "Deposit: New reward debt must be within range of uint128");
+        userInfo[msg.sender].rewardDebt = uint128(newRewardDebt);
 
         // Increase totalAmountStaked
         totalAmountStaked += (amount + pendingRewards);

```

`harvestAndCompound` can also be optimized:

```diff
     function harvestAndCompound() external nonReentrant {
         // Update pool information
         _updatePool();
 
+        uint256 userAmount = uint256(userInfo[msg.sender].amount);
+        uint256 accTokenPerShare_ = uint256(accTokenPerShare);
+
         // Calculate pending rewards
-        uint256 pendingRewards = ((userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR) -
-            userInfo[msg.sender].rewardDebt;
+        uint256 pendingRewards = ((userAmount * accTokenPerShare_) / PRECISION_FACTOR) -
+            uint256(userInfo[msg.sender].rewardDebt);
 
         // Return if no pending rewards
         if (pendingRewards == 0) {
             // It doesn't throw revertion (to help with the fee-sharing auto-compounding contract)
             return;
         }
 
+        uint256 newAmount = userAmount + pendingRewards;
+        require(newAmount <= type(uint128).max, "harvestAndCompound: New amount must be within range of uint128");
+
         // Adjust user amount for pending rewards
-        userInfo[msg.sender].amount += pendingRewards;
+        userInfo[msg.sender].amount = uint128(newAmount);
 
         // Adjust totalAmountStaked
         totalAmountStaked += pendingRewards;
 
         // Recalculate reward debt based on new user amount
-        userInfo[msg.sender].rewardDebt = (userInfo[msg.sender].amount * accTokenPerShare) / PRECISION_FACTOR;
+        uint256 newRewardDebt = (newAmount * accTokenPerShare_) / PRECISION_FACTOR;
+        require(
+            newRewardDebt <= type(uint128).max,
+            "harvestAndCompound: New reward debt must be within range of uint128"
+        );
+        userInfo[msg.sender].rewardDebt = uint128(newRewardDebt);
 
         emit Compound(msg.sender, pendingRewards);
     }
```

### Test results

Here is a comparison between the original `TokenDistributor` contract and the optimized version. The default
optimization settings used by Foundry were not changed.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `deposit` | First deposit a user makes (but after at least one other user has made a deposit) | 145,504 | 98,228 |
| `deposit` | Second deposit a user makes (within the same phase but different block as their first deposit) | 58,235 | 30,911 |
| `deposit` | Second deposit a user makes (within the next phase after their first deposit) | 58,235 | 30,911 |
| `harvestAndCompound` | Make a deposit and then call `harvestAndCompound` (within the same phase but different block as the deposit)  | 52,365 | 25,021 |
| `withdraw` | Make a deposit and then call `withdraw` (within the same phase but different block as the deposit)  | 57,492 | 30,272 |
| `withdrawAll` | Make a deposit and then call `withdrawAll` (within the same phase but different block as the deposit)  | 47,889 | 25,667 |
