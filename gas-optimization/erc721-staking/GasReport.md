## Gas Usage Report

Here is a comparison between the original `Staking721` contract and the optimized version. The default optimization
settings used by Foundry were not changed.

| Method | Scenario | Gas | Gas after optimization
| ------------- | ------------- | ------------- | ------------- |
| `stake` | First time any user stakes | 207,696 | 117,525 |
| `stake` | Second time a user stakes (under the same staking condition as their first stake) | 106,176 | 60,710 |
| `stake` | Second time a user stakes (but the staking condition has been changed once between the first and second stake) | 107,565 | 62,069  |
| `stake` | First time a user stakes (but another user has already staked before) | 105,996 | 65,860  |
| `withdraw` | Withdraw all (2) tokens staked (and the staking condition has not changed since the user last called `stake`) | 39,301 | 37,090 |
| `withdraw` | Withdraw all (20) tokens staked (and the staking condition has not changed since the user last called `stake`) | 150,351 | 143,636 |
| `withdraw` | Withdraw one of two tokens staked (and the staking condition has not changed since the user last called `stake`) | 31,655 | 32,304 |
| `claimRewards` | Claim rewards for the token staked (and the staking condition has not changed since the user called `stake`) | 22,993 | 22,848 |

The rewards were distributed via minting ERC20 tokens using the default OpenZeppelin ERC20 implementation. The users
were gifted a small amount of the ERC20 token before running the tests, ensuring less overhead from setting the balance
of the user from zero to non-zero when testing the `claimRewards` function.
