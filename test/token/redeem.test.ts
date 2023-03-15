import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { MINTER_ROLE } from '../../scripts/utils/const';
import { ERRORS } from "../../scripts/utils/errors";

describe("Testing unlocker", function () {

	let SYX: any, esSYX: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

		const deployments = await loadFixture(main);
        SYX = deployments.SYX;
        esSYX = deployments.esSYX;

        await SYX.connect(user1).increaseAllowance(esSYX.address, ethers.constants.MaxUint256);
        await SYX.connect(user2).increaseAllowance(esSYX.address, ethers.constants.MaxUint256);
	});

    it("unlock should fail if esSYX balance is 0", async function () {
        await expect(esSYX.connect(user1).startUnlock(ethers.utils.parseEther('100'))).to.be.revertedWith("ERC20: burn amount exceeds balance");
    })

    it("user1 gets 1000 esSYX", async function () {
        await SYX.mint(user1.address, ethers.utils.parseEther('1000'));
        await esSYX.connect(user1).lock(ethers.utils.parseEther('1000'), user1.address);
    })

    it("user1 should be able to start unlock of 100 tokens", async function () {
        // user1 starts unlock
        await esSYX.connect(user1).startUnlock(ethers.utils.parseEther('100'));
        // check unlocker quota. 100 tokens should be reserved for user1
        expect(await esSYX.remainingQuota()).to.equal(ethers.utils.parseEther('900'));
        // check user1 balance should be 1000 (initial) - 100 (send to unlock) = 900
        expect(await esSYX.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('900'));
    })

    it("user2 will start unlock of 250 tokens", async function () {
        // NOTE: past 7 days 
        await time.increase(86400 * 7);
        // user1 starts unlock
        await esSYX.connect(user1).startUnlock(ethers.utils.parseEther('250'));
        // check unlocker quota. 100 tokens should be reserved for user1
        expect(await esSYX.remainingQuota()).to.equal(ethers.utils.parseEther('650'));
        // check user1 balance should be 1000 (initial) - 100 (send to unlock) = 900
        expect(await esSYX.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('650'));
        // check user1 syx balance
        expect(await SYX.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('0'));
    })

    it("index0: unlock after lockPeriod, 0th of unlockPeriod, expect 5% to unlock", async function () {
        // NOTE: past 6 months
        await time.increase(86400 * 173);
        // keccak256(abi.encodePacked(address, uint256))
        const requestId = await esSYX.getRequestId(user1.address, '0');
        // 5% of 100 tokens
        const expectedToUnlock = await esSYX.unlocked(requestId);
        expect(expectedToUnlock).to.be.closeTo(ethers.utils.parseEther('5'), ethers.utils.parseEther('0.001'));

        await esSYX.connect(user1).claimUnlocked([requestId]);
        const unlockData = await esSYX.unlockRequests(requestId);
        expect(unlockData.claimed).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));
        // check user1 balance
        expect(await SYX.balanceOf(user1.address)).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));
    })

    it("index1: should not able to unlock", async function () {
        const requestId = ethers.utils.solidityKeccak256(['address', 'uint256'], [user1.address, '1']);
        await expect(esSYX.connect(user1).claimUnlocked([requestId])).to.be.revertedWith(ERRORS.UNLOCK_NOT_STARTED);
    })

    it("index0: unlock after lockPeriod, 60/180 of unlockPeriod", async function () {
        // NOTE: past 8 months (2 months past first unlock)
        await time.increase(86400 * 60);
        // keccak256(abi.encodePacked(address, uint256))
        const requestId = await esSYX.getRequestId(user1.address, '0');
        // 5% of 100 tokens + 95% of 100 tokens * 1/3
        const expectedToUnlock = await esSYX.unlocked(requestId);
        expect(expectedToUnlock).to.be.closeTo((ethers.utils.parseEther((0.95 * 100 * 1/3).toFixed(18))), ethers.utils.parseEther('0.001'));
        await esSYX.connect(user1).claimUnlocked([requestId]);

        // check claimed amount
        const unlockData = await esSYX.unlockRequests(requestId);
        expect(unlockData.claimed).to.be.closeTo(expectedToUnlock.add(ethers.utils.parseEther('5')), ethers.utils.parseEther('0.001'));

        // check user1 balance
        expect(await SYX.balanceOf(user1.address)).to.be.closeTo(expectedToUnlock.add(ethers.utils.parseEther('5')), ethers.utils.parseEther('0.001'));
    })

    it("index1: unlock after lockPeriod, 53/180th of unlockPeriod", async function () {
        const initialBalance = await SYX.balanceOf(user1.address);
        // 5 % of 250 tokens + 95% of 250 tokens * 53/180
        const expectedToUnlock = ethers.utils.parseEther((0.05 * 250).toFixed(18)).add(ethers.utils.parseEther((0.95 * 250 * 53/180).toFixed(18)));

        const requestId = await esSYX.getRequestId(user1.address, '1');
        await esSYX.connect(user1).claimUnlocked([requestId]);

        // check claimed amount
        const unlockData = await esSYX.unlockRequests(requestId);
        expect(unlockData.claimed).to.be.closeTo(expectedToUnlock, ethers.utils.parseEther('0.001'));

        // check user1 balance
        expect(await SYX.balanceOf(user1.address)).to.be.closeTo(initialBalance.add(expectedToUnlock), ethers.utils.parseEther('0.001'));
    })
});