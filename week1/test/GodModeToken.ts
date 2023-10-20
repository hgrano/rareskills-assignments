import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("GodModeToken", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployGodModeTokenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2] = await ethers.getSigners();

    const GodModeToken = await ethers.getContractFactory("GodModeToken");
    const godModeToken = await GodModeToken.deploy("name", "symbol", owner, "1000");
    await godModeToken.transfer(user1, "1000");

    return { godModeToken, owner, user1, user2 };
  }

  describe("Transfers", function () {
    it("Should only admin to force transfer", async function () {
      const { godModeToken, owner, user1, user2 } = await loadFixture(
        deployGodModeTokenFixture
      );

      const transferAmount = 10;
      await expect(godModeToken.connect(user2).transferFrom(user1, user2, transferAmount)).to.be.reverted;
    });

    it("Should allow admin to force transfer", async function () {
      const { godModeToken, owner, user1, user2 } = await loadFixture(
        deployGodModeTokenFixture
      );

      const initialBalance = await godModeToken.balanceOf(user1);
      const transferAmount = 10n;
      await expect(godModeToken.transferFrom(user1, user2, transferAmount)).not.to.be.reverted;
      expect(await godModeToken.balanceOf(user2)).to.equal(transferAmount);
      expect(await godModeToken.balanceOf(user1)).to.equal(initialBalance - transferAmount);
    });
  });
});
