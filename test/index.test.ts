import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../scripts/main";
import { ETH_ADDRESS } from "../scripts/utils/const";

describe("Testing the complete flow", function () {

	let synthex: any, oracle: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		oracle = deployments.oracle;
		cryptoPool = deployments.pools[0];
		sbtc = deployments.poolSynths[0][0];
		seth = deployments.poolSynths[0][1];
		susd = deployments.poolSynths[0][2];
	});

	it("Should stake eth", async function () {
		await synthex.connect(user1).deposit(ETH_ADDRESS, ethers.utils.parseEther("20"), {value: ethers.utils.parseEther("20").toString()});    // $ 20000
		await synthex.connect(user2).deposit(ETH_ADDRESS, ethers.utils.parseEther("10"), {value: ethers.utils.parseEther("10").toString()});    // $ 10000
		await synthex.connect(user3).deposit(ETH_ADDRESS, ethers.utils.parseEther("200"), {value: ethers.utils.parseEther("200").toString()});   // $ 100000

		expect(await synthex.healthFactorOf(user1.address)).to.equal(ethers.constants.MaxUint256);
		expect(await synthex.healthFactorOf(user2.address)).to.equal(ethers.constants.MaxUint256);
		expect(await synthex.healthFactorOf(user3.address)).to.equal(ethers.constants.MaxUint256);
	});

	it("issue synths", async function () {
		// user1 issues 10 seth
        await seth.connect(user1).mint(ethers.utils.parseEther("10")); // $ 10000
        // user3 issues 100000 susd
        await susd.connect(user3).mint(ethers.utils.parseEther("90000")); // $ 90000

		const user1Liquidity = await synthex.getAccountLiquidity(user1.address);
		const user3Liquidity = await synthex.getAccountLiquidity(user3.address);
        expect(user1Liquidity[1]).to.be.equal(ethers.utils.parseEther("10000.00"));
        expect(user3Liquidity[1]).to.be.equal(ethers.utils.parseEther("90000.00"));
	});

    it("swap em", async () => {
        // user1 exchanges 10 seth for 1 sbtc
        await seth.connect(user1).swap(ethers.utils.parseEther("10"), sbtc.address);
        // check balances
		const user1Liquidity = await synthex.getAccountLiquidity(user1.address);
		const user3Liquidity = await synthex.getAccountLiquidity(user3.address);
		expect(user1Liquidity[1]).to.be.equal(ethers.utils.parseEther("10000.00"));
		expect(user3Liquidity[1]).to.be.equal(ethers.utils.parseEther("90000.00"));

		expect(await seth.balanceOf(user1.address)).to.equal(0);
		expect(await sbtc.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1"));
    })

    it("update debt for users", async () => {
		const priorUser1Liquidity = await synthex.getAccountLiquidity(user1.address);
		const priorUser3Liquidity = await synthex.getAccountLiquidity(user3.address);

		// btc 10000 -> 15000
		const Feed = await ethers.getContractFactory("MockPriceFeed");
		const feed = Feed.attach(await oracle.getFeed(sbtc.address));
        await feed.setPrice(ethers.utils.parseUnits("20000", 8), 8);

		const user1Liquidity = await synthex.getAccountLiquidity(user1.address);
		const user3Liquidity = await synthex.getAccountLiquidity(user3.address);
        expect(user1Liquidity[1]).to.be.closeTo(priorUser1Liquidity[1].mul('110').div('100'), ethers.utils.parseEther("50"));
        expect(user3Liquidity[1]).to.be.closeTo(priorUser3Liquidity[1].mul('110').div('100'), ethers.utils.parseEther("500"));
    })

	it("burn synths", async function () {
		const debtUser1 = (await synthex.getAccountLiquidity(user1.address))[1]
		const debtUser3 = (await synthex.getAccountLiquidity(user3.address))[1]

		// user1 burns 10 seth
		let sbtcBalance = await sbtc.balanceOf(user1.address);
		await sbtc.connect(user1).burn(sbtcBalance); // $ 10000
		let sbtcToTransfer = await sbtc.balanceOf(user1.address);
		await sbtc.connect(user1).transfer(user3.address, sbtcToTransfer);
		// user3 burns 100000 susd
		let susdBalance = await susd.balanceOf(user3.address);
		await susd.connect(user3).burn(susdBalance); // $ 30000/118181
		sbtcBalance = await sbtc.balanceOf(user3.address);
		await sbtc.connect(user3).burn(sbtcBalance); // $ 45000/118181

		expect((await synthex.getAccountLiquidity(user1.address))[1]).to.be.closeTo(ethers.utils.parseEther("0.00"), ethers.utils.parseEther("0.2"));
		expect((await synthex.getAccountLiquidity(user3.address))[1]).to.be.lessThan(debtUser3);
		// expect(await synthex.getUserTotalDebtUSD(user3.address)).to.be.greaterThan(ethers.utils.parseEther("0.00"));
	})
});