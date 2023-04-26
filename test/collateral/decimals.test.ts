import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import hre from 'hardhat';

describe("Testing Collateral Enter/Exit", function () {
	let synthex: any,
        weth: any,
		usdc: any,
		oracle: any,
		cryptoPool: any,
		susd: any;
	let owner: any, user1: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		oracle = deployments.pools[0].oracle;
		cryptoPool = deployments.pools[0].pool;
        weth = deployments.pools[0].collateralTokens[0];
		usdc = deployments.pools[0].collateralTokens[3];
		susd = deployments.pools[0].synths[2];
	});

	it("supply 1000 USDC", async function () {
        // AAVE
        const amount = ethers.utils.parseUnits("1000", 6);
		await usdc.mint(user1.address, amount);
		await usdc
			.connect(user1)
			.approve(cryptoPool.address, amount);
		await cryptoPool
			.connect(user1)
			.deposit(usdc.address, amount, user1.address);

		expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
			ethers.utils.parseEther("1000")
		);
	});
});
