const ethers = require('ethers');

const structDefinitions = {
    BuyOrder: [
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
    ]
    //,
    // SellOrder: [
    //     {
    //         name: 'seller',
    //         type: 'address'
    //     },
    //     {
    //         name: 'expiry',
    //         type: 'uint256'
    //     },
    //     {
    //         name: 'nonce',
    //         type: 'uint256'
    //     },
    //     {
    //         name: 'quantity',
    //         type: 'uint256'
    //     },
    //     {
    //         name: 'price',
    //         type: 'uint256'
    //     }
    // ]
}

const alice = ethers.Wallet.fromPhrase('test test test test test test test test test test test junk');

const buy1 = {
    buyer: alice.address,
    expiry: 0,
    nonce: 1,
    quantity: ethers.parseEther("1"),
    price: ethers.parseEther("1")
}

const buy1Hashed = ethers.TypedDataEncoder.hashStruct('BuyOrder', structDefinitions, buy1);
console.log('buy1hashed = ', buy1Hashed);
