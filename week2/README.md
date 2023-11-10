# NFT Variants and Staking Assignment

##  ERC721A

ERC721A saves gas by not storing NFT metadata in a redundant way. For example, the base URI is stored as a single
variable, to avoid storing an identical base URI for each token. It also allows for batch minting: when minting in
batch the recipients balances are updated in a single increment, rather than mulitple increments for each NFT received.
Additionally, it introduces a more efficient way to encode the ownership of tokens when we mint several to the same
address. Say for example, we mint token IDs 1 to 5 for Alice, and 6 to 10 for Bob, we only need to update the owners
for tokens 1 and 6, as the owners for others are implied by ordering.

ERC721A adds cost on reads because of the extra complexity required to iterate over an appropriate token range when
checking the owner of a token.

## Wrapped NFT

A wrapped NFT may also be useful to allow users to access new functionality that is not available with the underyling
ERC721 contract. For example, being able to engage in lending, staking, voting or other features.

## ERC721 Events

OpenSea can quickly determine what NFTs an address owns because each ERC721 contract emits a `Transfer` events on each
transfer. The `Transfer` events have an index on the sender/receiver fields. If we do a query on the `Transfer` events
where sender or receiver are equal to the address in question, we can determine what token IDs the address owns. We just
filter out NFTs which the address has transfered out.
