const ethers = require('ethers');

const BuyOrder = [
    {
        name: 'buyer',
        type: 'address'
    },
    {
        name: 'expiry',
        type: 'uint256'
    },
    {
        name: 'nonce',
        type: 'uint256'
    },
    {
        name: 'quantity',
        type: 'uint256'
    },
    {
        name: 'price',
        type: 'uint256'
    }
];
const SellOrder = [
    {
        name: 'seller',
        type: 'address'
    },
    {
        name: 'expiry',
        type: 'uint256'
    },
    {
        name: 'nonce',
        type: 'uint256'
    },
    {
        name: 'quantity',
        type: 'uint256'
    },
    {
        name: 'price',
        type: 'uint256'
    }
]

const alice = ethers.Wallet.fromPhrase('test test test test test test test test test test test junk');
const bob = ethers.Wallet.fromPhrase('test test test test test test test test test test test absent');

console.log('alice = ', alice);
console.log('bob = ', bob);

const buy1Expiry = 1720228758;
const buy1 = {
    buyer: alice.address,
    expiry: buy1Expiry,
    nonce: 0,
    quantity: ethers.parseEther("10"),
    price: ethers.parseEther("2.01")
};

const sell1Expiry = 1722907158;
const sell1 = {
    seller: bob.address,
    expiry: sell1Expiry,
    nonce: 0,
    quantity: ethers.parseEther("5"),
    price: ethers.parseEther("1.99")
};

const sell2 = {...sell1};
sell2.nonce++;

console.log('buy1Hash = ', ethers.TypedDataEncoder.hashStruct('BuyOrder', {BuyOrder}, buy1));
console.log('sell1Hash = ', ethers.TypedDataEncoder.hashStruct('SellOrder', {SellOrder}, sell1));
console.log('sell2Hash = ', ethers.TypedDataEncoder.hashStruct('SellOrder', {SellOrder}, sell2));
