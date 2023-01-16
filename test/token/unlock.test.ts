// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import initiate from "../../scripts/test";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Testing unlocker", function () {

	let token: any, sealed: any, unlockerContract: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

		const TokenUnlocker = await ethers.getContractFactory("TokenUnlocker");
        const erc20 = await ethers.getContractFactory("MockToken");
        const erc20Sealed = await ethers.getContractFactory("SealedSYN");
        token = await erc20.deploy("Token", "TOKEN");
        sealed = await erc20Sealed.deploy(owner.address);
        unlockerContract = await TokenUnlocker.deploy(sealed.address, token.address, 86400 * 30, 86400 * 60, 0);

        // grant MINTER_ROLE to owner
        await sealed.grantRole(await sealed.MINTER_ROLE(), owner.address);
        // give sealed tokens to user1
        await sealed.mint(user1.address, ethers.utils.parseEther('1000'));
	});

    it("unlock should fail if token balance is 0", async function () {
        await expect(unlockerContract.connect(user1).startUnlock(ethers.utils.parseEther('100'))).to.be.revertedWith("Not enough SYN to unlock");
    })

    it("owner adds token to unlocker", async function () {
        // mint 1000 tokens to owner
        await token.mint(owner.address, ethers.utils.parseEther('1000'));
        expect(await token.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('1000'));
        // owner transfers 1000 tokens to unlocker
        await token.connect(owner).transfer(unlockerContract.address, ethers.utils.parseEther('1000'));
        // check unlocker quota
        expect(await unlockerContract.remainingQuota()).to.equal(ethers.utils.parseEther('1000'));
    })

    it("user1 should be able to start unlock of 100 tokens", async function () {
        // user1 approves unlocker to spend 100 tokens
        await sealed.connect(user1).approve(unlockerContract.address, ethers.utils.parseEther('100'));
        // user1 starts unlock
        await unlockerContract.connect(user1).startUnlock(ethers.utils.parseEther('100'));
        // check unlocker quota. 100 tokens should be reserved for user1
        expect(await unlockerContract.remainingQuota()).to.equal(ethers.utils.parseEther('900'));
        // check user1 balance should be 1000 (initial) - 100 (send to unlock) = 900
        expect(await sealed.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('900'));
    })

    it("user1 should be able to start unlock of 250 tokens after 7 days", async function () {
        // NOTE: past 7 days 
        await time.increase(86400 * 7);
        // user1 approves unlocker to spend 100 tokens
        await sealed.connect(user1).approve(unlockerContract.address, ethers.utils.parseEther('250'));
        // user1 starts unlock
        await unlockerContract.connect(user1).startUnlock(ethers.utils.parseEther('250'));
        // check unlocker quota. 100 tokens should be reserved for user1
        expect(await unlockerContract.remainingQuota()).to.equal(ethers.utils.parseEther('650'));
        // check user1 balance should be 1000 (initial) - 100 (send to unlock) = 900
        expect(await sealed.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('650'));
    })

    it("index0: unlock after lockPeriod, 0th of unlockPeriod", async function () {
        // NOTE: past 30 days
        await time.increase(86400 * 23);
        const expectedToUnlock = ethers.utils.parseEther('0');
        // keccak256(abi.encodePacked(address, uint256))
        const requestId = await unlockerContract.getRequestId(user1.address, '0');
        await unlockerContract.connect(user1).unlock([requestId]);
        const unlockData = await unlockerContract.unlockRequests(requestId);
        expect(unlockData.claimed).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));
    })

    it("index1: should not able to unlock", async function () {
        const requestId = await unlockerContract.getRequestId(user1.address, '1');
        await expect(unlockerContract.connect(user1).unlock([requestId])).to.be.revertedWith("Unlock period has not passed");
    })

    it("index0: unlock after lockPeriod, 1/3rd of unlockPeriod", async function () {
        // NOTE: past 50 days (20 past first unlock)
        await time.increase(86400 * 20);
        const expectedToUnlock = ethers.utils.parseEther((100 * 20/60).toFixed(10));
        // keccak256(abi.encodePacked(address, uint256))
        const requestId = await unlockerContract.getRequestId(user1.address, '0');
        await unlockerContract.connect(user1).unlock([requestId]);

        // check claimed amount
        const unlockData = await unlockerContract.unlockRequests(requestId);
        expect(unlockData.claimed).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));

        // check user1 balance
        expect(await token.balanceOf(user1.address)).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));
    })

    it("index1: unlock after lockPeriod, 14/60th of unlockPeriod", async function () {
        const initialBalance = await token.balanceOf(user1.address);
        const expectedToUnlock = ethers.utils.parseEther((250 * 13/60).toFixed(10));
        // keccak256(abi.encodePacked(address, uint256))
        const requestId = await unlockerContract.getRequestId(user1.address, '1');
        await unlockerContract.connect(user1).unlock([requestId]);

        // check claimed amount
        const unlockData = await unlockerContract.unlockRequests(requestId);
        expect(unlockData.claimed).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));

        // check user1 balance
        expect(await token.balanceOf(user1.address)).to.be.closeTo(initialBalance.add(expectedToUnlock), ethers.utils.parseEther('0.001'));
    })
});