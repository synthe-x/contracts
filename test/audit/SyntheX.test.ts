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
import { SyntheX, Pool, MockToken, EscrowedSYX, SyntheXToken } from "../../typechain-types";
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
    let dave: SignerWithAddress;

    let syntheX: SyntheX;
    let pool: Pool;
    let token: MockToken;
    let syx: SyntheXToken;
    let esSYX: EscrowedSYX;

    let snapshotA: SnapshotRestorer;

    before(async function () {
        [owner, alice, bob, charlie, dave] = await ethers.getSigners();

        const SyntheX = await ethers.getContractFactory("SyntheX");
        syntheX = (await upgrades.deployProxy(SyntheX, [owner.address, alice.address, bob.address])) as SyntheX;

        const Pool = await ethers.getContractFactory("Pool");
        pool = (await upgrades.deployProxy(Pool.connect(bob), ["Test", "TST", syntheX.address])) as Pool;

        const MockToken = await ethers.getContractFactory("MockToken");
        token = (await MockToken.deploy("Test", "TST", 18)) as MockToken;

        const SyntheXToken = await ethers.getContractFactory("SyntheXToken");
        syx = (await SyntheXToken.deploy(syntheX.address)) as SyntheXToken;

        const initialRewardsDuration = 3 * 24 * 60 * 60; // 3 days
        const lockPeriod = 15552000; // 6 months
        const unlockPeriod = 4838400; // 3 months
        const percUnlockAtRelease = 500;

        const EscrowedSYX = await ethers.getContractFactory("EscrowedSYX");
        esSYX = (await EscrowedSYX.deploy(
            syntheX.address,
            syx.address,
            token.address,
            initialRewardsDuration,
            lockPeriod,
            unlockPeriod,
            percUnlockAtRelease
        )) as EscrowedSYX;

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

        it("Shouldn't call specified any function when paused", async () => {
            await syntheX.connect(bob).pause();
            await expect(
                syntheX.connect(bob)["distribute(address,uint256,uint256)"](token.address, 100, 100)
            ).to.be.revertedWith("Pausable: paused");
            await expect(syntheX.connect(bob)["distribute(uint256)"](100)).to.be.revertedWith("Pausable: paused");
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

        it("Should claim rewards", async () => {
            // setup vault
            const Vault = await ethers.getContractFactory("Vault");
            const vault = await Vault.deploy(syntheX.address);
            const VAULT = ethers.utils.id("VAULT");
            await syntheX.connect(alice).setAddress(VAULT, vault.address);

            // supply reward token
            await syx.connect(alice).mint(owner.address, ethers.utils.parseEther("100000000"));
            await syx.increaseAllowance(esSYX.address, ethers.utils.parseEther("100000000"));
            await esSYX.lock(ethers.utils.parseEther("100000000"), syntheX.address);

            // set pool speed
            const speed = parseEther("10");
            const addToList = true;
            await syntheX.connect(bob).setPoolSpeed(esSYX.address, pool.address, speed, addToList);

            // deposit eth to pool
            await pool.connect(bob).unpause();
            await pool.connect(alice).setIssuerAlloc(500);

            const ERC20X = await ethers.getContractFactory("ERC20X");
            const synth = await upgrades.deployProxy(ERC20X, ["Ethereum", "ETH", pool.address, syntheX.address], {
                unsafeAllow: ["delegatecall"]
            });
            const mintFee = 4;
            const burnFee = 6;
            await pool.connect(alice).addSynth(synth.address, mintFee, burnFee);

            const WETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
            const collateral = await ethers.getContractAt("MockToken", WETH);

            const params = {
                cap: "100000000000000000000000",
                baseLTV: "8000",
                liqThreshold: "9000",
                liqBonus: "10500",
                isActive: true,
                totalDeposits: 0
            };

            const MockPriceFeed = await ethers.getContractFactory("MockPriceFeed");
            const feed = await MockPriceFeed.deploy(parseEther("0.000000001"), 18);

            const PriceOracle = await ethers.getContractFactory("PriceOracle");
            const oracle = await PriceOracle.deploy(
                syntheX.address,
                [collateral.address, synth.address],
                [feed.address, feed.address],
                ZERO_ADDRESS,
                ZERO_ADDRESS,
                1e8
            );

            await pool.connect(alice).setPriceOracle(oracle.address);
            await pool.connect(alice).setFeeToken(synth.address);

            await pool.connect(alice).updateCollateral(collateral.address, params);

            await pool.connect(charlie).depositETH({ value: parseEther("5") });
            expect((await pool.getAccountLiquidity(charlie.address))[1]).to.equal(parseEther("50"));

            await pool.connect(dave).depositETH({ value: parseEther("1") });
            expect((await pool.getAccountLiquidity(dave.address))[1]).to.equal(parseEther("10"));

            // issues synth
            await synth.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            expect((await pool.getAccountLiquidity(charlie.address))[2]).to.be.not.equal(0);

            await synth.connect(dave).mint(ethers.utils.parseEther("20"), dave.address, ZERO_ADDRESS);
            expect((await pool.getAccountLiquidity(dave.address))[2]).to.be.not.equal(0);

            // 2 days
            await time.increase(172800);

            // get reward accrued
            const charlieRewards = await syntheX.callStatic.getRewardsAccrued([esSYX.address], charlie.address, [
                pool.address
            ]);
            const daveRewards = await syntheX.callStatic.getRewardsAccrued([esSYX.address], dave.address, [
                pool.address
            ]);

            expect(await esSYX.balanceOf(charlie.address)).to.be.equal(0);
            expect(await esSYX.balanceOf(dave.address)).to.be.equal(0);

            expect(charlieRewards[0]).to.be.not.equal(0);
            expect(daveRewards[0]).to.be.not.equal(0);

            // give role for esSYX transfer
            const AUTHORIZED_SENDER = await esSYX.AUTHORIZED_SENDER();
            await esSYX.connect(alice).grantRole(AUTHORIZED_SENDER, syntheX.address);

            // claim rewards
            await syntheX.connect(alice).claimReward([esSYX.address], charlie.address, [pool.address]);
            await syntheX.connect(alice).claimReward([esSYX.address], dave.address, [pool.address]);

            expect(await esSYX.balanceOf(charlie.address)).to.be.not.equal(0);
            expect(await esSYX.balanceOf(dave.address))
                .to.be.lt(await esSYX.balanceOf(charlie.address))
                .and.to.be.not.equal(0);
        });

        it("Should claim rewards with 2 pools (collecting rewards from a pool they don't belong to)", async () => {
            // setup vault
            const Vault = await ethers.getContractFactory("Vault");
            const vault = await Vault.deploy(syntheX.address);
            const VAULT = ethers.utils.id("VAULT");
            await syntheX.connect(alice).setAddress(VAULT, vault.address);

            // setup 2 pools
            const Pool2 = await ethers.getContractFactory("Pool");
            const pool1 = (await upgrades.deployProxy(Pool2.connect(bob), ["Test1", "TST1", syntheX.address])) as Pool;
            const pool2 = (await upgrades.deployProxy(Pool2.connect(bob), ["Test2", "TST2", syntheX.address])) as Pool;

            // setup 3 gifferent reward tokens for 3 pools
            const MockToken = await ethers.getContractFactory("MockToken");
            const rewardToken1 = await MockToken.deploy("Reward Token 1", "RT1", 18);
            const rewardToken2 = await MockToken.deploy("Reward Token 2", "RT2", 18);
            const rewardToken3 = await MockToken.deploy("Reward Token 3", "RT3", 18);

            // supply reward tokens to pools
            await rewardToken1.connect(alice).mint(syntheX.address, parseEther("10000000000"));
            await rewardToken2.connect(alice).mint(syntheX.address, parseEther("10000000000"));
            await rewardToken3.connect(alice).mint(syntheX.address, parseEther("10000000000"));

            // set pools speed
            const speed = parseEther("0.00000009");
            const addToList = true;
            await syntheX.connect(bob).setPoolSpeed(rewardToken1.address, pool1.address, speed, addToList);
            await syntheX.connect(bob).setPoolSpeed(rewardToken2.address, pool1.address, speed, addToList);
            await syntheX.connect(bob).setPoolSpeed(rewardToken3.address, pool2.address, speed, addToList);

            // additional setup
            await pool1.connect(bob).unpause();
            await pool2.connect(bob).unpause();

            await pool1.connect(alice).setIssuerAlloc(0);
            await pool2.connect(alice).setIssuerAlloc(0);

            const ERC20X = await ethers.getContractFactory("ERC20X");
            const synth1 = await upgrades.deployProxy(ERC20X, ["Ethereum", "ETH", pool1.address, syntheX.address], {
                unsafeAllow: ["delegatecall"]
            });
            const synth2 = await upgrades.deployProxy(ERC20X, ["Ethereum", "ETH", pool2.address, syntheX.address], {
                unsafeAllow: ["delegatecall"]
            });
            const mintFee = 4;
            const burnFee = 6;
            await pool1.connect(alice).addSynth(synth1.address, mintFee, burnFee);
            await pool2.connect(alice).addSynth(synth2.address, mintFee, burnFee);

            const WETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
            const collateral = await ethers.getContractAt("MockToken", WETH);

            const params = {
                cap: "100000000000000000000000",
                baseLTV: "8000",
                liqThreshold: "9000",
                liqBonus: "10500",
                isActive: true,
                totalDeposits: 0
            };

            const MockPriceFeed = await ethers.getContractFactory("MockPriceFeed");
            const feed = await MockPriceFeed.deploy(parseEther("0.000000001"), 18);

            const PriceOracle = await ethers.getContractFactory("PriceOracle");
            const oracle = await PriceOracle.deploy(
                syntheX.address,
                [collateral.address, synth1.address, synth2.address],
                [feed.address, feed.address, feed.address],
                ZERO_ADDRESS,
                ZERO_ADDRESS,
                1e8
            );

            await pool1.connect(alice).setPriceOracle(oracle.address);
            await pool2.connect(alice).setPriceOracle(oracle.address);

            await pool1.connect(alice).setFeeToken(synth1.address);
            await pool2.connect(alice).setFeeToken(synth2.address);

            await pool1.connect(alice).updateCollateral(collateral.address, params);
            await pool2.connect(alice).updateCollateral(collateral.address, params);

            // deposit eth to 2 pools
            await pool1.connect(charlie).depositETH({ value: parseEther("5") });
            await pool2.connect(charlie).depositETH({ value: parseEther("5") });
            expect((await pool1.getAccountLiquidity(charlie.address))[1]).to.equal(parseEther("50"));
            expect((await pool2.getAccountLiquidity(charlie.address))[1]).to.equal(parseEther("50"));

            await pool1.connect(dave).depositETH({ value: parseEther("1") });
            await pool2.connect(dave).depositETH({ value: parseEther("1") });
            expect((await pool1.getAccountLiquidity(dave.address))[1]).to.equal(parseEther("10"));
            expect((await pool2.getAccountLiquidity(dave.address))[1]).to.equal(parseEther("10"));

            // issues synth
            await synth1.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            await synth2.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            expect((await pool1.getAccountLiquidity(charlie.address))[2]).to.be.not.equal(0);
            expect((await pool2.getAccountLiquidity(charlie.address))[2]).to.be.not.equal(0);

            await synth1.connect(dave).mint(ethers.utils.parseEther("20"), dave.address, ZERO_ADDRESS);
            await synth2.connect(dave).mint(ethers.utils.parseEther("20"), dave.address, ZERO_ADDRESS);
            expect((await pool1.getAccountLiquidity(dave.address))[2]).to.be.not.equal(0);
            expect((await pool2.getAccountLiquidity(dave.address))[2]).to.be.not.equal(0);

            //1 hour
            await time.increase(3600);

            // get reward accrued
            const charlieRewards = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address],
                charlie.address,
                [pool2.address]
            );
            expect(charlieRewards[0]).to.be.equal(0);

            const daveRewards = await syntheX.callStatic.getRewardsAccrued([rewardToken3.address], dave.address, [
                pool1.address
            ]);
            expect(daveRewards[0]).to.be.equal(0);

            // 2 hour
            await time.increase(3600 * 2);

            // get reward accrued
            const charlieRewardsAfter = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address],
                charlie.address,
                [pool2.address]
            );
            expect(charlieRewardsAfter[0]).to.be.equal(0);

            const daveRewardsAfter = await syntheX.callStatic.getRewardsAccrued([rewardToken3.address], dave.address, [
                pool1.address
            ]);
            expect(daveRewardsAfter[0]).to.be.equal(0);

            const daveValidRewards = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address, rewardToken3.address],
                dave.address,
                [pool1.address, pool2.address]
            );
            expect(daveValidRewards[0]).to.be.not.equal(0);
            expect(daveValidRewards[1]).to.be.not.equal(0);
            expect(daveValidRewards[2]).to.be.not.equal(0);

            const charlieValidRewards = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address, rewardToken3.address],
                charlie.address,
                [pool1.address, pool2.address]
            );
            expect(charlieValidRewards[0]).to.be.not.equal(0);
            expect(charlieValidRewards[1]).to.be.not.equal(0);
            expect(charlieValidRewards[2]).to.be.not.equal(0);

            const daveRewards1Pool = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address, rewardToken3.address],
                dave.address,
                [pool1.address]
            );
            expect(daveRewards1Pool[0]).to.be.not.equal(0);
            expect(daveRewards1Pool[1]).to.be.not.equal(0);
            expect(daveRewards1Pool[2]).to.be.equal(0);

            const daveRewards2Pool = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address, rewardToken3.address],
                dave.address,
                [pool2.address]
            );
            expect(daveRewards2Pool[0]).to.be.equal(0);
            expect(daveRewards2Pool[1]).to.be.equal(0);
            expect(daveRewards2Pool[2]).to.be.not.equal(0);

            // deposit ETH again
            await pool1.connect(dave).depositETH({ value: parseEther("3") });
            await pool2.connect(dave).depositETH({ value: parseEther("3") });
            await pool1.connect(charlie).depositETH({ value: parseEther("5") });
            await pool2.connect(charlie).depositETH({ value: parseEther("5") });

            // issue synth again
            await synth1.connect(dave).mint(ethers.utils.parseEther("10"), dave.address, ZERO_ADDRESS);
            await synth2.connect(dave).mint(ethers.utils.parseEther("10"), dave.address, ZERO_ADDRESS);
            await synth1.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            await synth2.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);

            // 10 hour
            await time.increase(3600 * 10);

            // get reward accrued
            const charlieRewardsAfter2 = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address],
                charlie.address,
                [pool2.address]
            );
            expect(charlieRewardsAfter2[0]).to.be.not.equal(0); //810729999999999
            expect(charlieRewardsAfter2[1]).to.be.not.equal(0); //810729999999999

            const daveRewardsAfter2 = await syntheX.callStatic.getRewardsAccrued([rewardToken3.address], dave.address, [
                pool1.address
            ]);
            expect(daveRewardsAfter2[0]).to.be.not.equal(0); // 162090000000000

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool2.address]);

            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0); //810729999999999
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0); //810729999999999
            expect(await rewardToken3.balanceOf(charlie.address)).to.be.equal(0);

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool1.address]);
            await syntheX.connect(alice).claimReward([rewardToken3.address], charlie.address, [pool2.address]);
            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0); //3125208571428570
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0); //3125208571428570
            expect(await rewardToken3.balanceOf(charlie.address)).to.be.not.equal(0); //3125208571428570

            // claim rewards
            await syntheX.connect(alice).claimReward([rewardToken3.address], dave.address, [pool1.address]);
            // check balance
            expect(await rewardToken1.balanceOf(dave.address)).to.be.equal(0);
            expect(await rewardToken2.balanceOf(dave.address)).to.be.equal(0);
            expect(await rewardToken3.balanceOf(dave.address)).to.be.not.equal(0); // 162090000000000

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], dave.address, [pool1.address]);
            await syntheX.connect(alice).claimReward([rewardToken3.address], dave.address, [pool2.address]);
            // check balance
            expect(await rewardToken1.balanceOf(dave.address)).to.be.not.equal(0);
            expect(await rewardToken2.balanceOf(dave.address)).to.be.not.equal(0);
            expect(await rewardToken3.balanceOf(dave.address)).to.be.not.equal(0);
        });

        it("Should claim rewards with 2 pools (check rewards calculation)", async () => {
            // setup vault
            const Vault = await ethers.getContractFactory("Vault");
            const vault = await Vault.deploy(syntheX.address);
            const VAULT = ethers.utils.id("VAULT");
            await syntheX.connect(alice).setAddress(VAULT, vault.address);

            // setup 2 pools
            const Pool2 = await ethers.getContractFactory("Pool");
            const pool1 = (await upgrades.deployProxy(Pool2.connect(bob), ["Test1", "TST1", syntheX.address])) as Pool;
            const pool2 = (await upgrades.deployProxy(Pool2.connect(bob), ["Test2", "TST2", syntheX.address])) as Pool;

            // setup 3 gifferent reward tokens for 3 pools
            const MockToken = await ethers.getContractFactory("MockToken");
            const rewardToken1 = await MockToken.deploy("Reward Token 1", "RT1", 18);
            const rewardToken2 = await MockToken.deploy("Reward Token 2", "RT2", 18);
            const rewardToken3 = await MockToken.deploy("Reward Token 3", "RT3", 18);

            // supply reward tokens to pools
            await rewardToken1.connect(alice).mint(syntheX.address, parseEther("10000000000"));
            await rewardToken2.connect(alice).mint(syntheX.address, parseEther("10000000000"));
            await rewardToken3.connect(alice).mint(syntheX.address, parseEther("10000000000"));

            // set pools speed
            const speed = parseEther("0.00000009");
            const addToList = true;
            await syntheX.connect(bob).setPoolSpeed(rewardToken1.address, pool1.address, speed, addToList);
            await syntheX.connect(bob).setPoolSpeed(rewardToken2.address, pool1.address, speed, addToList);
            await syntheX.connect(bob).setPoolSpeed(rewardToken3.address, pool2.address, speed, addToList);

            // additional setup
            await pool1.connect(bob).unpause();
            await pool2.connect(bob).unpause();

            await pool1.connect(alice).setIssuerAlloc(0);
            await pool2.connect(alice).setIssuerAlloc(0);

            const ERC20X = await ethers.getContractFactory("ERC20X");
            const synth1 = await upgrades.deployProxy(ERC20X, ["Ethereum", "ETH", pool1.address, syntheX.address], {
                unsafeAllow: ["delegatecall"]
            });
            const synth2 = await upgrades.deployProxy(ERC20X, ["Ethereum", "ETH", pool2.address, syntheX.address], {
                unsafeAllow: ["delegatecall"]
            });
            const mintFee = 4;
            const burnFee = 6;
            await pool1.connect(alice).addSynth(synth1.address, mintFee, burnFee);
            await pool2.connect(alice).addSynth(synth2.address, mintFee, burnFee);

            const WETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
            const collateral = await ethers.getContractAt("MockToken", WETH);

            const params = {
                cap: "100000000000000000000000",
                baseLTV: "8000",
                liqThreshold: "9000",
                liqBonus: "10500",
                isActive: true,
                totalDeposits: 0
            };

            const MockPriceFeed = await ethers.getContractFactory("MockPriceFeed");
            const feed = await MockPriceFeed.deploy(parseEther("0.000000001"), 18);

            const PriceOracle = await ethers.getContractFactory("PriceOracle");
            const oracle = await PriceOracle.deploy(
                syntheX.address,
                [collateral.address, synth1.address, synth2.address],
                [feed.address, feed.address, feed.address],
                ZERO_ADDRESS,
                ZERO_ADDRESS,
                1e8
            );

            await pool1.connect(alice).setPriceOracle(oracle.address);
            await pool2.connect(alice).setPriceOracle(oracle.address);

            await pool1.connect(alice).setFeeToken(synth1.address);
            await pool2.connect(alice).setFeeToken(synth2.address);

            await pool1.connect(alice).updateCollateral(collateral.address, params);
            await pool2.connect(alice).updateCollateral(collateral.address, params);

            // deposit eth to 2 pools
            await pool1.connect(charlie).depositETH({ value: parseEther("5") });
            await pool2.connect(charlie).depositETH({ value: parseEther("5") });
            expect((await pool1.getAccountLiquidity(charlie.address))[1]).to.equal(parseEther("50"));
            expect((await pool2.getAccountLiquidity(charlie.address))[1]).to.equal(parseEther("50"));

            await pool1.connect(dave).depositETH({ value: parseEther("1") });
            await pool2.connect(dave).depositETH({ value: parseEther("1") });
            expect((await pool1.getAccountLiquidity(dave.address))[1]).to.equal(parseEther("10"));
            expect((await pool2.getAccountLiquidity(dave.address))[1]).to.equal(parseEther("10"));

            // issues synth
            await synth1.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            await synth2.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            expect((await pool1.getAccountLiquidity(charlie.address))[2]).to.be.not.equal(0);
            expect((await pool2.getAccountLiquidity(charlie.address))[2]).to.be.not.equal(0);

            await synth1.connect(dave).mint(ethers.utils.parseEther("20"), dave.address, ZERO_ADDRESS);
            await synth2.connect(dave).mint(ethers.utils.parseEther("20"), dave.address, ZERO_ADDRESS);
            expect((await pool1.getAccountLiquidity(dave.address))[2]).to.be.not.equal(0);
            expect((await pool2.getAccountLiquidity(dave.address))[2]).to.be.not.equal(0);

            // 3 hour
            await time.increase(3600 * 3);

            // deposit ETH again
            await pool1.connect(dave).depositETH({ value: parseEther("3") });
            await pool2.connect(dave).depositETH({ value: parseEther("3") });
            await pool1.connect(charlie).depositETH({ value: parseEther("5") });
            await pool2.connect(charlie).depositETH({ value: parseEther("5") });

            // issue synth again
            await synth1.connect(dave).mint(ethers.utils.parseEther("10"), dave.address, ZERO_ADDRESS);
            await synth2.connect(dave).mint(ethers.utils.parseEther("10"), dave.address, ZERO_ADDRESS);
            await synth1.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);
            await synth2.connect(charlie).mint(ethers.utils.parseEther("10"), charlie.address, ZERO_ADDRESS);

            // 10 hour
            await time.increase(3600 * 10);

            const charlieValidRewards2 = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address, rewardToken3.address],
                charlie.address,
                [pool1.address, pool2.address]
            );
            expect(charlieValidRewards2[0]).to.be.not.equal(0); //3125079999999999
            expect(charlieValidRewards2[1]).to.be.not.equal(0); //3125079999999999
            expect(charlieValidRewards2[2]).to.be.not.equal(0); //3125015714285713

            // get reward accrued
            const charlieRewardsAfter2 = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken1.address, rewardToken2.address],
                charlie.address,
                [pool2.address]
            );
            expect(charlieRewardsAfter2[0]).to.be.not.equal(0); //810729999999999
            expect(charlieRewardsAfter2[1]).to.be.not.equal(0); //810729999999999

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool2.address]);

            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0);//810729999999999
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0);//810729999999999
            expect(await rewardToken3.balanceOf(charlie.address)).to.be.equal(0);//0

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool2.address]);
            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0);//810729999999999
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0);//810729999999999

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool1.address]);
            await syntheX.connect(alice).claimReward([rewardToken3.address], charlie.address, [pool2.address]);
            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0);//3125208571428570
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0);//3125208571428570
            expect(await rewardToken3.balanceOf(charlie.address)).to.be.not.equal(0);//3125208571428570

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool1.address]);
            await syntheX.connect(alice).claimReward([rewardToken3.address], charlie.address, [pool2.address]);

            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0);//3125337142857141
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0);//3125337142857141
            expect(await rewardToken3.balanceOf(charlie.address)).to.be.not.equal(0);//3125337142857141

            // claim rewards
            await syntheX
                .connect(alice)
                .claimReward([rewardToken1.address, rewardToken2.address], charlie.address, [pool2.address]);

            // check balance
            expect(await rewardToken1.balanceOf(charlie.address)).to.be.not.equal(0);//3125337142857141
            expect(await rewardToken2.balanceOf(charlie.address)).to.be.not.equal(0);//3125337142857141
            expect(await rewardToken3.balanceOf(charlie.address)).to.be.not.equal(0);//3125337142857141
        });
    });
});
