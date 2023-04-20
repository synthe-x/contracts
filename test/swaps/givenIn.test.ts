import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";

describe("Testing Swap: Given In", function () {

	let synthex: any, oracle: any, pool: any, eth: any, susd: any, sbtc: any, seth: any, sbtcFeed: any;
	let owner: any, user1: any;

	before(async () => {
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
        await pool.connect(user1).swap(seth.address, ethers.utils.parseEther("10"), sbtc.address, 0, user1.address);
        // check balances
		expect(await seth.balanceOf(user1.address)).to.equal(0);
		expect(await sbtc.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1"));
        // expect no change in liquidity
		const user1Liquidity = await pool.getAccountLiquidity(user1.address);
		expect(user1Liquidity[2]).to.be.equal(ethers.utils.parseEther("10000.00"));
    })
});