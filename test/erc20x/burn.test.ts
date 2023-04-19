// Test permit of ERC20X contract

import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import main from "../../scripts/main";
import hre from 'hardhat';

describe("Testing ERC20X Burnability", function () {

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
        await pool.connect(user1).depositETH(user1.address, {value: ethers.utils.parseEther("10")});
        // Mint 1 sBTC
        await pool.connect(user1).mint(sbtc.address, ethers.utils.parseEther("0.1"), user1.address);
    });


	it("Should not be able to burn synthe", async function () {
        await expect(sbtc.connect(user1).transfer(ethers.constants.AddressZero, ethers.utils.parseEther("0.01"))).to.be.revertedWith('ERC20: transfer to the zero address');
    });
});