import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import { ETH_ADDRESS } from "../scripts/utils/const";
import main from "../scripts/main";

describe("Rewards", function () {

	let synthex: any, SYX: any, esSYX: any, oracle: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any, pool2;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
        esSYX = deployments.esSYX;
		SYX = deployments.SYX;
		oracle = deployments.pools[0].oracle;
		cryptoPool = deployments.pools[0].pool;
		sbtc = deployments.pools[0].synths[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];

		// supply reward tokens
		await SYX.mint(owner.address, ethers.utils.parseEther("100000000"));
		await SYX.increaseAllowance(esSYX.address, ethers.utils.parseEther("100000000"));
		await esSYX.lock(ethers.utils.parseEther("100000000"), synthex.address);
	});

	it("set pool speed", async function () {
		// expect to revert, as it is already added to list
		await expect(synthex.setPoolSpeed(esSYX.address, cryptoPool.address, ethers.utils.parseEther("10"), true)).to.be.revertedWith("SyntheX: Reward token already added to list");
		await synthex.setPoolSpeed(esSYX.address, cryptoPool.address, ethers.utils.parseEther("10"), false);
	});

	it("Should deposit eth", async function () {
		await cryptoPool.connect(user1).depositETH({value: ethers.utils.parseEther("50")});    // $ 50000
		expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).to.equal(ethers.utils.parseEther("50000"));

		await cryptoPool.connect(user2).depositETH({value: ethers.utils.parseEther("50")});    // $ 50000
		expect((await cryptoPool.getAccountLiquidity(user2.address))[1]).to.equal(ethers.utils.parseEther("50000"));
	});

	it("user1 and user2 issue debt", async function () {
		// user1 issues 10 seth
        await seth.connect(user1).mint(ethers.utils.parseEther("10")); // $ 10000
        expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.equal(ethers.utils.parseEther("10000.00"));

		await seth.connect(user2).mint(ethers.utils.parseEther("20")); // $ 20000
        expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.equal(ethers.utils.parseEther("20000.00"));
	});

	it("burn after 33 days", async function () {
		await time.increase(86400 * 33);
        await seth.connect(user1).burn(ethers.utils.parseEther("10")); 
        await seth.connect(user2).burn(ethers.utils.parseEther("10"));
	})
	
    it("check esSYN rewards", async function () {
		const totalRewards = ethers.utils.parseEther((10 * 86400 * 33).toString());
		const user1Rewards = await synthex.callStatic.getRewardsAccrued([esSYX.address], user1.address, [cryptoPool.address])
		const user2Rewards = await synthex.callStatic.getRewardsAccrued([esSYX.address], user2.address, [cryptoPool.address])

		expect(user1Rewards[0]).to.be.closeTo(totalRewards.mul(1).div(3), ethers.utils.parseEther("10000"));
		expect(user2Rewards[0]).to.be.closeTo(totalRewards.mul(2).div(3), ethers.utils.parseEther("10000"));

    })

	it("claim rewards", async function () {
		const totalRewards = ethers.utils.parseEther((10 * 86400 * 33).toString());
		await synthex.connect(user1).claimReward([esSYX.address], user1.address, [cryptoPool.address]);
		await synthex.connect(user2).claimReward([esSYX.address], user2.address, [cryptoPool.address]);

		// check balance
		expect(await esSYX.balanceOf(user1.address)).to.be.closeTo(totalRewards.mul(1).div(3), ethers.utils.parseEther("10000"));
		expect(await esSYX.balanceOf(user2.address)).to.be.closeTo(totalRewards.mul(2).div(3), ethers.utils.parseEther("10000"));
	});

	it("user2 burn remaining debt after 10 days", async function () {
		await time.increase(86400 * 10);
        await seth.connect(user2).burn(ethers.utils.parseEther("10"));
	})

	it("check esSYN rewards", async function () {
		const totalRewards = ethers.utils.parseEther((10 * 86400 * 10).toString());
		const user1Rewards = await synthex.callStatic.getRewardsAccrued([esSYX.address], user1.address, [cryptoPool.address])
		const user2Rewards = await synthex.callStatic.getRewardsAccrued([esSYX.address], user2.address, [cryptoPool.address])

		expect(user1Rewards[0]).to.be.equal(0);
		expect(user2Rewards[0]).to.be.closeTo(totalRewards, ethers.utils.parseEther("2000"));
    })
});