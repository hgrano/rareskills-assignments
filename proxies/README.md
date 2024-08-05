# Proxies Assignment

## Part 1

### Question 1
The OZ upgrade tool for hardhat defends against 6 kinds of mistakes. What are they and why do they matter?


Before deploying the proxy, the upgrade tool will check that the implementation contract is upgradeable. This ensures
that the implementation does not use a constructor, does not `selfdestruct` and does not perform any `delegatecall`s.

Before upgrading the proxy, it validates that new implementation is upgradeable. It also checks that the new version
is compatible with the previous. The two contracts are considered compatible if the new version does not modify the 
storage layout of the previous verison, except for the appending of new storage variables (i.e. not colliding with the
existing storage).

The tool will check to see if there is an existing contract with the same bytecode as the implementation - if one
exists then it will skip the deployment of the implementation contract.

### Question 2
What is a beacon proxy used for?

A beacon proxy is used when you have multiple proxies using the same implementation contract. In this case, it is
better to manage the version of the implementation in one place - the beacon - instead of on each proxy.

### Question 3
Why does the openzeppelin upgradeable tool insert something like `uint256[50] private __gap;` inside the contracts? To see it, create an upgradeable smart contract that has a parent contract and look in the parent.

The `__gap` variable provides empty space reserved for adding new state variables in subsequent versions of the contract.
The problem is that if contract `A` is extended by contract `B` and we add a state variable on the new version of `A`
then the state variables of `B` will be shifted down by the Solidity compiler. By having reserved a set number of storage
slots on `A` using `__gap`, we can always add a new variables and replace `uint256[50] private __gap;` with
`uint256[49] private __gap;`.

### Question 4
What is the difference between initializing the proxy and initializing the implementation? Do you need to do both? When do they need to be done?

Initializing the proxy is the process of assigning initial state to the proxy contract itself (setting the owner field
for example). Whereas the implementation initialisation is used to set state (stored on the proxy) but used by
the implementation. The proxy initialisation should be done once on deployment of the proxy. The implementation
initialisation must be done at least once - after the first implementation has been deployed/constructed. If a
new implementation is deployed which adds new state variables that require initialisation then further initialisation
may be required after deployment of the new version.

### Question 5
What is the use for the [reinitializer](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/proxy/utils/Initializable.sol#L119)? Provide a minimal example of proper use in Solidity

A `reinitializer` can be used when we need to perform further initialisation steps when a new implementation is deployed.
For example, if we need to upgrade a dependency of our contract:

```solidity
contract MyImpl is MyParent {
    function initialize() initializer public {
        __MyParent_init("some argumemt");
    }
}

contract MyImplV2 is MyImpl, MyParentV2 {
    function initializeV2() reinitializer(2) public {
        __MyParentV2_init("some argumemt");
    }.
}
```

If we deploy a third version then it will not be possible to call `initializeV2` as the version number 2 has already
been consumed.
