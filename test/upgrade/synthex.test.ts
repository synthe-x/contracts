import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import main from "../../scripts/main";

describe("Testing SyntheX Upgradeablity", function () {

	let synthex: any;
	let owner: any, user1: any, user2: any, user3: any;

	beforeEach(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
	});

	it("Owner should be able to upgrade contract to SyntheXV2", async function () {
        const SyntheXV2 = await ethers.getContractFactory("SyntheXV2", owner);
        const upgradedSynthex = await upgrades.upgradeProxy(synthex, SyntheXV2);

        expect(await upgradedSynthex.version()).to.be.equal('v2');
    });


	it("User should not be able to upgrade contract to SyntheXV2", async function () {
        const SyntheXV2 = await ethers.getContractFactory("SyntheXV2", user1);
        await expect(upgrades.upgradeProxy(synthex, SyntheXV2)).to.be.revertedWith("2");
		const synthexv2 = SyntheXV2.attach(synthex.address);
		await expect(synthexv2.version()).to.be.revertedWithoutReason();
    });
});