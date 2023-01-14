// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import deploy from "../scripts/test";
import { ETH_ADDRESS } from "../scripts/utils/const";

describe("Testing Fee", function () {

	let synthex: any, vault: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	let liqHealthFactor = ethers.utils.parseEther("1.00");

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await deploy(owner.address);
        vault = deployments.vault;
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

    it("update fee to 1%", async function () {
        await cryptoPool.connect(owner).updateFee(ethers.utils.parseEther("100"));
        expect(await cryptoPool.fee()).to.equal(ethers.utils.parseEther("100"));
    });


	it("Should deposit eth", async function () {
		await synthex.connect(user1).deposit(ETH_ADDRESS, ethers.utils.parseEther("50"), {value: ethers.utils.parseEther("50")});    // $ 50000
		expect(await synthex.accountCollateralBalance(user1.address, ETH_ADDRESS)).to.equal(ethers.utils.parseEther("50"));

		await synthex.connect(user2).deposit(ETH_ADDRESS, ethers.utils.parseEther("50"), {value: ethers.utils.parseEther("50")});    // $ 50000
		expect(await synthex.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.equal(ethers.utils.parseEther("50"));
	});

    it("user1 issue synths", async function () {
		// user1 issues 10 seth
        await synthex.connect(user1).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000
        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(ethers.utils.parseEther("10000.00"));
        // After issuing 10 ETH, balance should be 9.9 ETH
        // 10 - 0.1 (1%) fee
        expect(await seth.balanceOf(user1.address)).to.be.equal(ethers.utils.parseEther("9.9")); 
	});

    it("user1 exchanges 1 seth to sbtc", async function () {
        // user1 exchanges 1 seth to sbtc
        await synthex.connect(user1).exchange(cryptoPool.address, seth.address, sbtc.address, ethers.utils.parseEther("1")); 
        // After exchanging 1 seth to sbtc, user should get 0.1 sbtc
        // 0.1 - 0.01 (1%) fee
        expect(await sbtc.balanceOf(user1.address)).to.be.equal(ethers.utils.parseEther("0.099")); 
    })

    it("update fee to 0.1%", async function () {
        await cryptoPool.connect(owner).updateFee(ethers.utils.parseEther("10"));
        expect(await cryptoPool.fee()).to.equal(ethers.utils.parseEther("10"));
    });

    it("user2 issue synths", async function () {
		// user2 issues 10 seth
        await synthex.connect(user2).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000
        expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.equal(ethers.utils.parseEther("10000.00"));
        // After issuing 10 ETH, balance should be 9.99 ETH
        // 10 - 0.01 (0.1%) fee
        expect(await seth.balanceOf(user2.address)).to.be.equal(ethers.utils.parseEther("9.99")); 
	});

    it("user2 exchanges 1 seth to sbtc", async function () {
        // user1 exchanges 1 seth to sbtc
        await synthex.connect(user2).exchange(cryptoPool.address, seth.address, sbtc.address, ethers.utils.parseEther("1")); 
        // After exchanging 1 seth to sbtc, user should get 0.1 sbtc
        // 0.1 - 0.001 (1%) fee
        expect(await sbtc.balanceOf(user2.address)).to.be.equal(ethers.utils.parseEther("0.0999")); 
    })
})