import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import main from "../../scripts/main";

describe("Testing ERC20X Upgradeablity", function () {

	let synthex: any, oracle: any, pool: any, eth: any, susd: any, sbtc: any, seth: any, sbtcFeed: any;
	let owner: any, user1: any, user2: any, user3: any;

	beforeEach(async () => {
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

	it("Owner should be able to upgrade contract to ERC20XV2", async function () {
        const ERC20XV2 = await ethers.getContractFactory("ERC20XV2", owner);
        const upgradedSeth = await upgrades.upgradeProxy(seth, ERC20XV2);

        expect(await upgradedSeth.version()).to.be.equal('v2');
    });

	it("User should not be able to upgrade contract to ERC20XV2", async function () {
        const ERC20XV2 = await ethers.getContractFactory("ERC20XV2", user1);
        await expect(upgrades.upgradeProxy(seth, ERC20XV2)).to.be.revertedWith("2");
		const sethv2 = ERC20XV2.attach(seth.address);
		await expect(sethv2.version()).to.be.revertedWithoutReason();
    });

	it("Should not be able to call initialize again", async function () {
		const ERC20XV2 = await ethers.getContractFactory("ERC20XV2", owner);
		const upgradedSeth = await upgrades.upgradeProxy(seth, ERC20XV2);
		await expect(upgradedSeth.initialize(
			"Synth sETH",
			"sETH",
			owner.address,
			owner.address,
		)).to.be.revertedWith("Initializable: contract is already initialized");
    });
});