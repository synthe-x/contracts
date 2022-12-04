// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { deploy } from "../scripts/deploy";
import { initiate } from "../scripts/initiate";

describe("SyntheX", function () {
	let synthex: any, oracle: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;
	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await deploy();
		synthex = deployments.synthex;
		oracle = deployments.oracle;
		cryptoPool = deployments.cryptoPool;


		const tokens = await initiate(synthex, cryptoPool, oracle);
		eth = tokens.eth;
		susd = tokens.susd;
		sbtc = tokens.sbtc;
		seth = tokens.seth;
	});

	it("Should stake eth", async function () {
		await eth.connect(user1).mint(user1.address, ethers.utils.parseUnits("100", 18));
		await eth.connect(user2).mint(user2.address, ethers.utils.parseUnits("100", 18));
		await eth.connect(user3).mint(user3.address, ethers.utils.parseUnits("100", 18));

		await eth.connect(user1).approve(synthex.address, ethers.utils.parseUnits("100", 18));
		await eth.connect(user2).approve(synthex.address, ethers.utils.parseUnits("100", 18));
		await eth.connect(user3).approve(synthex.address, ethers.utils.parseUnits("100", 18));

		await synthex.connect(user1).enterCollateral(eth.address);
		await synthex.connect(user1).deposit(eth.address, ethers.utils.parseEther("20"));    // $ 20000
		await synthex.connect(user2).enterCollateral(eth.address);
		await synthex.connect(user2).deposit(eth.address, ethers.utils.parseEther("10"));    // $ 10000
		await synthex.connect(user3).enterCollateral(eth.address);
		await synthex.connect(user3).deposit(eth.address, ethers.utils.parseEther("100"));   // $ 100000

		expect(await synthex.healthFactor(user1.address)).to.equal(ethers.constants.MaxUint256);
		expect(await synthex.healthFactor(user2.address)).to.equal(ethers.constants.MaxUint256);
		expect(await synthex.healthFactor(user3.address)).to.equal(ethers.constants.MaxUint256);
	});

	it("issue synths", async function () {
		// user1 issues 10 seth
		await synthex.connect(user1).enterPool(cryptoPool.address);
        await synthex.connect(user1).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000
        // user3 issues 100000 susd
		await synthex.connect(user3).enterPool(cryptoPool.address);
        await synthex.connect(user3).issue(cryptoPool.address, susd.address, ethers.utils.parseEther("100000")); // $ 100000

        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.closeTo(ethers.utils.parseEther("10000.00"), ethers.utils.parseEther("0.01"));
        expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.closeTo(ethers.utils.parseEther("100000.00"), ethers.utils.parseEther("0.01"));
	});

    it("exchange", async () => {
        // user3 exchanges 100000 susd for 10 seth
        await synthex.connect(user3).exchange(cryptoPool.address, susd.address, seth.address, ethers.utils.parseEther("30000"));
        // eth 1000 -> 1500
		const Feed = await ethers.getContractFactory("PriceFeed");
		const feed = Feed.attach(await oracle.getFeed(seth.address));
        await feed.setPrice(ethers.utils.parseUnits("1500", 8));
    })

    it("update debt for users", async () => {
        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.closeTo(ethers.utils.parseEther("11818.18"), ethers.utils.parseEther("0.01"));
        expect(await synthex.getUserTotalDebtUSD(user3.address)).to.closeTo(ethers.utils.parseEther("118181.81"), ethers.utils.parseEther("0.01"));
    })
});
