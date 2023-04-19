import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ETH_ADDRESS } from "../../scripts/utils/const";
import main from "../../scripts/main";

describe("ETH Collateral", function () {
	let synthex: any,
		weth: any,
		oracle: any,
		cryptoPool: any,
		eth: any,
		susd: any,
		sbtc: any,
		seth: any,
		pool2;
	let owner: any, user1: any, user2: any, user3: any;

	beforeEach(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		oracle = deployments.pools[0].oracle;
		cryptoPool = deployments.pools[0].pool;
		weth = deployments.pools[0].collateralTokens[0];
		sbtc = deployments.pools[0].synths[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];
	});

	it("deposit with depositETH", async function () {
        await cryptoPool.connect(user1).depositETH(user1.address, {value: ethers.utils.parseEther("10")});
		expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
			ethers.utils.parseEther("10000")
		);
	});

	it('withdraw all', async () => {
		await cryptoPool.connect(user1).depositETH(user1.address, {value: ethers.utils.parseEther("10")});
		await cryptoPool.connect(user1).withdraw(weth.address, ethers.utils.parseEther("1"), true);
		// expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
		// 	ethers.utils.parseEther("0")
		// );
	});
});
