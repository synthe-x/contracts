// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { initiate } from "../scripts/test_initiate";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("SyntheX", function () {

	let synthex: any, syn: any, oracle: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

		const deployments = await initiate();
		synthex = deployments.synthex;
        syn = deployments.syn;
		oracle = deployments.oracle;
		cryptoPool = deployments.pool;
		eth = deployments.eth;
		susd = deployments.susd;
		sbtc = deployments.sbtc;
		seth = deployments.seth;
	});

	it("Should deposit eth", async function () {
		await eth.connect(user1).mint(user1.address, ethers.utils.parseUnits("100", 18));
		
		await eth.connect(user1).approve(synthex.address, ethers.utils.parseUnits("100", 18));

		await synthex.connect(user1).enterCollateral(eth.address);
		await synthex.connect(user1).deposit(eth.address, ethers.utils.parseEther("50"));    // $ 50000

		expect(await synthex.healthFactor(user1.address)).to.equal(ethers.constants.MaxUint256);

        await eth.connect(user2).mint(user2.address, ethers.utils.parseUnits("100", 18));
		
		await eth.connect(user2).approve(synthex.address, ethers.utils.parseUnits("100", 18));

		await synthex.connect(user2).enterCollateral(eth.address);
		await synthex.connect(user2).deposit(eth.address, ethers.utils.parseEther("50"));    // $ 50000

		expect(await synthex.healthFactor(user2.address)).to.equal(ethers.constants.MaxUint256);
	});

	it("user1 issue synths", async function () {
		// user1 issues 10 seth
		await synthex.connect(user1).enterPool(cryptoPool.address);
        await synthex.connect(user1).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000

        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.closeTo(ethers.utils.parseEther("10000.00"), ethers.utils.parseEther("0.01"));
	});

    it("user2 issue synths", async function () {
		// user1 issues 10 seth
		await synthex.connect(user2).enterPool(cryptoPool.address);
        await synthex.connect(user2).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000

        expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.closeTo(ethers.utils.parseEther("10000.00"), ethers.utils.parseEther("0.01"));
	});

	it("burn after 7 days", async function () {
		await time.increase(86400 * 30); 
        await synthex.connect(user1).burn(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); 
        // 0.1 * 85400 * 30 * 0.5 = 128100
        expect(await synthex.synAccrued(user1.address)).to.be.greaterThan(ethers.utils.parseEther("128100"));

        await synthex.connect(user2).burn(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); 
        // 0.1 * 85400 * 30 * 0.5 = 128100
        expect(await synthex.synAccrued(user2.address)).to.be.greaterThan(ethers.utils.parseEther("128100"));
	})

    it("claim SYN", async function () {
        expect(await syn.balanceOf(user1.address)).to.equal(ethers.constants.Zero);
        expect(await syn.balanceOf(user2.address)).to.equal(ethers.constants.Zero);
        await synthex.claimSYN1(user1.address);
        await synthex.claimSYN1(user2.address);
        expect(await syn.balanceOf(user1.address)).to.be.greaterThan(ethers.utils.parseEther("128100"));
        expect(await syn.balanceOf(user2.address)).to.be.greaterThan(ethers.utils.parseEther("128100"));
    })
});