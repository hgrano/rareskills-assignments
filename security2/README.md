# Security 2

## Third week

### RareSkills Riddles: Forwarder (abi encoding)

Solution: https://github.com/hgrano/solidity-riddles/blob/main/test/Forwarder.js

The forwarder contract allows to call any arbitrary function on any contract. We can therefore call the `sendEther` function on the `Wallet`, by providing the correclty encoded call data and send the ether from the wallet to the attacker's address.

### Damn Vulnerable Defi #3 Truster (this is challenging)

Solution: https://github.com/hgrano/damn-vulnerable-defi/blob/main/test/truster/truster.challenge.js

The `TrusterLenderPool` contract allows the attacker to make the `TrustLenderPool` call any desired function on the `target` contract. Therefore, we can can make the `TrusterLenderPool` call `approve` on the token contract, thus giving the attacker control of the pool's funds.

### RareSkills Riddles: Overmint3 (Double voting or msg.sender spoofing)

Solution: https://github.com/hgrano/solidity-riddles/blob/main/contracts/Overmint3.sol

If we call the `mint` function during construction of a contract, the `msg.sender.isContract()` will return `false`. Therefore we can call the `mint` function during contract construction, and to overcome the restriction of `amountMinter[msg.sender] < 1`, we can simply deploy other contracts as part of the constructor who can also call `mint` which can transfer the tokens back to the attacker.

### RareSkills Riddles: Democracy (Double voting or msg.sender spoofing)

Solution: https://github.com/hgrano/solidity-riddles/blob/main/contracts/Democracy.sol, https://github.com/hgrano/solidity-riddles/blob/main/test/Democracy.js

To win the election we need to vote 3 times to get a majority, but the election would normally be called after 2 votes due to this [check](https://github.com/hgrano/solidity-riddles/blob/77f898d58ade3463077ea4c956815e4257d5e1be/contracts/Democracy.sol#L104-L106). However we can re-enter the `vote` function before this occurs, because the `Democracy` contract does a transfer to the `msg.sender` before this. Each Hodler can only vote once, thererfore the caller of `vote` needs to re-enter via another contract which also has a balance of 1 token. We first vote once as the `challenger`, then transfer one token to an attacker contract, and another token to a second attacker contract. Then the first attacker can call `vote` and re-enter `vote` via the second attacker.

### Ethernaut #13 Gatekeeper 1

Solution: https://github.com/hgrano/rareskills-assignments/blob/main/ethernaut-solutions/src/GatekeeperOne.sol

Passing `gateOne` is easy - we just need to call `enter` via a smart contract rather than using an EOA. To get through `gateTwo` we need to call `enter` using a gas limit that results in `gasLeft()` being equal to a multiple of 8191 during the `require` statement. We can try many different values of the gas limit by doing a low-level call to `enter` (this way our function will not bubble up the revert), until we hit a value that works. To get through `gateThree` we need the following to be true based on the three require statements:

1. The 17th to the 32nd bit of the `_gateKey` must all be zero.
1. The 33rd to the 64th bit of the `_gateKey` must contain at least one non-zero bit.
1. The first 16 bits of the `_gateKey` must be equal to the first 16 bits of the `tx.origin`.

We can achieve these requirements as follows:

1. To get necessary bits as zero, we do a bit-wise AND with a value with all zeros in these positions.
1. To get non-zero bits, we do a bit-wise OR with a value that has all ones in these positions.
1. We initialise the gate key with the first 16 bits of the `tx.origin` using casting, then follow this up with the above bit-wise operations.

## Fourth week

### RareSkills Riddles: Delete user (understanding storage pointers)

Solution: https://github.com/hgrano/solidity-riddles/blob/main/contracts/DeleteUser.sol

The `withdraw` function does not delete the user at the provided `index`, instead it just re-assigns the storage pointer variable (`user`) and removes the last element in the `users` array. Therefore we can call `withdraw` multiple times uisng the same `index` - provided we add some extra deposits with zero value (these will be appended to the `users` and can be popped from the array with no adverse affect to the attacker).

### RareSkills Riddles: Viceroy (understanding the delete keyword)

Solution: https://github.com/hgrano/solidity-riddles/blob/main/contracts/Viceroy.sol

The solution boils down to the following issues:

1. A viceroy or voter can be appointed even if it is not an EOA, because it can be done during construction of the contract.
1. A viceroy can approve a voter, allow them to vote, then disapprove the voter. This process can be repeated an unlimited number of times. Therefore they can accumulate more than 5 votes.

### Ethernaut #23 Dex2 (access control / input validation)
### Damn Vulnerable DeFi #2 Naive Receiver (access control / input validation)
### RareSkills Riddles: RewardToken (cross function reentrancy)
### RareSkills Riddles: Read-only reentrancy (read-only reentrancy)
### Damn Vulnerable DeFi #5 (flash loan attack)
### Damn Vulnerable DeFi #6 (flash loan attack)

