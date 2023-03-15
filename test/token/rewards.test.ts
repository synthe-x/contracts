import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { MINTER_ROLE } from '../../scripts/utils/const';

describe("Testing Staking Rewards", function () {
	let esSYX: any, SYX: any, WETH: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		SYX = deployments.SYX;
		esSYX = deployments.esSYX;
		WETH = deployments.WETH;
		
		// 10 WETH for owner to add reward
		await WETH.connect(owner).deposit({ value: ethers.utils.parseEther("10") });
	});

	it("add 10 WETH reward for 1 year", async function () {
		// add reward tokens
		await WETH.connect(owner).transfer(esSYX.address, ethers.utils.parseEther("10"));
		// set reward duration
		await esSYX.connect(owner).setRewardsDuration(ethers.BigNumber.from("31536000"));
		await esSYX.connect(owner).notifyReward(ethers.utils.parseEther("1000"));
		expect(await esSYX.rewardRate()).to.equal(
			ethers.utils
				.parseEther("1000")
				.div(ethers.BigNumber.from("31536000"))
		);
	});

	it("user1 should have 1000 esSYX", async function () {
		// 1000 esSYX for user1
		await SYX.mint(user1.address, ethers.utils.parseEther("1000"));
		await SYX.connect(user1).increaseAllowance(esSYX.address, ethers.utils.parseEther("1000"));
		await esSYX.connect(user1).lock(ethers.utils.parseEther("1000"), user1.address);

		expect(await esSYX.balanceOf(user1.address)).to.equal(
			ethers.utils.parseEther("1000")
		);
	});

	it("view reward APY should be 100%", async function () {
		// _totalSupply
		expect(await esSYX.totalSupply()).to.equal(
			ethers.utils.parseEther("1000")
		);

		// calculated APY
        const rewardRate = Number(ethers.utils.formatEther(await esSYX.rewardRate()));
        const totalSupply = Number(ethers.utils.formatEther(await esSYX.totalSupply()));

        expect(rewardRate * 365*24*60*60 / totalSupply).to.be.closeTo(1, 10e-8)
	});

    it("user2 should stake 500 syn", async function () {
		// 500 esSYX for user2
		await SYX.mint(user2.address, ethers.utils.parseEther("500"));
		await SYX.connect(user2).increaseAllowance(esSYX.address, ethers.utils.parseEther("500"));
		await esSYX.connect(user2).lock(ethers.utils.parseEther("500"), user2.address);
	});

	it("view reward APY 66%", async function () {
        // _totalSupply
		expect(await esSYX.totalSupply()).to.equal(
            ethers.utils.parseEther("1500")
        );

        // calculated APY
        const rewardRate = Number(ethers.utils.formatEther(await esSYX.rewardRate()));
        const totalSupply = Number(ethers.utils.formatEther(await esSYX.totalSupply()));

        expect(rewardRate * 365*24*60*60 / totalSupply).to.be.closeTo(2/3, 10e-8)
	});
});
