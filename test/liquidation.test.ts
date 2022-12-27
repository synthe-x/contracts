// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { initiate } from "../scripts/test";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Testing liquidation", function () {

	let synthex: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

		const deployments = await initiate();
		synthex = deployments.synthex;
        syn = deployments.syn;
		oracle = deployments.oracle;
		cryptoPool = deployments.pool;
		susd = deployments.susd;
		sbtc = deployments.sbtc;
		seth = deployments.seth;
        sethPriceFeed = deployments.ethPriceFeed;
        sbtcPriceFeed = deployments.sbtcPriceFeed;
	});

	it("Should deposit eth", async function () {
		await synthex.connect(user1).enterAndDeposit(ethers.constants.AddressZero, ethers.utils.parseEther("20"), {value: ethers.utils.parseEther("20")});    // $ 20000
		expect(await synthex.healthFactor(user1.address)).to.equal(ethers.constants.MaxUint256);

		await synthex.connect(user2).enterAndDeposit(ethers.constants.AddressZero, ethers.utils.parseEther("1000"), {value: ethers.utils.parseEther("1000")});    // $ 1000000
		expect(await synthex.healthFactor(user2.address)).to.equal(ethers.constants.MaxUint256);
	});

	it("user1 issue synths", async function () {
		// user1 issues 10 seth
        await synthex.connect(user1).enterAndIssue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000

        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.closeTo(ethers.utils.parseEther("10000.00"), ethers.utils.parseEther("0.01"));
        expect(await synthex.healthFactor(user1.address)).to.be.greaterThan(ethers.utils.parseEther("1.00"));
	});

    it("user2 issue synths", async function () {
		// user1 issues 10 seth
        await synthex.connect(user2).enterAndIssue(cryptoPool.address, sbtc.address, ethers.utils.parseEther("4")); // $ 40000

        expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.closeTo(ethers.utils.parseEther("40000.00"), ethers.utils.parseEther("0.01"));
        expect(await synthex.healthFactor(user2.address)).to.be.greaterThan(ethers.utils.parseEther("1.00"));        
	});

	it("liquidate 10 eth ($10000)", async function () {
        await sbtcPriceFeed.setPrice(ethers.utils.parseUnits("20000", 8));
        expect(await synthex.healthFactor(user1.address)).to.be.lessThan(ethers.utils.parseEther("1.00"));
        expect(await synthex.healthFactor(user2.address)).to.be.greaterThan(ethers.utils.parseEther("1.00"));

        await synthex.connect(user2).liquidate(user1.address, cryptoPool.address, sbtc.address, ethers.utils.parseEther("0.5"), ethers.constants.AddressZero);
	})
});