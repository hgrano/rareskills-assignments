# Security 1

## First week

### Capture the Ether Guess the secret number

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/GuessSecretNumber/src/GuessSecretNumber.sol

Given the guess is only 8 bits, it is feasible to simply loop over all possible values of the guess to see which one works.

### Capture the Ether predict the future

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/PredictTheFuture/src/PredictTheFuture.sol

There are only 10 possible values for `answer` as it is always calculated modulo 10. Therefore if we guess an answer of zero we can keep trying until such time as the hash (of the previous block hash and the current block timestamp) so happens to be a multiple of 10.

### RareSkills Riddles: ERC1155

Solution: https://github.com/hgrano/solidity-riddles/blob/main/contracts/Overmint1-ERC1155-Attacker.sol

The attacker contract re-enters the `mint` function within its `onERC1155Received` method. Since the `mint` function has not already updated the `amountMinted` storage, the attacker can request as many tokens as they want. We stop the recursion at 5 tokens in this example.

### Capture the Ether Token Bank

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/TokenBank/src/TokenBank.sol

The attacker contract (not the player) initially has a balance of zero in the token bank contract. The attacker then transfers in one token to the bank. It then calls `withdraw` on the bank, during which the token is transfered back to the attacker contract and its `tokenFallback` is executed. The fallback function can then call `withdraw` again as its balance has not been decreased yet. The attacker's balance is the decreased by one, and then one again - but second decrease results in an overflow (wraps back to max value of `uint256` as it is using `unchecked`). Finally the attacker contract can withdraw all available balance.

### Capture the Ether Predict the block hash

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/PredictTheBlockhash/test/PredictTheBlockhash.t.sol

The blockhash will be equal to zero if called on a block number less than the current block number minus 256. Therefore we just need to guess zero and wait until 257 blocks after the `settlementBlockNumber` to submit our transaction.

### Capture the Ether Token Whale Challenge

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/TokenWhale/src/TokenWhale.sol, https://github.com/hgrano/capture-the-ether-foundry/blob/master/TokenWhale/test/TokenWhale.t.sol

The `transferFrom` method has a flaw in which it actually does a transfer from the `msg.sender` not from the `from` address. It calls the internal `_transfer` method which does unchecked arithmetic on the `msg.sender`'s balance. Starting with zero balance, the attacker contract just needs to call `transferFrom` with a quantity of one token, and its balance will become `2 ** 256 - 1`. It can then transfer tokens out to the player's address.

## Second week

### Capture the Ether Token Sale (this one is more challenging)

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/TokenSale/test/TokenSale.t.sol

The `buy` function uses unchecked arithmetic when calculating the `total` amount the caller needs to pay. Therefore if we set the `numTokens` parameter high enough such that the `total` overflows, but in such a way that the resulting `total` is not too high an amount, we can acquire a very large number of tokens. After this, we just need to sell one token to steal all ether in the contract.

### Capture the Ether Retirement fund

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/RetirementFund/src/RetirementFund.sol, https://github.com/hgrano/capture-the-ether-foundry/blob/master/RetirementFund/test/RetirementFund.t.sol

The `collectPenalty` function allows the user to withdraw all funds as long as the `startBalance - address(this.balance) > 0` (using `unchcked`). If we forcilby transfer ether to the contract (using `selfdestruct`) we can make `address(this.balance) > startBalance` and hence overflow this calculation. Then we can call `collectPenalty` and drain all balance of the contract.

### Damn Vulnerable Defi #4 Side Entrance (Most vulnerabilities are application specific)

Solution: https://github.com/hgrano/damn-vulnerable-defi/blob/master/contracts/side-entrance/SideEntranceLenderPool.sol

The issue with the contract is that after calling `flashLoan` the contract can still suffer re-entrancy through the `deposit` function if the attacker contract does the following:

1. Take out a flash loan with all available funds of the victim.
1. Within its `execute` function, use the loaned funds to `deposit` back to the victim. This increases the attacker contract's balance, and pays back the loan.
1. Finally the attacker contract can use its balance to withdraw all funds from the victim.

### Damn Vulnerable Defi #1 Unstoppable (this is challenging)

Solution: https://github.com/hgrano/damn-vulnerable-defi/blob/master/test/unstoppable/unstoppable.challenge.js

The problem with the contract is that if a user directly transfers the token to the contract then they can manipulate `balanceBefore` [here](https://github.com/hgrano/damn-vulnerable-defi/blob/c23cd748744a12d75324ba8ec122c0470de8e251/contracts/unstoppable/UnstoppableVault.sol#L95-L96). This will then cause the assertion to fail.

**Is there a more elegant solution?**

### Ethernaut #20 Denial

Solution: https://github.com/hgrano/rareskills-assignments/blob/main/security1/ethernaut-solutions/src/Denial.sol

By setting the withdraw partner to be a malicious contract with a `receive` function that drains all available gas, when we transfer ether to them [here](https://github.com/hgrano/rareskills-assignments/blob/d2218bb69868e52c9a7571dd13ee68ad7be83b87/security1/ethernaut-solutions/src/Denial.sol#L19) the transaction will revert with out of gas error. This happens even though we ignore the return value of the low level `call.`

### Ethernaut #15 Naught Coin

Solution: https://github.com/hgrano/rareskills-assignments/blob/main/security1/ethernaut-solutions/test/NaughtCoin.t.sol

This is a very basic error in the contract where the `transferFrom` function does not include the `lockTokens` modifier. The developer should have put the modifier on the internal function (`_update`) which OpenZeppelin's ERC20 implementation uses for all types of transfers.
