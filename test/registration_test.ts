import { Contract, Interface, Signer } from "ethers";
import { ethers } from "hardhat";
import { BridgeContract, Withdraw, Proxy, Nexus } from "../typechain";
const { expect } = require("chai");

describe("registration test", function () {
  let owner: Signer, rollupAdmin: Signer, user1: Signer;
  let bridgeContract: BridgeContract,
    nexus: Nexus,
    NexusImplementation: Interface,
    withdraw: Withdraw,
    nexusProxy: Proxy;
  before(async function () {
    [rollupAdmin, user1] = await ethers.getSigners();
    owner = await ethers.getImpersonatedSigner("0xBEfBf15cac02B1cB30dADb1AA4CfA181E26DBfA1")
    console.log("owner address", await owner.getAddress());
    console.log("rollup admin address", await rollupAdmin.getAddress());
    console.log("user address", await user1.getAddress());
    const NexusContract = await ethers.getContractFactory("Nexus");
    NexusImplementation = NexusContract.interface;
    const nexusImpl = await NexusContract.deploy();
    console.log("nexus implementation deployed:", await nexusImpl.getAddress());
    const NexusProxy = await ethers.getContractFactory("Proxy");
    nexusProxy = await NexusProxy.deploy(
      NexusImplementation.encodeFunctionData("initialize", []),
      await nexusImpl.getAddress()
    );
    console.log("nexus proxy deployed:", await nexusProxy.getAddress());
    const BridgeContract = await ethers.getContractFactory("BridgeContract");
    bridgeContract = await BridgeContract.deploy(await nexusProxy.getAddress());
    console.log("bridge contract for rollup:", await bridgeContract.getAddress());
    nexus = await NexusContract.attach(await nexusProxy.getAddress());
    console.log(await nexus.getOwner());
  });
  describe("Rollup Registration", function () {
    it("should whitelist rollup", async function () {
      await nexus.whitelistRollup("nexus", await rollupAdmin.getAddress());
      await expect(
        nexus
          .connect(user1)
          .whitelistRollup("nexus", await rollupAdmin.getAddress())
      ).to.be.revertedWithCustomError(nexus, "NotOwner");
      await expect(
        nexus.whitelistRollup("nexus", await rollupAdmin.getAddress())
      ).to.be.revertedWithCustomError(nexus, "AddressAlreadyWhitelisted");
    });
    it("should register rollup", async function () {
      // await nexus.whitelistRollup("nexus", await rollupAdmin.getAddress());
      const BridgeContract_2 = await ethers.getContractFactory("BridgeContract");
      const bridgeContract_wrong = await BridgeContract_2.deploy(await user1.getAddress());
      await expect(nexus
        .connect(rollupAdmin)
        .registerRollup(
          await bridgeContract_wrong.getAddress(),
          1,
          1000
        )).to.be.revertedWithCustomError(nexus,"NexusAddressNotFound");
      await nexus
        .connect(rollupAdmin)
        .registerRollup(
          await bridgeContract.getAddress(),
          1,
          1000
        );
      await expect(nexus
        .connect(rollupAdmin)
        .registerRollup(
          await bridgeContract.getAddress(),
          1,
          1000
        )).to.be.revertedWithCustomError(nexus,"RollupAlreadyRegistered");
      const BridgeContract = await ethers.getContractFactory("BridgeContract");
      bridgeContract = await BridgeContract.deploy(await nexusProxy.getAddress());
      // const Withdraw = await ethers.getContractFactory("Withdraw");
      // withdraw = await Withdraw.attach(
      //   (
      //     await nexus.rollups(await rollupAdmin.getAddress())
      //   ).withdrawalAddress
      // );

      await expect(
        nexus
          .connect(user1)
          .registerRollup(
            await bridgeContract.getAddress(),
            1,
            1000
          )
      ).to.be.revertedWithCustomError(nexus, "AddressNotWhitelisted");
    });
    // it("deployed withdrawal contract should have correct params", async function () {
    //   await expect(await withdraw.DAO_ADDRESS()).to.be.equal(
    //     await rollupAdmin.getAddress()
    //   );
    //   await expect(await withdraw.nexusShare()).to.be.equal(1000);
    //   await expect(await withdraw.NEXUS_CONTRACT()).to.be.equal(await nexus.getAddress());
    // });
    it("should change staking limit", async function () {
      await expect(
        (
          await nexus.rollups(await rollupAdmin.getAddress())
        ).stakingLimit
      ).to.be.equal(1000);
      await nexus.connect(rollupAdmin).changeStakingLimit(2000);
      await expect(
        (
          await nexus.rollups(await rollupAdmin.getAddress())
        ).stakingLimit
      ).to.be.equal(2000);
    });
    it("should add cluster", async function () {
      const cluster = [1,5,7,11];
      await nexus.addCluster(cluster,1)
      await expect(nexus.connect(user1).addCluster(cluster,1)).to.be.revertedWithCustomError(nexus, "NotOwner")
      await expect((await nexus.getCluster(1)).toString()).to.be.equal(cluster.toString());
    });
    it("should send SSV to nexus Contract", async function (){
      const SSVToken = await ethers.getContractFactory("SSVToken");
      const ssv = await SSVToken.attach("0x3a9f01091C446bdE031E39ea8354647AFef091E7");
      const tokenHolder = await ethers.getImpersonatedSigner("0x929C3Ed3D1788C4862E6b865E0E02500DB8Fd760");
      await ssv.connect(tokenHolder).approve(await nexus.getAddress(),ethers.parseEther("1000"));
      await nexus.connect(tokenHolder).rechargeSSV(ethers.parseEther("1000"));
      await expect(await ssv.balanceOf(await nexus.getAddress())).to.be.equal(ethers.parseEther("1000"))
    });
  });
});
