## Gas Usage Report

Here is a comparison between the original `Staking721` contract and the optimized version. The default optimization
settings used by Foundry were not changed.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `stake` | First time any user stakes | 207,696 |  |
| `stake` | Second time a user stakes (under the same staking condition as their first stake) | 106,176 |  |
| `stake` | Second time a user stakes (but the staking condition has been changed between the first and second stake) | 107,565 |  |
| `stake` | First time a user stakes (but another user has already staked before) | 105,996 |  |
| `withdraw` | Withdraw all (two) tokens staked (and the staking condition has not changed since they called `stake`) | 39,301 |  |
| `withdraw` | Withdraw one of two tokens staked (and the staking condition has not changed since they called `stake`) | 31,655 |  |
| `claimRewards` | Claim rewards for the token staked (and the staking condition has not changed since they called `stake`) | 25,121 |  |

The rewards were distributed via minting ERC20 tokens using the default OpenZeppelin ERC20 implementation. The users
were gifted a small amount of the ERC20 token before running the tests, ensuring less overhead from setting the balance
of the user from zero to non-zero when testing the `claimRewards` function.
