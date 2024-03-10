## Gas Usage Report

Here is a comparison between the original `TokenDistributor` contract and the optimized version. The default
optimization settings used by Foundry were not changed.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `deposit` | First deposit a user makes (but after at least one other used has made a deposit) | 145,504 | 98,228 |
| `deposit` | Second deposit a user makes (within the same phase but different block as their first deposit) | 58,235 | 30,911 |
| `deposit` | Second deposit a user makes (within the next phase after their first deposit) | 58,235 | 30,911 |
| `harvestAndCompound` | Make a deposit and then call `harvestAndCompound` (within the same phase but different block as the deposit)  | 52,365 | 25,021 |
| `withdraw` | Make a deposit and then call `withdraw` (within the same phase but different block as the deposit)  | 57,492 | 30,272 |
| `withdrawAll` | Make a deposit and then call `withdrawAll` (within the same phase but different block as the deposit)  | 47,889 | 25,667 |
