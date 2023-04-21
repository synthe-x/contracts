import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import hre from 'hardhat';

describe("Testing Collateral Enter/Exit", function () {
	let synthex: any,
        weth: any,
		aave: any,
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
		aave = deployments.pools[0].collateralTokens[1];
		susd = deployments.pools[0].synths[2];
	});

	it("supply 10 AAVE and 10 ETH", async function () {
        // AAVE
		await aave.mint(user1.address, ethers.utils.parseEther("10"));
		await aave
			.connect(user1)
			.approve(cryptoPool.address, ethers.utils.parseEther("10"));
		await cryptoPool
			.connect(user1)
			.deposit(aave.address, ethers.utils.parseEther("10"), user1.address);

		expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
			ethers.utils.parseEther("10000")
		);
        // ETH
        await cryptoPool.connect(user1).depositETH(user1.address, {value: ethers.utils.parseEther("10")});
		expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
			ethers.utils.parseEther("20000")
		);
	});

	it("exit eth collateral", async function () {
        await cryptoPool.connect(user1).exitCollateral(weth.address);

        expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
            ethers.utils.parseEther("10000")
        );
	});

    it("should not be able to exit after minting 8000 sUSD", async function () {
        await cryptoPool.connect(user1).mint(
            susd.address, 
            ethers.utils.parseEther("8000"),
            user1.address
        );

        await expect(cryptoPool.connect(user1).exitCollateral(aave.address)).to.be.revertedWith("6");
    })
});
