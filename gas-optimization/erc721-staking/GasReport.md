## Gas Usage Report

### Areas for improvement

We can reduce storage needed for each staker and staking condition. Also, each `Staker` can store the array of
`tokenStaked` by removing the one large array of tokens staked by all users.

```diff
-struct Staker {
-    uint64 amountStaked;
-    uint64 conditionIdOflastUpdate;
-    uint128 timeOfLastUpdate;
-    uint256 unclaimedRewards;
+struct OptimizedStaker {
+    uint40 conditionIdOflastUpdate;
+    uint48 timeOfLastUpdate;
+    uint128 unclaimedRewards;
+    uint256[] tokensStaked;
 }
 
-struct StakingCondition {
-    uint256 timeUnit;
-    uint256 rewardsPerUnitTime;
-    uint256 startTimestamp;
-    uint256 endTimestamp;
+struct OptimizedStakingCondition {
+    uint32 timeUnit;
+    uint128 rewardsPerUnitTime;
+    uint48 startTimestamp;
+    uint48 endTimestamp;
 }
```

Storage variables can re-factored. The internal `isStaking` variable is not used in the contract - if contracts that
inherit `Staking721` need this type of flag, then it should be implemented on them, rather than the base contract. That
would give more flexibility to developers to choose to optimize their implementation or use this feature if necessary.
The public arrays (`stakersArray` and `indexedTokens`) do not appear to be necessary except for reading this data -
perhaps from a UI - so these could be instead derived off-chain using events.

```diff
-    /// @dev Flag to check direct transfers of staking tokens.
-    uint8 internal isStaking = 1;
-
     ///@dev Next staking condition Id. Tracks number of conditon updates so far.
-    uint64 private nextConditionId;
-
-    ///@dev List of token-ids ever staked.
-    uint256[] public indexedTokens;
-
-    /// @dev List of accounts that have staked their NFTs.
-    address[] public stakersArray;
-
-    ///@dev Mapping from token-id to whether it is indexed or not.
-    mapping(uint256 => bool) public isIndexed;
+    uint40 private nextConditionId;
 
     ///@dev Mapping from staker address to Staker struct. See {struct IStaking721.Staker}.
-    mapping(address => Staker) public stakers;
-
-    /// @dev Mapping from staked token-id to staker address.
-    mapping(uint256 => address) public stakerAddress;
+    mapping(address => OptimizedStaker) public stakers;
 
     ///@dev Mapping from condition Id to staking condition. See {struct IStaking721.StakingCondition}
-    mapping(uint256 => StakingCondition) private stakingConditions;
+    mapping(uint256 => OptimizedStakingCondition) private stakingConditions;
```

Re-entrancy guards can be removed from this contract. These can be added by contracts which inherit `Staking721` if
they are necessary.

We can reduce gas costs of the `_stake` function by not needing to update the public
arrays mentioned previously.

```diff
     function _stake(uint256[] calldata _tokenIds) internal virtual {
-        uint64 len = uint64(_tokenIds.length);
+        uint256 len = _tokenIds.length;
         require(len != 0, "Staking 0 tokens");
 
         address _stakingToken = stakingToken;
 
-        if (stakers[_stakeMsgSender()].amountStaked > 0) {
+        if (stakers[_stakeMsgSender()].tokensStaked.length > 0) {
             _updateUnclaimedRewardsForStaker(_stakeMsgSender());
         } else {
-            stakersArray.push(_stakeMsgSender());
-            stakers[_stakeMsgSender()].timeOfLastUpdate = uint128(block.timestamp);
+            stakers[_stakeMsgSender()].timeOfLastUpdate = uint48(block.timestamp);
             stakers[_stakeMsgSender()].conditionIdOflastUpdate = nextConditionId - 1;
         }
         for (uint256 i = 0; i < len; ++i) {
-            isStaking = 2;
             IERC721(_stakingToken).safeTransferFrom(_stakeMsgSender(), address(this), _tokenIds[i]);
-            isStaking = 1;
-
-            stakerAddress[_tokenIds[i]] = _stakeMsgSender();
 
-            if (!isIndexed[_tokenIds[i]]) {
-                isIndexed[_tokenIds[i]] = true;
-                indexedTokens.push(_tokenIds[i]);
-            }
+            stakers[_stakeMsgSender()].tokensStaked.push(_tokenIds[i]);
         }
-        stakers[_stakeMsgSender()].amountStaked += len;
 
         emit TokensStaked(_stakeMsgSender(), _tokenIds);
     }
```

Due to not needing to update large public arrays, we can optimize the `withdraw` function:

