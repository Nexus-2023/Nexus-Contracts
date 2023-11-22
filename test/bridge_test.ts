import { Signer, parseEther, getAddress } from "ethers";
import { ethers } from "hardhat";
import { NexusBridge } from "../typechain";
import { INexusInterface } from "../typechain/contracts/Nexus";
const { expect } = require("chai");

describe("bridge test", function () {
    let nexus: Signer, user1: Signer;
    let bridgeContract: NexusBridge;
    let withdrawalAddress: string;
    before(async function () {
        [nexus, user1] = await ethers.getSigners();
        withdrawalAddress = await getAddress("0x44449d7ca8e3724cb9c9e30ce49b286e275d79bf");
        const BridgeContract = await ethers.getContractFactory("BridgeContract");
        bridgeContract = await BridgeContract.deploy(await nexus.getAddress());
        console.log("bridge contract for rollup:", await bridgeContract.getAddress());
    });
    // it("nexus should add withdrawal address", async () => {
    //     await bridgeContract.setWithdrawal(withdrawalAddress);
    //     await expect(await bridgeContract.withdrawalCrendentails()).to.be.equal(
    //         withdrawalAddress
    //     );
    //     await expect(
    //         bridgeContract.connect(user1).setWithdrawal(await user1.getAddress())
    //     ).to.be.revertedWithCustomError(bridgeContract, "NotNexus");
    // });
    it("nexus should deposit keys", async () => {
        await user1.sendTransaction({
            to: await bridgeContract.getAddress(),
            value: parseEther("500"),
        });
        const validatorsWrong: INexusInterface.ValidatorStruct[] = [{ pubKey: "0xb6165000715f5a684fb6f158e6362cc9a2b47d0e07b999dad982bd0f4fef977a5a8c3d1a99a9f85ac7599f508d15a6dd", withdrawalAddress: "0x010000000000000000000000c71bdeb1e87cdeb289da8e23ef9b7f6d9353b9d8", signature: "0x817690edc28f4b897a98c23f09f7262911c7a10001d30008166aa9787d48b80eb6cbf601370b5fcdb5fda7849626fe0201d8d36194e62870a6925cde1f0f0a4180854690d1ef514bb63c1b4556c6e8f73cb70cd46cc7cf16dea27bd13a6df751", depositRoot: "0x96bfd6193ed989087655bb65ae15d0c5c4185bcaa0fcffe2644cc285a768236b" }]
        await expect(bridgeContract.connect(user1).depositValidatorNexus(validatorsWrong, 1000, 0)).to.be.revertedWithCustomError(bridgeContract,"NotNexus");
        await expect(bridgeContract.depositValidatorNexus(validatorsWrong, 1000, 0)).to.be.revertedWithCustomError(bridgeContract,"IncorrectWithdrawalCredentials");
        const validators: INexusInterface.ValidatorStruct[] = [{ pubKey: "0x90721017cd2d518ee0ca5a4281593f2537a3e24126e0e56812eaf0e953d7d3465cd06c213969c1bbc88c62f610ea31bd", withdrawalAddress: "0x01000000000000000000000044449d7ca8e3724cb9c9e30ce49b286e275d79bf", signature: "0x97a2b61e747c596d8f3a675c08498c8f906de18378d09900ce5c21970d95e1aec8aba64e30f6fc16219ced98b4598ffa0ad7d84f7ce88c3dcef35c132e7d3686966441183f932d6f6b612988784091a24ca37202512e4141bd89e05bfc7ae06a", depositRoot: "0xa554ddd43b49a9a8537e2e1f448ce5ad66565656ed2cb56f71a51fb1e0d43663" },
        { pubKey: "0xb6165000715f5a684fb6f158e6362cc9a2b47d0e07b999dad982bd0f4fef977a5a8c3d1a99a9f85ac7599f508d15a6dd", withdrawalAddress: "0x01000000000000000000000044449d7ca8e3724cb9c9e30ce49b286e275d79bf", signature: "0x817690edc28f4b897a98c23f09f7262911c7a10001d30008166aa9787d48b80eb6cbf601370b5fcdb5fda7849626fe0201d8d36194e62870a6925cde1f0f0a4180854690d1ef514bb63c1b4556c6e8f73cb70cd46cc7cf16dea27bd13a6df751", depositRoot: "0x96bfd6193ed989087655bb65ae15d0c5c4185bcaa0fcffe2644cc285a768236b" }]
        await expect(bridgeContract.depositValidatorNexus(validators, 1000, 0)).to.be.revertedWithCustomError(bridgeContract,"StakingLimitExceeding");
        await bridgeContract.depositValidatorNexus([validators[1]], 1000, 0);
    });
    it("withdrawal contract should send validator exit deposits", async () => {
        const BridgeContract = await ethers.getContractFactory("BridgeContract");
        const bridgeContract2 = await BridgeContract.deploy(await nexus.getAddress());
        await bridgeContract2.setWithdrawal(await nexus.getAddress());
        await expect(bridgeContract2.connect(user1).validatorExit({value:parseEther("10")})).to.be.revertedWithCustomError(bridgeContract,"IncorrectWithdrawalAddress");
        await bridgeContract2.validatorExit({value:parseEther("10")});
    });
});
