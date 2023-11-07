import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const THREE_DAYS_IN_SECS = 3 * 24 * 60 * 60;

describe("UntrustedEscrow", function () {
  async function deployUntrustedEscrowFixture() {
    const [deployer, user1, user2, user3] = await ethers.getSigners();

    const UntrustedEscrow = await ethers.getContractFactory("UntrustedEscrow");
    const untrustedEscrow = await UntrustedEscrow.deploy();

    const BasicERC20 = await ethers.getContractFactory("BasicERC20");
    const basicERC20 = await BasicERC20.deploy(10000, user1);

    const FeeOnTransfer = await ethers.getContractFactory("FeeOnTranserToken");
    const feeOnTransfer = await FeeOnTransfer.deploy(5);
    await feeOnTransfer.mint(user1, 1000);
    await feeOnTransfer.mint(user2, 1000)

    return { untrustedEscrow, basicERC20, feeOnTransfer, user1, user2, user3 };
  }

  describe("Escrowing", function () {
    it("Should allow withdawal after 3 days", async function () {
      const { untrustedEscrow, basicERC20, user1, user2 } = await loadFixture(deployUntrustedEscrowFixture);
      const escrowId = 0;
      const value = 10;
      await expect(basicERC20.connect(user1).approve(untrustedEscrow, value)).to.not.be.reverted;
      await expect(untrustedEscrow.connect(user1).escrow(escrowId, basicERC20, user2, value)).to.not.be.reverted;
      const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECS;
      await expect(
        untrustedEscrow.connect(user2).withdraw(escrowId)
      ).to.be.revertedWith("UntrustedEscrow: can only withdraw after the unlock time");
      await time.increaseTo(unlockTime);
      await expect(untrustedEscrow.connect(user2).withdraw(escrowId)).to.changeTokenBalances(
        basicERC20,
        [untrustedEscrow, user2],
        [-value, value]
      );
    });

    it("Should work with fee on transfer token", async function () {
      const { untrustedEscrow, feeOnTransfer, user1, user2 } = await loadFixture(deployUntrustedEscrowFixture);

      const escrowId = 0;
      // A 5% fee on a transfer of 120 is 6, meaning we can escrow a total of 120 - 6 = 114
      const value = 114;
      const fee = 6;

      await feeOnTransfer.connect(user1).approve(untrustedEscrow, value + fee);
      await expect(
        untrustedEscrow.connect(user1).escrow(escrowId, feeOnTransfer, user2, value + fee)
      ).to.not.be.reverted;
      const unlockTime = (await time.latest()) + THREE_DAYS_IN_SECS;
      await time.increaseTo(unlockTime);
      await expect(untrustedEscrow.connect(user2).withdraw(escrowId)).to.changeTokenBalances(
        feeOnTransfer,
        [untrustedEscrow, user2],
        [-value, value - 5]
      );
    });
  });
});
