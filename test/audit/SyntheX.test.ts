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
import { SyntheX, Pool, MockToken } from "../../typechain-types";
import { synthex } from "../../typechain-types/contracts";

const parseEther = ethers.utils.parseEther;
const toBN = ethers.BigNumber.from;
const ZERO_ADDRESS = ethers.constants.AddressZero;
const provider = ethers.provider;

describe.only("SyntheX", function () {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let charlie: SignerWithAddress;

    let syntheX: SyntheX;
    let pool: Pool;
    let token: MockToken;

    let snapshotA: SnapshotRestorer;

    before(async function () {
        [owner, alice, bob, charlie] = await ethers.getSigners();

        const SyntheX = await ethers.getContractFactory("SyntheX");
        syntheX = (await upgrades.deployProxy(SyntheX, [owner.address, alice.address, bob.address])) as SyntheX;

        const Pool = await ethers.getContractFactory("Pool");
        pool = (await upgrades.deployProxy(Pool.connect(bob), ["Test", "TST", syntheX.address])) as Pool;

        const MockToken = await ethers.getContractFactory("MockToken");
        token = (await MockToken.deploy("Test", "TST", 18)) as MockToken;

        snapshotA = await takeSnapshot();
    });

    afterEach(async function () {
        await snapshotA.restore();
    });

    describe("Initialization", function () {
        it("Should initialize correctly", async () => {
            expect(await syntheX.isL0Admin(owner.address)).to.equal(true);
            expect(await syntheX.isL1Admin(alice.address)).to.equal(true);
            expect(await syntheX.isL2Admin(bob.address)).to.equal(true);
        });
    });

    describe("Setters", function () {
        it("Should set address", async () => {
            const key = ethers.utils.formatBytes32String("exampleKey");
            const value = charlie.address;

            await expect(syntheX.connect(alice).setAddress(key, value))
                .to.emit(syntheX, "AddressUpdated")
                .withArgs(key, value);

            const storedAddress = await syntheX.connect(alice).getAddress(key);
            expect(storedAddress).to.equal(value);
        });
    });

    describe("Pause/unpause", function () {
        it("Should pause and unpause contract", async () => {
            await syntheX.connect(bob).pause();
            expect(await syntheX.paused()).to.equal(true);
            await syntheX.connect(bob).unpause();
            expect(await syntheX.paused()).to.equal(false);
        });

        it("Shouldn't pause and unpause contract by everyone but L2Admin", async () => {
            await expect(syntheX.connect(alice).pause()).to.be.revertedWith("3");
            await expect(syntheX.connect(charlie).pause()).to.be.revertedWith("3");
        });
    });

    describe("Rewards operations", function () {
        it("Should set pool speed with adding reward token to list", async () => {
            const speed = 100;
            const addToList = true;

            await expect(syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList))
                .to.emit(syntheX, "SetPoolRewardSpeed")
                .withArgs(token.address, pool.address, speed);

            expect(await syntheX.rewardSpeeds(token.address, pool.address)).to.equal(speed);
            expect(await syntheX.rewardTokens(pool.address, 0)).to.equal(token.address);
        });

        it("Should set pool speed without adding reward token to list", async () => {
            const speed = 100;
            const addToList = true;

            await syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList);
            expect(await syntheX.rewardSpeeds(token.address, pool.address)).to.equal(speed);
            expect(await syntheX.rewardTokens(pool.address, 0)).to.equal(token.address);

            const speed2 = 200;
            await syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed2, !addToList);

            expect(await syntheX.rewardSpeeds(token.address, pool.address)).to.equal(speed2);
            expect(await syntheX.rewardTokens(pool.address, 0)).to.equal(token.address);
        });

        it("Shouldn't set pool speed if reward token already added but param addToList is true", async () => {
            const speed = 100;
            const addToList = true;

            await syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList);
            await expect(
                syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList)
            ).to.be.revertedWith("14");
        });

        it("Should remove reward token from list", async () => {
            const speed = 100;
            const addToList = true;

            await syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList);
            await syntheX.connect(bob).removeRewardToken(token.address, pool.address);
            await syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList);

            expect(await syntheX.rewardTokens(pool.address, 0)).to.equal(token.address);
            expect(await syntheX.rewardSpeeds(token.address, pool.address)).to.equal(speed);
        });

        it("Should update pool reward index", async () => {
            const speed = 100;
            const addToList = true;
            await syntheX.connect(bob).setPoolSpeed(token.address, pool.address, speed, addToList);

            await impersonateAccount(pool.address);
            const poolSigner = await ethers.getSigner(pool.address);
            await setBalance(pool.address, parseEther("1000"));

            const poolRewardStateBefore = await syntheX.rewardState(token.address, pool.address);
            let latestTime = await time.latest();
            expect(poolRewardStateBefore.index).to.equal(0);
            expect(poolRewardStateBefore.timestamp).to.equal(latestTime);

            const totalSupply = parseEther("100");
            await syntheX.connect(poolSigner)["distribute(uint256)"](totalSupply);

            const days2 = 172800;
            await time.increase(days2);

            await syntheX.connect(poolSigner)["distribute(uint256)"](totalSupply);
            const poolRewardState = await syntheX.rewardState(token.address, pool.address);
            latestTime = await time.latest();
            expect(poolRewardState.index).to.not.equal(0);
            expect(poolRewardState.timestamp).to.equal(latestTime);
        });
    });
});
