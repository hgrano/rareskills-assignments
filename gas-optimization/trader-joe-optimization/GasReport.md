## Gas Usage Report

Here is a comparison between the original `TokenVesting` contract and the optimized version. The default
optimization settings used by Foundry were not changed. Each reported gas value measures the execution cost of a single
invocation of the method as reported by `forge`.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `release` | Test calling `release` for the first time (after the cliff period but before the final time) | 63,062 | 53,787 |
| `release` | Test calling `release` for the second time (after the cliff period but before the final time) | 9,262 | 7,987 |
| `release` | Test calling `release` for the first time (at the the final time) | 48,344 | 41,160 |
| `release` | Test calling `release` for the second time (at the the final time) | 6,904 | 6,120 |
