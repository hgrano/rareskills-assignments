## Gas Usage Report

### Areas for improvement

Use immutable variables:

```diff
-    address private _beneficiary;
+    address private immutable _beneficiary;
 
     // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
-    uint256 private _cliff;
-    uint256 private _start;
-    uint256 private _duration;
+    uint256 private immutable _cliff;
+    uint256 private immutable _start;
+    uint256 private immutable _end;
+    uint256 private immutable _duration;

-    bool private _revocable;
+    bool private immutable _revocable;
```

Cache variables so that we do not incur storage read costs:

```diff
     function release(IERC20 token) public {
-        uint256 unreleased = _releasableAmount(token);
+        uint256 releasedForToken = _released[address(token)]; // cache variable
+        uint256 unreleased = _releasableAmount(token, releasedForToken);
 
         require(unreleased > 0, "TokenVesting: no tokens are due");
 
-        _released[address(token)] = _released[address(token)] + unreleased;
+        unchecked { // Cannot exceed ERC20 supply
+            _released[address(token)] = releasedForToken + unreleased;
+        }
```

Where `_releasableAmount` is altered:

```diff 
-    function _releasableAmount(IERC20 token) private view returns (uint256) {
-        return _vestedAmount(token) - _released[address(token)];
+    function _releasableAmount(IERC20 token, uint256 releasedForToken) private view returns (uint256) {
+        return _vestedAmount(token, releasedForToken) - releasedForToken;
     }
```

The `_vestedAmount` function can also be changed for the same reason as above (the `releasedForToken` value is already read from storage):

```diff
-    function _vestedAmount(IERC20 token) private view returns (uint256) {
+    function _vestedAmount(IERC20 token, uint256 releasedForToken) private view returns (uint256) {
         uint256 currentBalance = token.balanceOf(address(this));
-        uint256 totalBalance = currentBalance + _released[address(token)];
+        uint256 totalBalance;
+        unchecked { // Cannot exceed ERC20 supply
+            totalBalance = currentBalance + releasedForToken;
+        }
 
         if (block.timestamp < _cliff) {
             return 0;
-        } else if (block.timestamp >= _start + _duration || _revoked[address(token)]) {
+        } else if (block.timestamp >= _end || _revoked[address(token)]) {
             return totalBalance;
         } else {
-            return (totalBalance * (block.timestamp - _start)) / _duration;
+            uint256 elapsed;
+            unchecked { // block.timestamp is monotonically increasing
+                elapsed = block.timestamp - _start;
+            }
+            uint256 numerator = totalBalance * elapsed;
+
+            unchecked { // duration is non-zero
+                return numerator / _duration;
+            }
         }
     }
 }
```

As shown above, unchecked arithmetic can be used in some places.

### Test results

Here is a comparison between the original `TokenVesting` contract and the optimized version. The default
optimization settings used by Foundry were not changed. Each reported gas value measures the execution cost of a single
invocation of the method as reported by `forge`.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `release` | Test calling `release` for the first time (after the cliff period but before the final time) | 63,062 | 53,787 |
| `release` | Test calling `release` for the second time (after the cliff period but before the final time) | 9,262 | 7,987 |
| `release` | Test calling `release` for the first time (at the the final time) | 48,344 | 41,160 |
| `release` | Test calling `release` for the second time (at the the final time) | 6,904 | 6,120 |
