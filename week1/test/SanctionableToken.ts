import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
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

  // describe("Deployment", function () {
    // it("Should set the right unlockTime", async function () {
    //   const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);

    //   expect(await lock.unlockTime()).to.equal(unlockTime);
    // });

    // it("Should set the right owner", async function () {
    //   const { lock, owner } = await loadFixture(deployOneYearLockFixture);

    //   expect(await lock.owner()).to.equal(owner.address);
    // });

    // it("Should receive and store the funds to lock", async function () {
    //   const { lock, lockedAmount } = await loadFixture(
    //     deployOneYearLockFixture
    //   );

    //   expect(await ethers.provider.getBalance(lock.target)).to.equal(
    //     lockedAmount
    //   );
    // });

    // it("Should fail if the unlockTime is not in the future", async function () {
    //   // We don't use the fixture here because we want a different deployment
    //   const latestTime = await time.latest();
    //   const Lock = await ethers.getContractFactory("Lock");
    //   await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //     "Unlock time should be in the future"
    //   );
    // });
  // });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

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

  describe("Sanctioning", function () {
    it("Should not allow anyone except owner to sanction", async function () {
      const { sanctionableToken, owner, user1, user2 } = await loadFixture(
        deploySanctionableTokenFixture
      );

      await expect(sanctionableToken.connect(user1).sanction(user2)).to.be.reverted;
    });
  });
});
