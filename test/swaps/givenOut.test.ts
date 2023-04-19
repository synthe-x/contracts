import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";

describe("Testing Swaps: Given Out", function () {

	let synthex: any, oracle: any, pool: any, eth: any, susd: any, sbtc: any, seth: any, sbtcFeed: any;
	let owner: any, user1: any;

	beforeEach(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		pool = deployments.pools[0].pool;
		oracle = deployments.pools[0].oracle;
		sbtc = deployments.pools[0].synths[0];
		sbtcFeed = deployments.pools[0].synthPriceFeeds[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];

		await pool.connect(user1).depositETH(user1.address, {value: ethers.utils.parseEther("20")});    // $ 20000
		expect((await pool.getAccountLiquidity(user1.address)).collateral).to.equal(ethers.utils.parseEther('20000'));

        await pool.connect(user1).mint(seth.address, ethers.utils.parseEther("10"), user1.address); // $ 10000
		// balance
		expect(await seth.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("10"));

		const user1Liquidity = await pool.getAccountLiquidity(user1.address);
        expect(user1Liquidity[2]).to.be.equal(ethers.utils.parseEther("10000.00"));
	});

    it("swap given exact in", async () => {
        // user1 exchanges 10 seth for 1 sbtc
        await pool.connect(user1).swap(seth.address, ethers.utils.parseEther("1"), sbtc.address, 1, user1.address);
        // check balances
		expect(await seth.balanceOf(user1.address)).to.equal(0);
		expect(await sbtc.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1"));
        // expect no change in liquidity
		const user1Liquidity = await pool.getAccountLiquidity(user1.address);
		expect(user1Liquidity[2]).to.be.equal(ethers.utils.parseEther("10000.00"));
    })

	it("with 1% fee", async () => {
		await pool.connect(owner).updateSynth(sbtc.address, {mintFee: 100, isActive: true, isDisabled: false, burnFee: 0});

		// user1 exchanges 10 seth for 1 sbtc
		await expect(pool.connect(user1).swap(seth.address, ethers.utils.parseEther("1"), sbtc.address, 1, user1.address)).to.be.revertedWith("ERC20: burn amount exceeds balance");

		// user1 exchanges 1 seth for 0.1 sbtc
		await pool.connect(user1).swap(seth.address, ethers.utils.parseEther("0.1"), sbtc.address, 1, user1.address);

		// check balances
		let sethAmountExpectedToSpend = ethers.utils.parseEther("1").mul(101).div(100);
		expect(await seth.balanceOf(user1.address)).to.closeTo(ethers.utils.parseEther("10").sub(sethAmountExpectedToSpend), ethers.utils.parseEther('0.001'));
		expect(await sbtc.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("0.1"));
	})
});