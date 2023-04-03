import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
    takeSnapshot,
    SnapshotRestorer,
    setBalance,
    time,
    impersonateAccount
} from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { SyntheX, EscrowedSYX, SyntheXToken, MockToken } from "../../typechain-types";

const parseEther = ethers.utils.parseEther;
const toBN = ethers.BigNumber.from;
const ZERO_ADDRESS = ethers.constants.AddressZero;
const provider = ethers.provider;

describe("EscrowedSYX", function () {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let charlie: SignerWithAddress;
    let dave: SignerWithAddress;

    let syntheX: SyntheX;
    let esSYX: EscrowedSYX;
    let syx: SyntheXToken;
    let token: MockToken;

    let snapshotA: SnapshotRestorer;

    before(async function () {
        [bob, owner, alice, charlie, dave] = await ethers.getSigners();

        const SyntheX = await ethers.getContractFactory("SyntheX");
        syntheX = (await upgrades.deployProxy(SyntheX, [owner.address, alice.address, bob.address])) as SyntheX;

        const MockToken = await ethers.getContractFactory("MockToken");
        token = (await MockToken.deploy("Test", "TST", 18)) as MockToken;

        const SyntheXToken = await ethers.getContractFactory("SyntheXToken");
        syx = (await SyntheXToken.deploy(syntheX.address)) as SyntheXToken;

        const initialRewardsDuration = 3 * 24 * 60 * 60; // 3 days
        const lockPeriod = 15552000; // 6 months
        const unlockPeriod = 4838400; // 3 months
        const percUnlockAtRelease = 500;

        const EscrowedSYX = await ethers.getContractFactory("EscrowedSYX");
        esSYX = await upgrades.deployProxy(
            EscrowedSYX,
            [
                syntheX.address,
                syx.address,
                token.address,
                initialRewardsDuration,
                lockPeriod,
                unlockPeriod,
                percUnlockAtRelease
            ]
        )  as EscrowedSYX

        snapshotA = await takeSnapshot();
    });

    afterEach(async function () {
        await snapshotA.restore();
    });

    describe("Initialization", function () {
        it("Should initialize correctly", async () => {
            expect(await esSYX.synthex()).to.equal(syntheX.address);
            expect(await esSYX.REWARD_TOKEN()).to.equal(token.address);
            expect(await esSYX.TOKEN()).to.equal(syx.address);
            expect(await esSYX.rewardsDuration()).to.equal(3 * 24 * 60 * 60);
            expect(await esSYX.lockPeriod()).to.equal(15552000);
            expect(await esSYX.unlockPeriod()).to.equal(4838400);
            expect(await esSYX.percUnlockAtRelease()).to.equal(500);
            expect(await esSYX.lastUpdateTime()).to.equal(0);
            expect(await esSYX.periodFinish()).to.equal(0);
            expect(await esSYX.rewardRate()).to.equal(0);
            expect(await esSYX.rewardPerTokenStored()).to.equal(0);
            expect(await esSYX.totalSupply()).to.equal(0);
        });
    });

    describe("Setters", function () {
        it("Should set rewards duration", async () => {
            const days2 = 2 * 24 * 60 * 60;
            await expect(esSYX.connect(alice).setRewardsDuration(days2))
                .to.emit(esSYX, "RewardsDurationUpdated")
                .withArgs(days2);
        });

        it("Shouldn't set rewards duration if rewards period isn't completed", async () => {
            const days2 = 2 * 24 * 60 * 60;
            const days1 = 1 * 24 * 60 * 60;
            await expect(esSYX.connect(alice).setRewardsDuration(days2))
                .to.emit(esSYX, "RewardsDurationUpdated")
                .withArgs(days2);

            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await esSYX.connect(alice).notifyReward(amount);

            await expect(esSYX.connect(alice).setRewardsDuration(days1)).to.be.revertedWith(
                "Previous rewards period must be complete before changing the duration for the new period"
            );
        });

        it("Should set rewards duration only by L2Admin", async () => {
            const days2 = 2 * 24 * 60 * 60;
            await expect(esSYX.connect(bob).setRewardsDuration(days2)).to.be.revertedWith("2");
        });

        it("Should set lock period", async () => {
            const days2 = 2 * 24 * 60 * 60;
            await expect(esSYX.connect(alice).setLockPeriod(days2)).to.emit(esSYX, "SetLockPeriod").withArgs(days2);
            await expect(esSYX.connect(charlie).setLockPeriod(days2)).to.be.revertedWith("2");
        });

        it("Should set lock period only by L2Admin", async () => {
            const days2 = 2 * 24 * 60 * 60;
            await expect(esSYX.connect(charlie).setLockPeriod(days2)).to.be.revertedWith("2");
        });
    });

    describe("Roles", function () {
        it("Should grant and revoke AUTHORIZED_SENDER role", async function () {
            const AUTHORIZED_SENDER = await esSYX.AUTHORIZED_SENDER();
            await esSYX.connect(alice).grantRole(AUTHORIZED_SENDER, dave.address);

            expect(await esSYX.hasRole(AUTHORIZED_SENDER, dave.address)).to.be.true;

            await esSYX.connect(alice).revokeRole(AUTHORIZED_SENDER, dave.address);

            expect(await esSYX.hasRole(AUTHORIZED_SENDER, dave.address)).to.be.false;
        });

        it("Should revert when trying to grant or revoke roles without being L1Admin", async function () {
            const AUTHORIZED_SENDER = await esSYX.AUTHORIZED_SENDER();
            await expect(esSYX.connect(charlie).grantRole(AUTHORIZED_SENDER, dave.address)).to.be.revertedWith(
                "2"
            );

            await esSYX.connect(alice).grantRole(AUTHORIZED_SENDER, dave.address);

            await expect(esSYX.connect(charlie).revokeRole(AUTHORIZED_SENDER, dave.address)).to.be.revertedWith(
                "2"
            );
        });
    });

    describe("Pause/unpause", function () {
        it("Should pause", async () => {
            await expect(esSYX.connect(bob).pause()).to.emit(esSYX, "Paused");
            expect(await esSYX.paused()).to.equal(true);
        });

        it("Should unpause", async () => {
            expect(await esSYX.paused()).to.equal(false);
            await esSYX.connect(bob).pause();
            expect(await esSYX.paused()).to.equal(true);
            await expect(esSYX.connect(bob).unpause()).to.emit(esSYX, "Unpaused");
            expect(await esSYX.paused()).to.equal(false);
        });

        it("Should pause only by L2Admin", async () => {
            await expect(esSYX.connect(charlie).pause()).to.be.revertedWith("3");
        });

        it("Should unpause only by L2Admin", async () => {
            await esSYX.connect(bob).pause();
            await expect(esSYX.connect(charlie).unpause()).to.be.revertedWith("3");
        });

        it("Shouldn't call specified functions when paused", async () => {
            await esSYX.connect(bob).pause();
            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await expect(esSYX.connect(alice).getReward()).to.be.revertedWith("Pausable: paused");
            await expect(esSYX.connect(alice).lock(amount, charlie.address)).to.be.revertedWith("Pausable: paused");
            await expect(esSYX.connect(alice).startUnlock(amount)).to.be.revertedWith("Pausable: paused");
        });
    });

    describe("Rewards operations", function () {
        it("Should notify reward", async () => {
            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await expect(esSYX.connect(alice).notifyReward(amount)).to.emit(esSYX, "RewardAdded").withArgs(amount);
            expect(await esSYX.rewardRate()).to.equal(amount.div(3 * 24 * 60 * 60));
            expect(await esSYX.lastUpdateTime()).to.equal(await time.latest());
            expect(await esSYX.periodFinish()).to.equal((await time.latest()) + 3 * 24 * 60 * 60);
        });

        it("Should notify reward during rewards period", async () => {
            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await expect(esSYX.connect(alice).notifyReward(amount)).to.emit(esSYX, "RewardAdded").withArgs(amount);
            const rewardRate = await esSYX.rewardRate();
            expect(await esSYX.rewardRate()).to.equal(amount.div(3 * 24 * 60 * 60));
            expect(await esSYX.lastUpdateTime()).to.equal(await time.latest());
            expect(await esSYX.periodFinish()).to.equal((await time.latest()) + 3 * 24 * 60 * 60);

            await time.increase(1 * 24 * 60 * 60);
            await expect(esSYX.connect(alice).notifyReward(amount)).to.emit(esSYX, "RewardAdded").withArgs(amount);
            expect(await esSYX.rewardRate()).to.not.equal(rewardRate);
            expect(await esSYX.lastUpdateTime()).to.equal(await time.latest());
            expect(await esSYX.periodFinish()).to.equal((await time.latest()) + 3 * 24 * 60 * 60);
        });

        it("Should get amount of reward for duration", async () => {
            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await esSYX.connect(alice).notifyReward(amount);
            expect(await esSYX.getRewardForDuration()).to.not.equal(0);
        });

        it("Should get reward per token", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await esSYX.connect(alice).notifyReward(amount);

            await time.increase(5 * 24 * 60 * 60);

            expect(await esSYX.rewardPerToken()).to.not.equal(0);
        });

        it("Should get reward", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            const amount = parseEther("1000");
            await token.mint(esSYX.address, amount);
            await esSYX.connect(alice).notifyReward(amount);

            await time.increase(5 * 24 * 60 * 60);

            expect(await esSYX.earned(charlie.address)).to.not.equal(0);

            await expect(esSYX.connect(charlie).getReward()).to.emit(esSYX, "RewardPaid");

            expect(await token.balanceOf(charlie.address)).to.be.closeTo(parseEther("1000"), parseEther("1"));
            expect(await esSYX.rewards(charlie.address)).to.equal(0);
            expect(await esSYX.earned(charlie.address)).to.equal(0);
        });

        it("Shouldn't get reward if notifyReward was't called", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);
            
            await time.increase(5 * 24 * 60 * 60);

            await expect(esSYX.connect(charlie).getReward()).to.not.emit(esSYX, "RewardPaid");

            expect(await token.balanceOf(charlie.address)).to.equal(0);
        });
    });

    describe("Syx operations", function () {
        it("Should lock", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            expect(await esSYX.balanceOf(charlie.address)).to.equal(parseEther("100"));
            expect(await esSYX.totalSupply()).to.equal(parseEther("100"));
            expect(await syx.balanceOf(esSYX.address)).to.equal(parseEther("100"));
            expect(await syx.balanceOf(charlie.address)).to.equal(parseEther("900"));
        });

        it("Should start unlock", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            const unlockAmount = parseEther("100");

            // Create a filter for the UnlockRequested event
            const filter = esSYX.filters.UnlockRequested(charlie.address, null, null);

            await esSYX.connect(charlie).startUnlock(unlockAmount);

            // Query the latest event from the contract using the filter
            const events = await esSYX.queryFilter(filter, "latest");
            const event = events[0];
            const requestId = event.args[1];

            expect(await esSYX.balanceOf(charlie.address)).to.equal(0);
            expect(await syx.balanceOf(charlie.address)).to.equal(parseEther("900"));

            const unlockRequest = await esSYX.unlockRequests(requestId);
            expect(unlockRequest.amount).to.equal(unlockAmount);
            expect(unlockRequest.claimed).to.equal(0);
            expect(unlockRequest.requestTime).to.be.closeTo(await time.latest(), 5);

            expect(await esSYX.reservedForUnlock()).to.equal(unlockAmount);
        });

        it("Should claim unlocked with 3 requests", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            const unlockAmount = parseEther("30");

            // Create a filter for the UnlockRequested event
            const filter = esSYX.filters.UnlockRequested(charlie.address, null, null);

            await esSYX.connect(charlie).startUnlock(unlockAmount);

            // Query the latest event from the contract using the filter
            let events = await esSYX.queryFilter(filter, "latest");
            let event = events[0];
            const requestId1 = event.args[1];

            await esSYX.connect(charlie).startUnlock(unlockAmount);

            events = await esSYX.queryFilter(filter, "latest");
            event = events[0];
            const requestId2 = event.args[1];

            await esSYX.connect(charlie).startUnlock(unlockAmount);

            events = await esSYX.queryFilter(filter, "latest");
            event = events[0];
            const requestId3 = event.args[1];

            const lockPeriod = 15552000; // 6 months
            const unlockPeriod = 4838400; // 3 months
            await time.increase(lockPeriod + unlockPeriod);

            await expect(esSYX.connect(charlie).claimUnlocked([requestId1, requestId2, requestId3])).to.emit(
                esSYX,
                "Unlocked"
            );

            expect(await esSYX.balanceOf(charlie.address)).to.equal(parseEther("10"));
            expect(await syx.balanceOf(charlie.address)).to.be.gt(unlockAmount.mul(3)); //990 `100`
            expect(await esSYX.reservedForUnlock()).to.be.eq(0);

            await esSYX.connect(bob).pause();
            await expect(esSYX.connect(bob).claimUnlocked([requestId1, requestId2, requestId3])).to.be.revertedWith(
                "Pausable: paused"
            );
        });
    });

    describe("Transfer operations", function () {
        it("Should transfer esSYX only by authorized senders", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            const AUTHORIZED_SENDER = await esSYX.AUTHORIZED_SENDER();
            await esSYX.connect(alice).grantRole(AUTHORIZED_SENDER, charlie.address);

            await expect(esSYX.connect(charlie).transfer(alice.address, parseEther("10"))).to.emit(
                esSYX,
                "Transfer"
            );

            expect(await esSYX.balanceOf(charlie.address)).to.equal(parseEther("90"));
            expect(await esSYX.balanceOf(alice.address)).to.equal(parseEther("10"));
        });

        it("Shouldn't transfer esSYX if sender is not authorized", async () => {
            await syx.connect(alice).mint(charlie.address, parseEther("1000"));
            await syx.connect(charlie).approve(esSYX.address, parseEther("1000"));

            await esSYX.connect(charlie).lock(parseEther("100"), charlie.address);

            await expect(esSYX.connect(charlie).transfer(alice.address, parseEther("10"))).to.be.revertedWith(
                "16"
            );
        });
    });
});
