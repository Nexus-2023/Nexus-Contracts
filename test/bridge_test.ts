import { Signer, parseEther, toBigInt } from "ethers";
import { ethers } from "hardhat";
import { BridgeContractDAO, BridgeContractRebase, BridgeContractCValue } from "../typechain";
const { expect } = require("chai");

describe("bridge test", function () {
    let nexus: Signer, user1: Signer, user2:Signer,dao_address:Signer, nexus_fee:Signer;
    before(async function () {
        [nexus, user1 ,user2] = await ethers.getSigners();
        dao_address = await ethers.getImpersonatedSigner("0x14630e0428B9BbA12896402257fa09035f9F7447");
        nexus_fee = await ethers.getImpersonatedSigner("0x735bf02E4435dFADfE47a5FE5FBD42Ef375864A9")
    });
    describe("DAO bridge test",async function () {
        let bridgeContractDao: BridgeContractDAO;
        before(async function () {
            const BridgeContractDAO = await ethers.getContractFactory("BridgeContractDAO");
            const _amountDeposited = parseEther("2000");
            const _amountWithdrawn = parseEther("1100");
            const _slashedAmount = parseEther("1");
            const _rewardsClaimed = parseEther("4");
            const _validatorCount = 10;
            const _NexusFeePercentage = 1000;
            bridgeContractDao = await BridgeContractDAO.deploy(await nexus.getAddress(),_amountDeposited,_amountWithdrawn,_slashedAmount,_rewardsClaimed,_validatorCount,_NexusFeePercentage);
            console.log("dao bridge contract for rollup:", await bridgeContractDao.getAddress());
            await user1.sendTransaction({
                to: await bridgeContractDao.getAddress(),
                value: parseEther("582")
            })
        })
        it("should implement slashing", async function(){
            await expect(bridgeContractDao.connect(user1).validatorsSlashed(parseEther("1"))).to.be.revertedWithCustomError(bridgeContractDao,"NotNexus")
            await bridgeContractDao.validatorsSlashed(parseEther("1"));
            console.log(await bridgeContractDao.slashedAmount())
            await expect(await bridgeContractDao.slashedAmount()).to.be.equal(parseEther("1"))
        });
        it("should be able to claim his DAO rewards", async function(){
            const before_balance = await ethers.provider.getBalance(await user1.getAddress());
            const before_balance_nexus = await ethers.provider.getBalance(await nexus_fee.getAddress());
            await expect(bridgeContractDao.connect(user2).redeemRewards(await user1.getAddress())).to.be.revertedWithCustomError(bridgeContractDao,"NotDAO");
            await bridgeContractDao.connect(dao_address).redeemRewards(await user1.getAddress());
            await expect(await ethers.provider.getBalance(await user1.getAddress())).to.equal(before_balance+parseEther("0.9"))
            await expect(await ethers.provider.getBalance(await nexus_fee.getAddress())).to.equal(before_balance_nexus+parseEther("0.1"))
        });
        it("should be able to update exited validators", async function(){
            await expect(bridgeContractDao.connect(user1).updateExitedValidators()).to.be.revertedWithCustomError(bridgeContractDao,"NotNexus");
            await expect(bridgeContractDao.updateExitedValidators()).to.be.revertedWithCustomError(bridgeContractDao,"ValidatorNotExited");
            await user1.sendTransaction({
                to: await bridgeContractDao.getAddress(),
                value: parseEther("632")
            })
            await expect(bridgeContractDao.connect(dao_address).redeemRewards(await user1.getAddress())).to.be.revertedWithCustomError(bridgeContractDao,"WaitingForValidatorExits");
            await bridgeContractDao.updateExitedValidators();
            await expect(await bridgeContractDao.validatorCount()).to.be.equal(9)
        });
    });
    describe("Rebase bridge address",async function () {
        let bridgeContractRebase: BridgeContractRebase;
        let _amountDistributed: bigint;
        before(async function () {
            const BridgeContractRebase = await ethers.getContractFactory("BridgeContractRebase");
            const _amountDeposited = parseEther("2000");
            const _amountWithdrawn = parseEther("1100");
            const _slashedAmount = parseEther("1");
            _amountDistributed = parseEther("4");
            const _validatorCount = 10;
            const _NexusFeePercentage = 1000;
            const balanceToSend = 582;
            bridgeContractRebase = await BridgeContractRebase.deploy(await nexus.getAddress(),_amountDeposited,_amountWithdrawn,_slashedAmount,_amountDistributed,_validatorCount,_NexusFeePercentage);
            console.log("Rebase bridge contract for rollup:", await bridgeContractRebase.getAddress());
            await user1.sendTransaction({
                to: await bridgeContractRebase.getAddress(),
                value: parseEther("586")
            })
        });
        it("should implement slashing", async function(){
            await expect(bridgeContractRebase.connect(user1).validatorsSlashed(parseEther("1"))).to.be.revertedWithCustomError(bridgeContractRebase,"NotNexus")
            await bridgeContractRebase.validatorsSlashed(parseEther("1"));
            await expect(await bridgeContractRebase.slashedAmount()).to.be.equal(parseEther("1"))
        });
        it("should rebase tokens",async function () {
            const before_balance_nexus = await ethers.provider.getBalance(await nexus_fee.getAddress());
            await expect(bridgeContractRebase.rebase()).to.emit(bridgeContractRebase,"RebaseAmount").withArgs(parseEther("0.9"))
            await expect(await ethers.provider.getBalance(await nexus_fee.getAddress())).to.equal(before_balance_nexus+parseEther("0.1"))
            await expect(await bridgeContractRebase.amountDistributed()).to.equal(_amountDistributed+parseEther("0.9"))
        });
        it("should be able to update exited validators", async function(){
            await expect(bridgeContractRebase.connect(user1).updateExitedValidators()).to.be.revertedWithCustomError(bridgeContractRebase,"NotNexus");
            await expect(bridgeContractRebase.updateExitedValidators()).to.be.revertedWithCustomError(bridgeContractRebase,"ValidatorNotExited");
            await user1.sendTransaction({
                to: await bridgeContractRebase.getAddress(),
                value: parseEther("632")
            })
            await expect(bridgeContractRebase.rebase()).to.be.revertedWithCustomError(bridgeContractRebase,"WaitingForValidatorExits");
            await bridgeContractRebase.updateExitedValidators();
            await expect(await bridgeContractRebase.validatorCount()).to.be.equal(9)
        });

    });
    describe("C Token bridge address",async function () {
        let bridgeContractCValue: BridgeContractCValue;
        let  _amountDeposited:bigint,
        _amountWithdrawn:bigint,
        _slashedAmount:bigint,
        _amountDistributed:bigint;
        before(async function () {
            _amountDeposited = parseEther("2000");
            _amountWithdrawn = parseEther("1100");
            _slashedAmount = parseEther("1");
            _amountDistributed = parseEther("4");
            const _validatorCount = 10;
            const _NexusFeePercentage = 1000;
            const BridgeContractCValue = await ethers.getContractFactory("BridgeContractCValue");
            bridgeContractCValue = await BridgeContractCValue.deploy(await nexus.getAddress(),_amountDeposited,_amountWithdrawn,_slashedAmount,_amountDistributed,_validatorCount,_NexusFeePercentage);
            console.log("CValue bridge contract for rollup:", await bridgeContractCValue.getAddress());
            await user1.sendTransaction({
                to: await bridgeContractCValue.getAddress(),
                value: parseEther("586")
            })
        })
        it("should implement slashing", async function(){
            await expect(bridgeContractCValue.connect(user1).validatorsSlashed(parseEther("1"))).to.be.revertedWithCustomError(bridgeContractCValue,"NotNexus")
            await bridgeContractCValue.validatorsSlashed(parseEther("1"));
            await expect(await bridgeContractCValue.slashedAmount()).to.be.equal(parseEther("1"))
        });
        it("should change c-token value",async function () {
            const before_balance_nexus = await ethers.provider.getBalance(await nexus_fee.getAddress());
            await bridgeContractCValue.updateCValue()
            const cValue = ((_amountDeposited - _amountWithdrawn)*parseEther("1"))/((await ethers.provider.getBalance(await bridgeContractCValue.getAddress()))+(toBigInt(10)*parseEther("32")));
            await expect(await ethers.provider.getBalance(await nexus_fee.getAddress())).to.equal(before_balance_nexus+parseEther("0.1"))
            await expect(await bridgeContractCValue.amountDistributed()).to.equal(_amountDistributed+parseEther("0.9"))
            await expect(await bridgeContractCValue.cValue()).to.equal(cValue)
        });
        it("should be able to update exited validators", async function(){
            await expect(bridgeContractCValue.connect(user1).updateExitedValidators()).to.be.revertedWithCustomError(bridgeContractCValue,"NotNexus");
            await expect(bridgeContractCValue.updateExitedValidators()).to.be.revertedWithCustomError(bridgeContractCValue,"ValidatorNotExited");
            await user1.sendTransaction({
                to: await bridgeContractCValue.getAddress(),
                value: parseEther("632")
            })
            await bridgeContractCValue.updateExitedValidators();
            await expect(await bridgeContractCValue.validatorCount()).to.be.equal(9)
        });

    })
    // it("nexus should add withdrawal address", async () => {
    //     await bridgeContract.setWithdrawal(withdrawalAddress);
    //     await expect(await bridgeContract.withdrawalCrendentails()).to.be.equal(
    //         withdrawalAddress
    //     );
    //     await expect(
    //         bridgeContract.connect(user1).setWithdrawal(await user1.getAddress())
    //     ).to.be.revertedWithCustomError(bridgeContract, "NotNexus");
    // });
});
