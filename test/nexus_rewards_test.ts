import { Contract, Interface, Signer, parseEther } from "ethers";
import { ethers } from "hardhat";
import { NexusRewards } from "../typechain";
const { expect } = require("chai");
describe("Execution Reward test", function () {
    let transaction_bot: Signer, rollupAdmin: Signer, notrollupAdmin: Signer, MEV: Signer;
    let reward: NexusRewards;
    before(async function () {
        [transaction_bot, rollupAdmin, notrollupAdmin,MEV] = await ethers.getSigners();
        const Reward = await ethers.getContractFactory("NexusRewards");
        reward = await Reward.deploy(await transaction_bot.getAddress());
        console.log("rewards contract deployed:", await reward.getAddress());
    })
    it("should receive execution rewards", async function () {
        await MEV.sendTransaction({
            to: await reward.getAddress(),
            value: parseEther("5")
        })
        await expect(await reward.rewardsEarned()).to.be.equal(parseEther("5"))
    });
    it("bot should update execution rewards for the rollup",async function () {
        const rollupRewardIncorrect: NexusRewards.RollupExecutionRewardStruct[] = [{rollupAdmin:await rollupAdmin.getAddress(), amount: parseEther("20")}];
        const rollupReward: NexusRewards.RollupExecutionRewardStruct[] = [{rollupAdmin:await rollupAdmin.getAddress(), amount: parseEther("2")}];
        await expect(reward.updateRewardsRollup(rollupRewardIncorrect)).to.be.revertedWithCustomError(reward,"IncorrectRewards");
        await expect(reward.connect(notrollupAdmin).updateRewardsRollup(rollupRewardIncorrect)).to.be.revertedWithCustomError(reward,"NotRewardBot");
        await reward.updateRewardsRollup(rollupReward);
        await expect(await reward.executionRewards(await rollupAdmin.getAddress())).to.be.equal(parseEther("2"))
    });
    it("rollupadmin should be able to claim rewards", async function () {
        await expect(reward.claimRewards()).to.be.revertedWithCustomError(reward,"RewardNotPresent");
        await reward.connect(rollupAdmin).claimRewards();
        await expect(await ethers.provider.getBalance(await reward.getAddress())).to.be.equal(parseEther("3"))
        await expect(await reward.executionRewards(await rollupAdmin.getAddress())).to.be.equal(parseEther("0"))
    })
})
