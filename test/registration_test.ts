import { Contract, Signer } from "ethers";
import { Interface } from "ethers/lib/utils";
import { ethers } from "hardhat";
// const { expect } = require("chai");

describe("registration test", function () {
  let owner: Signer, rollupAdmin: Signer, user1: Signer;
  let bridgeContract: Contract,
    nexus: Contract,
    NexusImplementation: Interface,
    // withdraw: Contract,
    nexusProxy: Contract;
  before(async function () {
    [owner, rollupAdmin, user1] = await ethers.getSigners();
    console.log("owner address", await owner.getAddress());
    console.log("user address", await user1.getAddress());
    const Nexus = await ethers.getContractFactory("Nexus");
    NexusImplementation = Nexus.interface;
    const nexusImpl = await Nexus.deploy();
    console.log("implementation deployed to", nexusImpl.address)
    const BridgeContract = await ethers.getContractFactory("BridgeContract");
    bridgeContract = await BridgeContract.deploy();
    console.log("bridge contract", bridgeContract.address);
    const NexusProxy = await ethers.getContractFactory("Proxy");
    nexusProxy = await NexusProxy.deploy(
      NexusImplementation.encodeFunctionData("initialize", []),
      nexusImpl.address
    );
    console.log("proxy deployed to", nexusProxy.address);
    nexus = await Nexus.attach(nexusProxy.address);
    console.log(await nexus.getOwner());
  });
  it("should whitelist rollup", async function () {
    await nexus.whitelistRollup("nexus", await rollupAdmin.getAddress());
  });
});
