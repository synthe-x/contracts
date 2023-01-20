// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import deploy from "../scripts/test/user1_user2_deposited_issues";
import { ETH_ADDRESS } from "../scripts/utils/const";

describe("Testing liquidation", function () {

	let synthex: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	let liqHealthFactor = ethers.utils.parseEther("1.00");

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await deploy(owner, user1, user2, user3);
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

	it("check initial state", async function () {
		// check collateral
		expect(await synthex.getUserTotalCollateralUSD(user1.address)).to.be.equal(ethers.utils.parseEther("100000"));
		expect(await synthex.getUserTotalCollateralUSD(user2.address)).to.be.equal(ethers.utils.parseEther("100000"));
	});

	it("liquidation environment", async function () {
		// initial debt: $75000
		let totalDebt = ethers.utils.parseEther("75000")
		expect(await cryptoPool.getTotalDebtUSD()).to.be.equal(totalDebt);
		// user1: 33% ($25000)
		expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(totalDebt.div(3));
		// user2: 33% ($25000)
		expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.equal(totalDebt.div(3));


		// increasing btc price to $20000
		await sbtcPriceFeed.setPrice(ethers.utils.parseUnits("20000", 8), 8);

		// debt now: $100000
		totalDebt = ethers.utils.parseEther("100000");
		expect(await cryptoPool.getTotalDebtUSD()).to.be.equal(totalDebt);
		// user1: 33% ($33333)
		expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(totalDebt.div(3));
		// user2: 33% ($33333)
		expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.equal(totalDebt.div(3));

		// increasing btc price to $80000
		await sbtcPriceFeed.setPrice(ethers.utils.parseUnits("80000", 8), 8);

		// debt now: $250000
		totalDebt = ethers.utils.parseEther("250000");
		expect(await cryptoPool.getTotalDebtUSD()).to.be.equal(totalDebt);
		// user1: 33% ($83333)
		expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(totalDebt.div(3));
		// user1 adjusted debt: $83333 / 0.9 = $92592
		expect(await synthex.getAdjustedUserTotalDebtUSD(user1.address)).to.be.equal(totalDebt.div(3).mul(10).div(9));
		// user1 adjusted collateral: $100000 * 0.9 = $90000
		expect(await synthex.getAdjustedUserTotalCollateralUSD(user1.address)).to.be.equal(ethers.utils.parseEther("90000"));
		// user2: 33% ($83333)
		expect(await synthex.getUserTotalDebtUSD(user2.address)).to.be.equal(totalDebt.div(3));
		// user2 adjusted debt: $83333 / 0.9 = $92592
		expect(await synthex.getAdjustedUserTotalDebtUSD(user2.address)).to.be.equal(totalDebt.div(3).mul(10).div(9));

		// check health factor
		expect(await synthex.healthFactor(user1.address)).to.be.lessThan(ethers.utils.parseEther("1.00"));
		expect(await synthex.healthFactor(user2.address)).to.be.lessThan(ethers.utils.parseEther("1.00"));
		liqHealthFactor = await synthex.healthFactor(user1.address);
	});

	it("user2 liquidates user1 with 0.05 BTC ($4000)", async function () {
		// expect same health factor while partially liquidating
		expect(await synthex.healthFactor(user1.address)).to.equal(liqHealthFactor);
		// liquidate 0.05 BTC
        await synthex.connect(user2).liquidate(user1.address, cryptoPool.address, sbtc.address, ethers.utils.parseEther("0.05"), ETH_ADDRESS);

		// check health factor
		expect(await synthex.healthFactor(user1.address)).to.be.lessThan(ethers.utils.parseEther("1.00"));
		expect(await synthex.healthFactor(user2.address)).to.be.greaterThan(ethers.utils.parseEther("1.00"));
	})

	it("user2 completely liquidates user1", async function () {
		// expect same health factor while partially liquidating
		expect(await synthex.healthFactor(user1.address)).to.equal(liqHealthFactor);
		// liquidate 1 BTC
        await synthex.connect(user2).liquidate(user1.address, cryptoPool.address, sbtc.address, ethers.utils.parseEther("1"), ETH_ADDRESS);

		// check health factor
		expect(await synthex.healthFactor(user1.address)).to.be.equal(ethers.utils.parseEther("0"));
		expect(await synthex.healthFactor(user2.address)).to.be.greaterThan(ethers.utils.parseEther("1.00"));
	})

	it("tries to liquidate again", async function () {
        // expect tx to revert
		await expect(
			synthex.connect(user2).liquidate(user1.address, cryptoPool.address, sbtc.address, ethers.utils.parseEther("1"), ETH_ADDRESS)
		).to.be.revertedWith("Account is already liquidated");
	})
})