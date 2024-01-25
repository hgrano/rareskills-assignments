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

The blockhash will be equal to zero if called on a block number less than the current block number minus 256. Therefore we just need guess zero and wait until 257 blocks after the `settlementBlockNumber` to submit our transaction.

### Capture the Ether Token Whale Challenge

Solution: https://github.com/hgrano/capture-the-ether-foundry/blob/master/TokenWhale/src/TokenWhale.sol, https://github.com/hgrano/capture-the-ether-foundry/blob/master/TokenWhale/test/TokenWhale.t.sol

The `transferFrom` method has a flaw in which it actually does a transfer from the `msg.sender` not from the `from` address. It calls the interal `_transfer` method which does unchecked arithmetic on the `msg.sender`'s balance. Starting with zero balance, the attacker contract just needs to call `transferFrom` with a quantity of one token, and its balance will become `2 ** 256 - 1`. It can then transfer tokens out to the player's address.
