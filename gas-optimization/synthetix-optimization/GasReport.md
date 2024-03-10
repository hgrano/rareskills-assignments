## Gas Usage Report

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
