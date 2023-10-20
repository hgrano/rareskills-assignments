import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SanctionableToken", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deploySanctionableTokenFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2] = await ethers.getSigners();

    const SanctionableToken = await ethers.getContractFactory("SanctionableToken");
    const sanctionableToken = await SanctionableToken.deploy("name", "symbol", owner, "1000");

    return { sanctionableToken, owner, user1, user2 };
  }

  describe("Transfers", function () {
    it("Should allow transfers to addresses which are not sanctioned", async function () {
      const { sanctionableToken, owner, user1, user2 } = await loadFixture(
        deploySanctionableTokenFixture
      );

      const transferAmount = 10;
      await expect(sanctionableToken.transfer(user1, transferAmount)).not.to.be.reverted;
      expect(await sanctionableToken.balanceOf(user1)).to.equal(transferAmount);
    });

    it("Should not allow transfers to addresses which are sanctioned", async function () {
      const { sanctionableToken, owner, user1, user2 } = await loadFixture(
        deploySanctionableTokenFixture
      );

      await expect(sanctionableToken.sanction(user1)).not.to.be.reverted;

      const transferAmount = 10;
      await expect(sanctionableToken.transfer(user1, transferAmount))
        .to.be.revertedWith("SanctionableToken: cannot transfer to sanctioned address")
      expect(await sanctionableToken.balanceOf(user1)).to.equal(0);
    });

    it("Should not allow transfers from addresses which are sanctioned", async function () {
      const { sanctionableToken, owner, user1, user2 } = await loadFixture(
        deploySanctionableTokenFixture
      );

      const user1Balance = 100;
      await expect(sanctionableToken.transfer(user1, user1Balance)).not.to.be.reverted;
      await expect(sanctionableToken.sanction(user1)).not.to.be.reverted;

      await expect(sanctionableToken.connect(user1).transfer(user2, 10))
        .to.be.revertedWith("SanctionableToken: cannot transfer from sanctioned address")
      expect(await sanctionableToken.balanceOf(user1)).to.equal(user1Balance);
      expect(await sanctionableToken.balanceOf(user2)).to.equal(0);
    });

    it("Should allow transfers after sanctions have been lifted", async function () {
      const { sanctionableToken, owner, user1, user2 } = await loadFixture(
        deploySanctionableTokenFixture
      );

      await expect(sanctionableToken.sanction(user1)).not.be.reverted;
      await expect(sanctionableToken.unSanction(user1)).not.be.reverted;
      const transferAmount = 10;
      await expect(sanctionableToken.transfer(user1, transferAmount)).not.to.be.reverted;
      expect(await sanctionableToken.balanceOf(user1)).to.equal(transferAmount);
    });
  });

  // TODO test transferFrom, maybe also approve?

  describe("Sanctioning", function () {
    it("Should not allow anyone except owner to sanction", async function () {
      const { sanctionableToken, owner, user1, user2 } = await loadFixture(
        deploySanctionableTokenFixture
      );

      await expect(sanctionableToken.connect(user1).sanction(user2)).to.be.reverted;
    });
  });
});
