import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";

describe("Testing Staking Rewards", function () {
	let sealedSyn: any, syn: any, stakingRewards: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		syn = deployments.syn;
		sealedSyn = deployments.sealedSYN;
		stakingRewards = deployments.stakingRewards;

		await sealedSyn.grantMinterRole(owner.address);
		// for user1 to stake
		await sealedSyn.mint(user1.address, ethers.utils.parseEther("10000"));
        // for user2 to stake
		await sealedSyn.mint(user2.address, ethers.utils.parseEther("10000"));
		// for owner to add reward
		await syn.mint(owner.address, ethers.utils.parseEther("10000"));
	});

	it("add 1000 syn reward for 1 year", async function () {
		await syn
			.connect(owner)
			.approve(stakingRewards.address, ethers.utils.parseEther("1000"));
		await stakingRewards
			.connect(owner)
			.setRewardsDuration(ethers.BigNumber.from("31536000"));
		await stakingRewards
			.connect(owner)
			.notifyReward(ethers.utils.parseEther("1000"));
		expect(await stakingRewards.rewardRate()).to.equal(
			ethers.utils
				.parseEther("1000")
				.div(ethers.BigNumber.from("31536000"))
		);
	});

	it("user1 should stake 1000 syn", async function () {
		await sealedSyn
			.connect(user1)
			.approve(stakingRewards.address, ethers.utils.parseEther("1000"));
		await stakingRewards
			.connect(user1)
			.stake(ethers.utils.parseEther("1000"));
		expect(await stakingRewards.balanceOf(user1.address)).to.equal(
			ethers.utils.parseEther("1000")
		);
	});

	it("view reward APY should be 100%", async function () {
		// _totalSupply
		expect(await stakingRewards.totalSupply()).to.equal(
			ethers.utils.parseEther("1000")
		);

		// calculated APY
        const rewardRate = Number(ethers.utils.formatEther(await stakingRewards.rewardRate()));
        const totalSupply = Number(ethers.utils.formatEther(await stakingRewards.totalSupply()));

        expect(rewardRate * 365*24*60*60 / totalSupply).to.be.closeTo(1, 10e-8)

	});

    it("user2 should stake 500 syn", async function () {
		await sealedSyn
			.connect(user2)
			.approve(stakingRewards.address, ethers.utils.parseEther("500"));
		await stakingRewards
			.connect(user2)
			.stake(ethers.utils.parseEther("500"));
		expect(await stakingRewards.balanceOf(user2.address)).to.equal(
			ethers.utils.parseEther("500")
		);
	});

	it("view reward APY 66%", async function () {
        // _totalSupply
		expect(await stakingRewards.totalSupply()).to.equal(
            ethers.utils.parseEther("1500")
        );

        // calculated APY
        const rewardRate = Number(ethers.utils.formatEther(await stakingRewards.rewardRate()));
        const totalSupply = Number(ethers.utils.formatEther(await stakingRewards.totalSupply()));

        expect(rewardRate * 365*24*60*60 / totalSupply).to.be.closeTo(2/3, 10e-8)
	});
});
