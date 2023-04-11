// Test permit of ERC20X contract

import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import main from "../../scripts/main";
import hre from 'hardhat';

describe("Testing ERC20X Upgradeablity", function () {

	let synthex: any, oracle: any, pool: any, eth: any, susd: any, sbtc: any, seth: any, sbtcFeed: any;
	let owner: any, user1: any, user2: any, user3: any;

	beforeEach(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		pool = deployments.pools[0].pool;
		sbtc = deployments.pools[0].synths[0];
	});

	it("Mint 0.1 sBTC", async function () {
        // Deposit 10 ETH to pool
        await pool.connect(user1).depositETH({value: ethers.utils.parseEther("10")});
        // Mint 1 sBTC
        await sbtc.connect(user1).mint(ethers.utils.parseEther("0.1"), user1.address, ethers.constants.AddressZero);
    });


	it("User1 approves 0.05 sBTC to user2 via calling permit", async function () {
        expect(await sbtc.allowance(user1.address, pool.address)).eq(0);

        // permit signature
		const domain = {
			name: await sbtc.name(),
			version: "1",
			chainId: hre.network.config.chainId,
			verifyingContract: sbtc.address,
		};

		const Permit = [
			{ name: "owner", type: "address" },
			{ name: "spender", type: "address" },
			{ name: "value", type: "uint256" },
			{ name: "nonce", type: "uint256" },
			{ name: "deadline", type: "uint256" },
		];

        const deadline = Date.now() + 200 * 60;
        const value = ethers.utils.parseEther("0.05");

		const permit = {
			owner: user1.address,
			spender: pool.address,
			value,
			nonce: (await sbtc.nonces(user1.address)).toHexString(),
			deadline,
		};
        
        const signature = await user1._signTypedData(domain, { Permit }, permit);
        const { v, r, s } = ethers.utils.splitSignature(signature);

        // Approve 0.05 sBTC to user2
        await sbtc.connect(user1).permit(user1.address, pool.address, value, deadline, v, r, s);

        // check allowance
        expect(await sbtc.allowance(user1.address, pool.address)).eq(value);
    });
});