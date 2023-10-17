# ERC1363 Tokens and Bonding Curves Assignment

## ERC777 and ERC1363

Both ERC777 and ERC1363 allow for additional business logic to occur when a token is transferred. This helps to reduce
gas fees because both the transfer and additional logic can be completed in a single transaction, removing the overhead
associated with creating a new transaction. ERC777 attempts to add more functionality to ERC20 by adding the ability
for contracts and external accounts to register callback functions which are called when tokens are about to be
transfered from their account or after they have been received. This allows for addresses to reject certain transfers
or perform additional logic before/after transfers. ERC1363 is offers similiar benefits however it does not have a
callback which is called on the from address before the transfer. It also adds a callback on the spender when they
approve another address to spend on their behalf.

ERC777 presents the opportunity for an attacker to register a malicious callback function to be called when tokens are
transfered to them. The callback function can be re-entrant allowing an attacker to exploit vulnerabilities in contracts
which send them tokens. Another problem is that the callback function cannot know who the actual `msg.sender` was that
sent them the tokens and so the value of `operator` can be manipulated whoever calls the callback.

## SafeERC20

The issue with calling the standard ERC20 methods on an aribitrary contract is that the contract may not correctly
implement the API. The SafeERC20 handles cases where the contract does not return a boolean value and signals failure
via an exception/revert.

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
