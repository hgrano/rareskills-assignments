import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("BondingCurveToken", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployBondingCurveTokenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2] = await ethers.getSigners();

    const BondingCurveToken = await ethers.getContractFactory("BondingCurveToken");
    const slope = 2;
    const bondingCurveToken = await BondingCurveToken.deploy("name", "symbol", slope);

    return { bondingCurveToken, slope, owner, user1, user2 };
  }

  describe("Purchasing", function () {
    it("Should have correct price initially", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const user1InitialBalance = await ethers.provider.getBalance(user1);
      const tx = await bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 });
      const txReceipt = await tx.wait();
      if (txReceipt == null) {
        throw Error("Tx receipt is null");
      }
      expect(await bondingCurveToken.balanceOf(user1)).to.equal(1e3);
      const gasSpend = txReceipt.gasPrice * txReceipt.gasUsed;
      expect(await ethers.provider.getBalance(user1)).to.equal(user1InitialBalance - BigInt(1e6) - gasSpend);
    });

    it("Should not permit purchase with insufficient funds", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      await expect(
        bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 - 1 })
      ).to.be.revertedWith("Insufficient funds");
    });

    it("Should send refund", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const user1InitialBalance = await ethers.provider.getBalance(user1);
      const tx = await bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 + 1 });
      const txReceipt = await tx.wait();
      if (txReceipt == null) {
        throw Error("Tx receipt is null");
      }
      expect(await bondingCurveToken.balanceOf(user1)).to.equal(1e3);
      const gasSpend = txReceipt.gasPrice * txReceipt.gasUsed;
      expect(await ethers.provider.getBalance(user1)).to.equal(user1InitialBalance - BigInt(1e6) - gasSpend);
    });

    it("Should update price after one purchase", async function() {
      const { bondingCurveToken, user1, user2 } = await loadFixture(deployBondingCurveTokenFixture);

      await expect(bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 })).to.not.be.reverted;
      await expect(bondingCurveToken.connect(user1).buy(1, { value: 2e3 + 1 })).to.not.be.reverted;
      expect(await bondingCurveToken.balanceOf(user1)).to.equal(1e3 + 1);
    });
  });

  describe("Selling", function() {
    it("Should allow selling up to maximum available supply", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const user1InitialBalance = await ethers.provider.getBalance(user1);
      const buyTx = await bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 });
      const buyTxReceipt = await buyTx.wait();
      if (buyTxReceipt == null) {
        throw Error("Tx receipt is null");
      }
      const sellTx = await bondingCurveToken.connect(user1).sell(1e3, 0);
      const sellTxReceipt = await sellTx.wait();
      if (sellTxReceipt == null) {
        throw Error("Tx receipt is null");
      }

      expect(await bondingCurveToken.totalSupply()).to.equal(0);
      expect(await ethers.provider.getBalance(bondingCurveToken)).to.equal(0);

      expect(await bondingCurveToken.balanceOf(user1)).to.equal(0);
      const gasSpend = buyTxReceipt.gasPrice * buyTxReceipt.gasUsed + sellTxReceipt.gasPrice * sellTxReceipt.gasUsed;
      expect(await ethers.provider.getBalance(user1)).to.equal(user1InitialBalance - gasSpend);
    });

    it("Should not permit selling without sufficient balance", async function() {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      await expect(bondingCurveToken.connect(user1).sell(1, 0)).to.be.reverted;
    });

    it("Should limit price slippage when selling", async function() {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      await expect(bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 })).to.not.be.reverted;
      await expect(bondingCurveToken.connect(user1).sell(1e3, 1e6 + 1)).to.be.reverted;
    });
  });

  // TODO test overflow
});
