import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../scripts/main";

describe("Testing the complete flow", function () {

	let synthex: any, oracle: any, pool: any, eth: any, susd: any, sbtc: any, seth: any, sbtcFeed: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		pool = deployments.pools[0].pool;
		oracle = deployments.pools[0].oracle;
		sbtc = deployments.pools[0].synths[0];
		sbtcFeed = deployments.pools[0].synthPriceFeeds[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];
	});

	it("Should stake eth", async function () {
		const user1Deposit = ethers.utils.parseEther("20");
		const user2Deposit = ethers.utils.parseEther("10");
		const user3Deposit = ethers.utils.parseEther("200");

		await pool.connect(user1).depositETH(user1.address, {value: user1Deposit});    // $ 20000
		// user2 transfers 10 eth to pool
		// await user2.sendTransaction({to: pool.address, value: user2Deposit}); // $ 10000
		await pool.connect(user2).depositETH(user2.address, {value: user2Deposit});    // $ 10000
		await pool.connect(user3).depositETH(user3.address, {value: user3Deposit});   // $ 100000

		expect((await pool.getAccountLiquidity(user1.address)).collateral).to.equal(ethers.utils.parseEther('20000'));
		expect((await pool.getAccountLiquidity(user2.address)).collateral).to.equal(ethers.utils.parseEther('10000'));
		expect((await pool.getAccountLiquidity(user3.address)).collateral).to.equal(ethers.utils.parseEther('200000'));
	});

	it("issue synths", async function () {
		// user1 issues 10 seth
        await pool.connect(user1).mint(seth.address, ethers.utils.parseEther("10"), user1.address); // $ 10000
        // user3 issues 100000 susd
        await pool.connect(user3).mint(susd.address, ethers.utils.parseEther("90000"), user3.address); // $ 90000

		// balance
		expect(await seth.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("10"));
		expect(await susd.balanceOf(user3.address)).to.equal(ethers.utils.parseEther("90000"));

		const user1Liquidity = await pool.getAccountLiquidity(user1.address);
		const user3Liquidity = await pool.getAccountLiquidity(user3.address);
        expect(user1Liquidity[2]).to.be.equal(ethers.utils.parseEther("10000.00"));
        expect(user3Liquidity[2]).to.be.equal(ethers.utils.parseEther("90000.00"));
	});

    it("swap em", async () => {
        // user1 exchanges 10 seth for 1 sbtc
        await pool.connect(user1).swap(seth.address, ethers.utils.parseEther("10"), sbtc.address, 0, user1.address);
        // check balances
		const user1Liquidity = await pool.getAccountLiquidity(user1.address);
		const user3Liquidity = await pool.getAccountLiquidity(user3.address);
		expect(user1Liquidity[2]).to.be.equal(ethers.utils.parseEther("10000.00"));
		expect(user3Liquidity[2]).to.be.equal(ethers.utils.parseEther("90000.00"));

		expect(await seth.balanceOf(user1.address)).to.equal(0);
		expect(await sbtc.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1"));
    })

    it("update debt for users", async () => {
		const priorUser1Liquidity = await pool.getAccountLiquidity(user1.address);
		const priorUser3Liquidity = await pool.getAccountLiquidity(user3.address);

		// btc 10000 -> 20000, increases debt by 100%
        await sbtcFeed.setPrice(ethers.utils.parseUnits("20000", 8), 8);

        expect((await pool.getAccountLiquidity(user1.address))[2]).to.be.equal(priorUser1Liquidity[2].mul('110').div('100'));
        expect((await pool.getAccountLiquidity(user3.address))[2]).to.be.equal(priorUser3Liquidity[2].mul('110').div('100'));
    })

	it("burn synths", async function () {
		const debtUser1 = (await pool.getAccountLiquidity(user1.address))[2]
		const debtUser3 = (await pool.getAccountLiquidity(user3.address))[2]

		// user1 burns 10 seth
		let sbtcBalance = await sbtc.balanceOf(user1.address);
		await pool.connect(user1).burn(sbtc.address, sbtcBalance); // $ 10000
		let sbtcToTransfer = await sbtc.balanceOf(user1.address);
		await sbtc.connect(user1).transfer(user3.address, sbtcToTransfer);
		// user3 burns 100000 susd
		let susdBalance = await susd.balanceOf(user3.address);
		await pool.connect(user3).burn(susd.address, susdBalance); // $ 30000/118181
		sbtcBalance = await sbtc.balanceOf(user3.address);
		await pool.connect(user3).burn(sbtc.address, sbtcBalance); // $ 45000/118181

		expect((await pool.getAccountLiquidity(user1.address))[2]).to.be.closeTo(ethers.utils.parseEther("0.00"), ethers.utils.parseEther("0.2"));
		expect((await pool.getAccountLiquidity(user3.address))[2]).to.be.lessThan(debtUser3);
	})
});