```diff
     function _withdraw(uint256[] calldata _tokenIds) internal virtual {
-        uint256 _amountStaked = stakers[_stakeMsgSender()].amountStaked;
-        uint64 len = uint64(_tokenIds.length);
-        require(len != 0, "Withdrawing 0 tokens");
-        require(_amountStaked >= len, "Withdrawing more than staked");
+        uint256[] storage tokensStaked = stakers[_stakeMsgSender()].tokensStaked;
+        uint256 _amountStaked = tokensStaked.length;
+        uint256 len = _tokenIds.length;
+        // We re-design the logic so that if the user wants to withdraw all tokens they can supply a zero-length array
+        // to indicate this, and consequently we can optimize the implementation
+        require(_amountStaked >= len || len == 0, "Withdrawing more than staked");
 
         address _stakingToken = stakingToken;
 
         _updateUnclaimedRewardsForStaker(_stakeMsgSender());
 
-        if (_amountStaked == len) {
-            address[] memory _stakersArray = stakersArray;
-            for (uint256 i = 0; i < _stakersArray.length; ++i) {
-                if (_stakersArray[i] == _stakeMsgSender()) {
-                    stakersArray[i] = _stakersArray[_stakersArray.length - 1];
-                    stakersArray.pop();
-                    break;
+        unchecked { // Only index increments/decrements done in this block (which are bounded correctly)
+            if (len > 0) {
+                for (uint256 i = 0; i < len; ++i) {
+                    uint256 tokensStakedLen = tokensStaked.length;
+                    for (uint256 stakedIndex = 0; stakedIndex < tokensStakedLen; ++stakedIndex) {
+                        if (tokensStaked[stakedIndex] == _tokenIds[i]) {
+                            tokensStaked[stakedIndex] = tokensStaked[tokensStakedLen - 1];
+                            tokensStaked.pop();
+                            break;
+                        } else {
+                            require(stakedIndex < tokensStakedLen - 1, "Token not staked by sender");
+                        }
+                    }
+                    IERC721(_stakingToken).safeTransferFrom(address(this), _stakeMsgSender(), _tokenIds[i]);
+                }   
+            } else {
+                uint256[] memory _tokensStaked = tokensStaked;
+                delete stakers[_stakeMsgSender()].tokensStaked;
+                for (uint256 stakedIndex = 0; stakedIndex < _amountStaked; ++stakedIndex) {
+                    IERC721(_stakingToken).safeTransferFrom(address(this), _stakeMsgSender(), _tokensStaked[stakedIndex]);
                 }
             }
         }
-        stakers[_stakeMsgSender()].amountStaked -= len;
-
-        for (uint256 i = 0; i < len; ++i) {
-            require(stakerAddress[_tokenIds[i]] == _stakeMsgSender(), "Not staker");
-            stakerAddress[_tokenIds[i]] = address(0);
-            IERC721(_stakingToken).safeTransferFrom(address(this), _stakeMsgSender(), _tokenIds[i]);
-        }
         emit TokensWithdrawn(_stakeMsgSender(), _tokenIds);
     }
```

### Test results

Here is a comparison between the original `Staking721` contract and the optimized version. The default optimization
settings used by Foundry were not changed.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `stake` | First time any user stakes | 207,696 | 115,038 |
| `stake` | Second time a user stakes (under the same staking condition as their first stake) | 106,176 | 42,352 |
| `stake` | Second time a user stakes (but the staking condition has been changed once between the first and second stake) | 107,565 | 43,251  |
| `stake` | First time a user stakes (but another user has already staked before) | 105,996 | 63,231  |
| `withdraw` | Withdraw all (2) tokens staked (and the staking condition has not changed since the user last called `stake`) | 39,301 | 16,887 |
| `withdraw` | Withdraw all (20) tokens staked (and the staking condition has not changed since the user last called `stake`) | 150,351 | 121,562 |
| `withdraw` | Withdraw one of two tokens staked (and the staking condition has not changed since the user last called `stake`) | 31,655 | 11,288 |
| `withdraw` | Withdraw one of one tokens staked when 500 other users currently have their tokens staked | 189,571 | 11,306 |
| `claimRewards` | Claim rewards for the token staked (and the staking condition has not changed since the user called `stake`) | 22,993 | 19,958 |

The rewards were distributed via minting ERC20 tokens using the default OpenZeppelin ERC20 implementation. The users
were gifted a small amount of the ERC20 token before running the tests, ensuring less overhead from setting the balance
of the user from zero to non-zero when testing the `claimRewards` function.
