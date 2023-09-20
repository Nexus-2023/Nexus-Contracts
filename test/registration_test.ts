import { Contract, Signer, wordlists } from "ethers";
import { Interface } from "ethers/lib/utils";
import { ethers } from "hardhat";
const { expect } = require("chai");

describe("registration test", function () {
  let owner: Signer, rollupAdmin: Signer, user1: Signer;
  let bridgeContract: Contract,
    nexus: Contract,
    NexusImplementation: Interface,
    withdraw: Contract,
    nexusProxy: Contract;
  before(async function () {
    [owner, rollupAdmin, user1] = await ethers.getSigners();
    console.log("owner address", await owner.getAddress());
    console.log("rollup admin address", await rollupAdmin.getAddress());
    console.log("user address", await user1.getAddress());
    const Nexus = await ethers.getContractFactory("Nexus");
    NexusImplementation = Nexus.interface;
    const nexusImpl = await Nexus.deploy();
    console.log("nexus implementation deployed:", nexusImpl.address);
    const NexusProxy = await ethers.getContractFactory("Proxy");
    nexusProxy = await NexusProxy.deploy(
      NexusImplementation.encodeFunctionData("initialize", []),
      nexusImpl.address
    );
    console.log("nexus proxy deployed:", nexusProxy.address);
    const BridgeContract = await ethers.getContractFactory("BridgeContract");
    bridgeContract = await BridgeContract.deploy(nexusProxy.address);
    console.log("bridge contract for rollup:", bridgeContract.address);
    nexus = await Nexus.attach(nexusProxy.address);
    console.log(await nexus.getOwner());
  });
  describe("Rollup Registration", function () {
    it("should whitelist rollup", async function () {
      await nexus.whitelistRollup("nexus", await rollupAdmin.getAddress());
      await expect(
        nexus
          .connect(user1)
          .whitelistRollup("nexus", await rollupAdmin.getAddress())
      ).to.be.revertedWith("NotOwner");
      await expect(
        nexus.whitelistRollup("nexus", await rollupAdmin.getAddress())
      ).to.be.revertedWith("AddressAlreadyWhitelisted");
    });
    it("should register rollup", async function () {
      // await nexus.whitelistRollup("nexus", await rollupAdmin.getAddress());
      await nexus
        .connect(rollupAdmin)
        .registerRollup(
          bridgeContract.address,
          1,
          10,
          await rollupAdmin.getAddress()
        );
      const Withdraw = await ethers.getContractFactory("Withdraw");
      withdraw = await Withdraw.attach(
        (
          await nexus.rollups(await rollupAdmin.getAddress())
        ).withdrawalAddress
      );

      await expect(
        nexus
          .connect(user1)
          .registerRollup(
            bridgeContract.address,
            1,
            10,
            await rollupAdmin.getAddress()
          )
      ).to.be.revertedWith("AddressNotWhitelisted");
    });
    it("deployed withdrawal contract should have correct params", async function () {
      await expect(await withdraw.DAO_ADDRESS()).to.be.equal(
        await rollupAdmin.getAddress()
      );
      await expect(await withdraw.nexusShare()).to.be.equal(1000);
      await expect(await withdraw.NEXUS_CONTRACT()).to.be.equal(nexus.address);
    });
    it("should change staking limit", async function () {
      await expect(
        (
          await nexus.rollups(await rollupAdmin.getAddress())
        ).stakingLimit
      ).to.be.equal(10);
      await nexus.connect(rollupAdmin).changeStakingLimit(20);
      await expect(
        (
          await nexus.rollups(await rollupAdmin.getAddress())
        ).stakingLimit
      ).to.be.equal(20);
    });
  });
  describe("Validator Management", function () {
    const validators:Validat = []
    const validator_shares = []
    before(async function () {
      await user1.sendTransaction({
        to: bridgeContract.address,
        value: ethers.utils.parseEther("2000"),
      });
    });
    it("should deposit validator to bridge", async function () {
      
      await 
    });
  })
});
