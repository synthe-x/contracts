// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import initiate from "../scripts/test";
import { ETH_ADDRESS } from "../scripts/utils/const";

describe("SyntheX", function () {

	let synthex: any, oracle: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await initiate(owner.address);
		synthex = deployments.synthex;
		oracle = deployments.oracle;
		cryptoPool = deployments.pool;
		susd = deployments.susd;
		sbtc = deployments.sbtc;
		seth = deployments.seth;
	});

	it("Should stake eth", async function () {
		await synthex.connect(user1).deposit(ETH_ADDRESS, ethers.utils.parseEther("20"), {value: ethers.utils.parseEther("20").toString()});    // $ 20000
		await synthex.connect(user2).deposit(ETH_ADDRESS, ethers.utils.parseEther("10"), {value: ethers.utils.parseEther("10").toString()});    // $ 10000
		await synthex.connect(user3).deposit(ETH_ADDRESS, ethers.utils.parseEther("200"), {value: ethers.utils.parseEther("200").toString()});   // $ 100000

		expect(await synthex.healthFactor(user1.address)).to.equal(ethers.constants.MaxUint256);
		expect(await synthex.healthFactor(user2.address)).to.equal(ethers.constants.MaxUint256);
		expect(await synthex.healthFactor(user3.address)).to.equal(ethers.constants.MaxUint256);
	});

	it("issue synths", async function () {
		// user1 issues 10 seth
        await synthex.connect(user1).issue(cryptoPool.address, seth.address, ethers.utils.parseEther("10")); // $ 10000
        // user3 issues 100000 susd
        await synthex.connect(user3).issue(cryptoPool.address, susd.address, ethers.utils.parseEther("90000")); // $ 90000

        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(ethers.utils.parseEther("10000.00"));
        expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.equal(ethers.utils.parseEther("90000.00"));
	});

    it("exchange", async () => {
        // user1 exchanges 10 seth for 1 sbtc
        await synthex.connect(user1).exchange(cryptoPool.address, seth.address, sbtc.address, ethers.utils.parseEther("10"));
        // check balances
		expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.equal(ethers.utils.parseEther("10000.00"));
		expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.equal(ethers.utils.parseEther("90000.00"));

		expect(await seth.balanceOf(user1.address)).to.equal(0);
		expect(await sbtc.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1"));
    })

    it("update debt for users", async () => {
		const debtUser1 = await synthex.getUserTotalDebtUSD(user1.address);
		const debtUser3 = await synthex.getUserTotalDebtUSD(user3.address);

		// btc 10000 -> 15000
		const Feed = await ethers.getContractFactory("MockPriceFeed");
		const feed = Feed.attach(await oracle.getFeed(sbtc.address));
        await feed.setPrice(ethers.utils.parseUnits("20000", 8), 8);

        expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.closeTo(debtUser1.mul('110').div('100'), ethers.utils.parseEther("50"));
        expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.closeTo(debtUser3.mul('110').div('100'), ethers.utils.parseEther("500"));
    })

	it("burn synths", async function () {
		const debtUser1 = await synthex.getUserTotalDebtUSD(user1.address);
		const debtUser3 = await synthex.getUserTotalDebtUSD(user3.address);

		// user1 burns 10 seth
		let sbtcBalance = await sbtc.balanceOf(user1.address);
		console.log('User 1 burning', ethers.utils.formatEther(sbtcBalance), 'sbtc');
		await synthex.connect(user1).burn(cryptoPool.address, sbtc.address, sbtcBalance); // $ 10000
		let sbtcToTransfer = await sbtc.balanceOf(user1.address);
		console.log("Transfering", ethers.utils.formatEther(sbtcToTransfer), "sbtc to user3");
		await sbtc.connect(user1).transfer(user3.address, sbtcToTransfer);
		// user3 burns 100000 susd
		let susdBalance = await susd.balanceOf(user3.address);
		console.log("Burning", ethers.utils.formatEther(susdBalance), "susd");
		await synthex.connect(user3).burn(cryptoPool.address, susd.address, susdBalance); // $ 30000/118181
		sbtcBalance = await sbtc.balanceOf(user3.address);
		console.log("Burning", ethers.utils.formatEther(sbtcBalance), "sbtc");
		await synthex.connect(user3).burn(cryptoPool.address, sbtc.address, sbtcBalance); // $ 45000/118181


		expect(await synthex.getUserTotalDebtUSD(user1.address)).to.be.closeTo(ethers.utils.parseEther("0.00"), ethers.utils.parseEther("0.2"));
		// expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.greaterThan(ethers.utils.parseEther("0.00"));
		expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.lessThan(debtUser3);
	})
});