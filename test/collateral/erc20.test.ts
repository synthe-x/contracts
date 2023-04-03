import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ETH_ADDRESS } from "../../scripts/utils/const";
import main from "../../scripts/main";
import hre from 'hardhat';

describe("Rewards", function () {
	let synthex: any,
		aave: any,
		oracle: any,
		cryptoPool: any,
		susd: any,
		sbtc: any,
		seth: any,
		pool2;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		oracle = deployments.pools[0].oracle;
		cryptoPool = deployments.pools[0].pool;
		aave = deployments.pools[0].collateralTokens[1];

		sbtc = deployments.pools[0].synths[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];
	});

	it("supply token", async function () {
		await aave.mint(user1.address, ethers.utils.parseEther("10"));
		await aave
			.connect(user1)
			.approve(cryptoPool.address, ethers.utils.parseEther("10"));
		await cryptoPool
			.connect(user1)
			.deposit(aave.address, ethers.utils.parseEther("10"));

		expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
			ethers.utils.parseEther("10000")
		);
	});

	it("supply token with permit", async function () {
		await aave.mint(user1.address, ethers.utils.parseEther("10"));
		// permit signature
		const domain = {
			name: await aave.name(),
			version: "1",
			chainId: hre.network.config.chainId,
			verifyingContract: aave.address,
		};

		const Permit = [
			{ name: "owner", type: "address" },
			{ name: "spender", type: "address" },
			{ name: "value", type: "uint256" },
			{ name: "nonce", type: "uint256" },
			{ name: "deadline", type: "uint256" },
		];

        const deadline = Date.now() + 200 * 60;
        const value = ethers.utils.parseEther("10");

		const permit = {
			owner: user1.address,
			spender: cryptoPool.address,
			value,
			nonce: (await aave.nonces(user1.address)).toHexString(),
			deadline,
		};
        
        const signature = await user1._signTypedData(domain, { Permit }, permit);
        const { v, r, s } = ethers.utils.splitSignature(signature);

        await cryptoPool.connect(user1).depositWithPermit(aave.address, value, deadline, v, r, s);

        expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).eq(
            ethers.utils.parseEther("20000")
        );
	});

	it("withdraw all", async function () {
		await cryptoPool.connect(user1).withdraw(aave.address, ethers.utils.parseEther('20'), false);

		expect(await aave.balanceOf(user1.address)).eq(
			ethers.utils.parseEther("20")
		);
	});
});
