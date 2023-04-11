import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import main from "../../scripts/main";

describe("Testing Pool Upgradeablity", function () {

	let synthex: any, pool: any;
	let owner: any, user1: any, user2: any, user3: any;

	beforeEach(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		pool = deployments.pools[0].pool;
	});

	it("Owner should be able to upgrade contract to PoolV2", async function () {
        const PoolV2 = await ethers.getContractFactory("PoolV2", owner);
        const upgradedSeth = await upgrades.upgradeProxy(pool, PoolV2);

        expect(await upgradedSeth.version()).to.be.equal('v2');
    });


	it("User should not be able to upgrade contract to PoolV2", async function () {
        const PoolV2 = await ethers.getContractFactory("PoolV2", user1);
        await expect(upgrades.upgradeProxy(pool, PoolV2)).to.be.revertedWith("2");
		const poolv2 = PoolV2.attach(pool.address);
		await expect(poolv2.version()).to.be.revertedWithoutReason();
    });
});