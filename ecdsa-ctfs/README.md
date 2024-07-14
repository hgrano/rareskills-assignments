## ECDSA CTFs

### Exercise 0

> What pieces of information go in to an EIP 712 delimiter, and what could go wrong if those were omitted?

The message to be signed is defined as the `keccak256` hash of the concatenation of the below values:

1. `"\x19\x01"`
1. `domainSeparator = hashStruct(eip712Domain)`
1. `hashStruct(message)`

where

`hashStruct = keccak256(typeHash + encodeData(s))`

The domain separator helps to avoids users signing a message which could unexpetedly be a valid message in a
different application, contract or chain. If it were omitted then an attacker could replay the message and signature
in a different context. The domain separator is made up of the following fields:

- `string name`
- `string version`
- `uint256 chainId`
- `address verifyingContract`
- `bytes32 salt`

The `name` and `version` help to avoid collisions with other applications/protocols or other versions of the same
application/protocol. The `chainId` protects against signature re-use across different chains. The `verifyingContract`
restricts signatures so they are valid only for the specific contract they are intended for (one protocol could be
composed of multiple contracts so this allows for selection of the appropriate contract). The `salt` is a last
resort way to separate signatures used within the exact same contract but for different purposes.

### Exercise 3

1. `renounceOwnership()` (owner is set to the zero address)
1. `claimAirdrop(0xFFFF...F, attackerAddress, 0, bytes32(0), bytes32(0))` (because the signature is invalid, the recovered address is zero)
