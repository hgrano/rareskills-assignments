import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const COOL_DOWN_PERIOD = 24 * 60 * 60;

describe("BondingCurveToken", function () {
  async function deployBondingCurveTokenFixture() {
    const [owner, user1, user2] = await ethers.getSigners();

    const BondingCurveToken = await ethers.getContractFactory("BondingCurveToken");
    const bondingCurveToken = await BondingCurveToken.deploy("name", "symbol", 2, 1, COOL_DOWN_PERIOD);

    return { bondingCurveToken, owner, user1, user2 };
  }

  describe("Purchasing", function () {
    it("Should have correct price initially", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const user1InitialBalance = await ethers.provider.getBalance(user1);
      const quantity = 1e3;
      const cost = 1e6 + 1e3;
      const tx = await bondingCurveToken.connect(user1).buy(quantity, { value: cost });
      const txReceipt = await tx.wait();
      if (txReceipt == null) {
        throw Error("Tx receipt is null");
      }
      expect(await bondingCurveToken.balanceOf(user1)).to.equal(quantity);
      const gasSpend = txReceipt.gasPrice * txReceipt.gasUsed;
      expect(await ethers.provider.getBalance(user1)).to.equal(user1InitialBalance - BigInt(cost) - gasSpend);
    });

    it("Should not permit purchase with insufficient funds", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      await expect(
        bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 + 1e3 - 1 })
      ).to.be.revertedWith("BondingCurveToken: Insufficient funds");
    });

    it("Should send refund", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const user1InitialBalance = await ethers.provider.getBalance(user1);
      const quantity = 1e3;
      const cost = 1e6 + 1e3;
      const tx = await bondingCurveToken.connect(user1).buy(quantity, { value: cost + 1 });
      const txReceipt = await tx.wait();
      if (txReceipt == null) {
        throw Error("Tx receipt is null");
      }
      expect(await bondingCurveToken.balanceOf(user1)).to.equal(quantity);
      const gasSpend = txReceipt.gasPrice * txReceipt.gasUsed;
      expect(await ethers.provider.getBalance(user1)).to.equal(user1InitialBalance - BigInt(cost) - gasSpend);
    });

    it("Should update price after one purchase", async function() {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      await expect(bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 + 1e3 })).to.not.be.reverted;
      await expect(bondingCurveToken.connect(user1).buy(1, { value: 2e3 + 2 })).to.not.be.reverted;
      expect(await bondingCurveToken.balanceOf(user1)).to.equal(1e3 + 1);
    });
  });

  describe("Selling", function() {
    it("Should allow selling up to maximum available supply", async function () {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const user1InitialBalance = await ethers.provider.getBalance(user1);
      const buyTx = await bondingCurveToken.connect(user1).buy(1e3, { value: 1e6 + 1e3 });
      const buyTxReceipt = await buyTx.wait();
      if (buyTxReceipt == null) {
        throw Error("Tx receipt is null");
      }
      await time.increase(COOL_DOWN_PERIOD + 1);
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

      const quantity = 1e3;
      const cost = 1e6 + 1e3;
      await expect(bondingCurveToken.connect(user1).buy(quantity, { value: cost })).to.not.be.reverted;
      await time.increase(COOL_DOWN_PERIOD + 1);
      await expect(bondingCurveToken.connect(user1).sell(quantity, cost + 1)).to.be.reverted;
    });

    it("Should not permit selling before cooldown period is over", async function() {
      const { bondingCurveToken, user1 } = await loadFixture(deployBondingCurveTokenFixture);

      const quantity = 1e3;
      const cost = 1e6 + 1e3;
      await expect(bondingCurveToken.connect(user1).buy(quantity, { value: cost })).to.not.be.reverted;
      await expect(
        bondingCurveToken.connect(user1).sell(quantity, cost + 1)
      ).to.be.revertedWith("BondingCurveToken: Can only sell after the cooldown");
    });
  });
});
