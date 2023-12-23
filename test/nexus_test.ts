import { Contract, Interface, Signer, parseEther } from "ethers";
import { ethers } from "hardhat";
import { Proxy, Nexus, SSVToken,NodeOperator } from "../typechain";
import { BridgeContractDAO } from "../typechain/contracts/demo_contracts/BridgeContractDAO.sol";
const { expect } = require("chai");

describe("nexus test", function () {
  let owner: Signer, rollupAdmin1: Signer, notRollupAdmin: Signer,userRollup:Signer;
  let bridgeContractDAO: BridgeContractDAO,
    nexus: Nexus,
    NexusImplementation: Interface,
    nexusProxy: Proxy,
    nodeOperator: NodeOperator;
  before(async function () {
    [owner,rollupAdmin1, notRollupAdmin, userRollup] = await ethers.getSigners();
    console.log("owner address", await owner.getAddress());
    console.log("rollup admin address", await rollupAdmin1.getAddress());
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
    nexus = await NexusContract.attach(await nexusProxy.getAddress());
  });
  describe("Rollup functionalities", function () {
    before(async function () {
      const BridgeContract = await ethers.getContractFactory("BridgeContractDAO");
      bridgeContractDAO = await BridgeContract.deploy(await nexus.getAddress(), parseEther("1000"),parseEther("800"),0,0,0,1000)
      console.log("bridge contract deployd to:", await bridgeContractDAO.getAddress());
      const NopeOperatorContract = await ethers.getContractFactory("NodeOperator");
      nodeOperator = await NopeOperatorContract.deploy();
      await nodeOperator.initialize();
      await nodeOperator.registerSSVOperator(1,"test","http://127.0.0.1:8787","nexus_1");
      await nodeOperator.registerSSVOperator(2,"test2","http://127.0.0.1:8787","nexus_1");
      await nodeOperator.registerSSVOperator(3,"test3","http://127.0.0.1:8787","nexus_1");
      await nodeOperator.registerSSVOperator(4,"test4","http://127.0.0.1:8787","nexus_1");
      await nodeOperator.addCluster([1,2,3,4],1);
      await nexus.setNodeOperatorContract(await nodeOperator.getAddress())

    });
    it("should whitelist rollup", async function () {
      await nexus.whitelistRollup("nexus", await rollupAdmin1.getAddress());
      await expect(
        nexus
          .connect(notRollupAdmin)
          .whitelistRollup("nexus", await rollupAdmin1.getAddress())
      ).to.be.revertedWithCustomError(nexus, "NotOwner");
      await expect(
        nexus.whitelistRollup("nexus", await rollupAdmin1.getAddress())
      ).to.be.revertedWithCustomError(nexus, "AddressAlreadyWhitelisted");
    });
    it("should register rollup", async function () {
      await expect(nexus.registerRollup(await bridgeContractDAO.getAddress(),1,1000,1000)).to.be.revertedWithCustomError(nexus,"AddressNotWhitelisted");
      const BridgeContract = await ethers.getContractFactory("BridgeContractDAO");
      const wrongbridgeContractDAO = await BridgeContract.deploy(await userRollup.getAddress(), parseEther("1000"),parseEther("800"),0,0,0,1000)
      await expect(nexus.connect(rollupAdmin1).registerRollup(await bridgeContractDAO.getAddress(),1,1000,30000)).to.be.revertedWithCustomError(nexus,"IncorrectStakingLimit");
      await expect(nexus.connect(rollupAdmin1).registerRollup(await bridgeContractDAO.getAddress(),1,5000,1000)).to.be.revertedWithCustomError(bridgeContractDAO,"IncorrectNexusFee");
      await expect(nexus.connect(rollupAdmin1).registerRollup(await wrongbridgeContractDAO.getAddress(),1,1000,1000)).to.be.revertedWithCustomError(nexus,"NexusAddressNotFound");
      await expect(nexus.connect(rollupAdmin1).registerRollup(await bridgeContractDAO.getAddress(),4,1000,1000)).to.be.revertedWithCustomError(nodeOperator,"ClusterNotPresent");
      await nexus.connect(rollupAdmin1).registerRollup(await bridgeContractDAO.getAddress(),1,1000,1000);
      await expect(nexus.connect(rollupAdmin1).registerRollup(await bridgeContractDAO.getAddress(),1,1000,1000)).to.be.revertedWithCustomError(nexus,"RollupAlreadyRegistered");

    });
    it("should change staking limit", async function () {
      await expect(
        (
          await nexus.rollups(await rollupAdmin1.getAddress())
        ).stakingLimit
      ).to.be.equal(1000);
      await nexus.connect(rollupAdmin1).changeStakingLimit(2000);
      await expect(
        (
          await nexus.rollups(await rollupAdmin1.getAddress())
        ).stakingLimit
      ).to.be.equal(2000);
    });
    it("should change nexus fee limit",async function () {
      await expect(nexus.changeNexusFee(2000)).to.be.revertedWithCustomError(nexus,"AddressNotWhitelisted")
      await expect(nexus.connect(rollupAdmin1).changeNexusFee(2000)).to.be.revertedWithCustomError(bridgeContractDAO,"IncorrectNexusFee")
      await nexus.connect(rollupAdmin1).changeNexusFee(500);
    });
    it("should change cluster ",async function () {
      await expect(nexus.changeCluster(2)).to.be.revertedWithCustomError(nexus,"AddressNotWhitelisted")
      await expect(nexus.connect(rollupAdmin1).changeCluster(2000)).to.be.revertedWithCustomError(nodeOperator,"ClusterNotPresent");
      await nodeOperator.addCluster([2,3,4],2);
      await nexus.connect(rollupAdmin1).changeCluster(2);
    });
  });
  it("should send SSV to nexus Contract", async function () {
    const SSVToken = await ethers.getContractFactory("SSVToken");
    const ssv:SSVToken = await SSVToken.attach("0x3a9f01091C446bdE031E39ea8354647AFef091E7");
    const tokenHolder = await ethers.getImpersonatedSigner("0x929C3Ed3D1788C4862E6b865E0E02500DB8Fd760");
    await ssv.connect(tokenHolder).transfer(await nexus.getAddress(), ethers.parseEther("1000"));
    await expect(await ssv.balanceOf(await nexus.getAddress())).to.be.equal(ethers.parseEther("1000"))
  });
});
