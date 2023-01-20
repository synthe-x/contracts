// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import deploy from "../scripts/test";
import initiatePool from "../scripts/test/initiate";

import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ETH_ADDRESS } from "../scripts/utils/const";

describe("Rewards", function () {

	let synthex: any, syn: any, sealedSyn: any, oracle: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any, pool2;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

		const deployments = await deploy(owner);
		synthex = deployments.synthex;
        sealedSyn = deployments.sealedSYN;
		oracle = deployments.oracle;
		cryptoPool = deployments.pool;
		susd = deployments.susd;
		sbtc = deployments.sbtc;
		seth = deployments.seth;
	});

	it("Should deposit eth", async function () {
		await synthex.connect(user1).deposit(ETH_ADDRESS, ethers.utils.parseEther("50"), {value: ethers.utils.parseEther("50")});    // $ 50000
		expect(await synthex.healthFactor(user1.address)).to.equal(ethers.constants.MaxUint256);

		await synthex.connect(user2).deposit(ETH_ADDRESS, ethers.utils.parseEther("50"), {value: ethers.utils.parseEther("50")});    // $ 50000
		expect(await synthex.healthFactor(user2.address)).to.equal(ethers.constants.MaxUint256);
	});

	it("user1 issue synths", async function () {
		// user1 issues 10 seth
        await synthex.connect(user1).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000
        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(ethers.utils.parseEther("10000.00"));
	});

    it("user2 issue synths", async function () {
		// user1 issues 10 seth
        await synthex.connect(user2).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000

        expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.equal(ethers.utils.parseEther("10000.00"));
	});

	it("burn after 30 days", async function () {
		await time.increase(86400 * 33);
        await synthex.connect(user1).burn(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); 
        await synthex.connect(user2).burn(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); 
	})
	
    it("claim SYN", async function () {
		// 0.1 * 3600 * 24 * 30 * 0.5 = 129600
		expect(await synthex.callStatic.getRewardsAccrued(sealedSyn.address, user1.address, [cryptoPool.address])).to.closeTo(ethers.utils.parseEther("129600"), ethers.utils.parseEther("3000"));
		// 0.1 * 3600 * 24 * 30 * 0.5 = 129600
		expect(await synthex.callStatic.getRewardsAccrued(sealedSyn.address, user2.address, [cryptoPool.address])).to.equals(ethers.utils.parseEther("129600"));

		// check prior balance
        expect(await sealedSyn.balanceOf(user1.address)).to.equal(ethers.constants.Zero);
        expect(await sealedSyn.balanceOf(user2.address)).to.equal(ethers.constants.Zero);
		// claim the rewards
        await synthex['claimReward(address,address,address[])'](sealedSyn.address, user1.address, [cryptoPool.address]);
        await synthex['claimReward(address,address,address[])'](sealedSyn.address, user2.address, [cryptoPool.address]);
		// accurately predict the amount of rewards

    })
});