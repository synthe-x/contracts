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

describe("SyntheXToken", function () {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let charlie: SignerWithAddress;
    let dave: SignerWithAddress;

    let syntheX: SyntheX;
    let syx: SyntheXToken;

    let snapshotA: SnapshotRestorer;

    before(async function () {
        [bob, owner, alice, charlie, dave] = await ethers.getSigners();

        const SyntheX = await ethers.getContractFactory("SyntheX");
        syntheX = (await upgrades.deployProxy(SyntheX, [owner.address, alice.address, bob.address])) as SyntheX;

        const SyntheXToken = await ethers.getContractFactory("SyntheXToken");
        syx = (await SyntheXToken.deploy(syntheX.address)) as SyntheXToken;

        snapshotA = await takeSnapshot();
    });

    afterEach(async function () {
        await snapshotA.restore();
    });

    describe("Initialization", function () {
        it("Should correctly initialize SyntheXToken contract", async () => {
            expect(await syx.name()).to.equal("SyntheX Token");
            expect(await syx.symbol()).to.equal("SYX");
            expect(await syx.decimals()).to.equal(18);
        });
    });

    describe("Minting", function () {
        it("Should allow L1Admin to mint tokens", async () => {
            await syx.connect(alice).mint(dave.address, ethers.utils.parseEther("1000"));
            expect(await syx.balanceOf(dave.address)).to.equal(ethers.utils.parseEther("1000"));
        });

        it("Should not allow non-L1Admin to mint tokens", async () => {
            await expect(syx.connect(dave).mint(dave.address, ethers.utils.parseEther("1000"))).to.be.revertedWith(
                "2"
            );
        });
    });

    describe("Pause/Unpause", function () {
        it("Should allow L2Admin to pause and unpause the contract", async () => {
            await syx.connect(bob).pause();
            expect(await syx.paused()).to.be.true;
            await syx.connect(bob).unpause();
            expect(await syx.paused()).to.be.false;
        });
        it("Should not allow non-L2Admin to pause and unpause the contract", async () => {
            await expect(syx.connect(dave).pause()).to.be.revertedWith("3");
            await expect(syx.connect(dave).unpause()).to.be.revertedWith("3");
        });

        it("Should not allow transfers when paused", async () => {
            await syx.connect(alice).mint(dave.address, ethers.utils.parseEther("1000"));
            await syx.connect(bob).pause();
            await expect(
                syx.connect(dave).transfer(charlie.address, ethers.utils.parseEther("100"))
            ).to.be.revertedWith("Pausable: paused");
            await syx.connect(bob).unpause();
            await syx.connect(dave).transfer(charlie.address, ethers.utils.parseEther("100"));
            expect(await syx.balanceOf(charlie.address)).to.equal(ethers.utils.parseEther("100"));
        });
    });
});
