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
import { SyntheX, MockToken, Pool, MockPriceFeed, PriceOracle, ERC20X, Vault } from "../../typechain-types";

const parseEther = ethers.utils.parseEther;
const toBN = ethers.BigNumber.from;
const ZERO_ADDRESS = ethers.constants.AddressZero;
const provider = ethers.provider;

describe.only("PoolScenarios", function () {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;
    let charlie: SignerWithAddress;
    let dave: SignerWithAddress;

    let syntheX: SyntheX;
    let collateral: MockToken;
    let rewardToken: MockToken;
    let pool: Pool;
    let feed: MockPriceFeed;
    let feedSynth: MockPriceFeed;
    let oracle: PriceOracle;
    let synth: ERC20X;
    let vault: Vault;

    let price: any;
    let priceSynth: any;

    let snapshotA: SnapshotRestorer;

    before(async function () {
        [bob, owner, alice, charlie, dave] = await ethers.getSigners();

        const SyntheX = await ethers.getContractFactory("SyntheX");
        syntheX = (await upgrades.deployProxy(SyntheX, [owner.address, alice.address, bob.address])) as SyntheX;

        const MockToken = await ethers.getContractFactory("MockToken");
        collateral = (await MockToken.deploy("Coll", "CLT", 18)) as MockToken;
        rewardToken = (await MockToken.deploy("Reward", "RWD", 18)) as MockToken;

        const Vault = await ethers.getContractFactory("Vault");
        vault = await Vault.deploy(syntheX.address);

        const VAULT = ethers.utils.id("VAULT");
        await syntheX.connect(alice).setAddress(VAULT, vault.address);

        const Pool = await ethers.getContractFactory("Pool");
        pool = (await upgrades.deployProxy(Pool.connect(bob), ["First", "FRST", syntheX.address])) as Pool;

        //setup rewards
        await rewardToken.connect(alice).mint(syntheX.address, parseEther("1000000"));

        const speed = parseEther("0.0000001");
        const addToList = true;
        await syntheX.connect(bob).setPoolSpeed(rewardToken.address, pool.address, speed, addToList);

        //additional setup
        await pool.connect(bob).unpause();
        await pool.connect(alice).setIssuerAlloc(5000);

        //setup synth
        const ERC20X = await ethers.getContractFactory("ERC20X");
        synth = (await upgrades.deployProxy(ERC20X, ["Synth", "SNTH", pool.address, syntheX.address], {
            unsafeAllow: ["delegatecall"]
        })) as ERC20X;
        const mintFee = parseEther("0.000000000000000001");
        const burnFee = parseEther("0.000000000000000001");
        await pool.connect(alice).addSynth(synth.address, mintFee, burnFee);
        await pool.connect(alice).setFeeToken(synth.address);

        //setup collateral
        const collateralParams = {
            cap: parseEther("100000"),
            baseLTV: "8000",
            liqThreshold: "9000",
            liqBonus: "10500",
            isActive: true,
            totalDeposits: 0
        };
        await pool.connect(alice).updateCollateral(collateral.address, collateralParams);
        await collateral.mint(dave.address, parseEther("100"));

        //setup price feed
        const MockPriceFeed = await ethers.getContractFactory("MockPriceFeed");
        price = parseEther("0.0000000001");
        const decimals = 18;
        feed = (await MockPriceFeed.deploy(price, decimals)) as MockPriceFeed;

        priceSynth = parseEther("1");
        const decimalsSynth = 18;
        feedSynth = (await MockPriceFeed.deploy(price, decimalsSynth)) as MockPriceFeed;

        //setup oracle
        const PriceOracle = await ethers.getContractFactory("PriceOracle");
        const baseCurrencyUnit = 1e8;
        oracle = (await PriceOracle.deploy(
            syntheX.address,
            [collateral.address, synth.address],
            [feed.address, feedSynth.address],
            ZERO_ADDRESS,
            ZERO_ADDRESS,
            baseCurrencyUnit
        )) as PriceOracle;
        await pool.connect(alice).setPriceOracle(oracle.address);

        snapshotA = await takeSnapshot();
    });

    afterEach(async function () {
        await snapshotA.restore();
    });

    describe("Deposit/borrow and reward calculation", function () {
        it("Should get rewards after repay if rewards off before repay", async () => {
            //deposit collateral
            await collateral.connect(dave).approve(pool.address, parseEther("100"));
            await pool.connect(dave).deposit(collateral.address, parseEther("100"));

            //issue debt
            await synth.connect(dave).mint(parseEther("100"), dave.address, ZERO_ADDRESS);

            //3 days
            await time.increase(60 * 60 * 24 * 3);

            // get rewards accrued
            const rewards = await syntheX
                .connect(dave)
                .callStatic.getRewardsAccrued([rewardToken.address], dave.address, [pool.address]);
            expect(rewards[0]).to.be.not.equal(0);

            //rewards off
            await syntheX.connect(bob).setPoolSpeed(rewardToken.address, pool.address, 0, false);
            const rewardsAfterOff = await syntheX
                .connect(dave)
                .callStatic.getRewardsAccrued([rewardToken.address], dave.address, [pool.address]);
            expect(rewardsAfterOff[0]).to.be.gt(rewards[0]);

            //3 days
            await time.increase(60 * 60 * 24 * 3);

            //repay debt
            await synth.connect(dave).burn(parseEther("50"));
            const rewardsAfterBurn = await syntheX
                .connect(dave)
                .callStatic.getRewardsAccrued([rewardToken.address], dave.address, [pool.address]);
            expect(rewardsAfterBurn[0]).to.be.equal(rewardsAfterOff[0]);

            //claim rewards
            expect(await rewardToken.balanceOf(dave.address)).to.be.equal(0);
            await syntheX.connect(dave).claimReward([rewardToken.address], dave.address, [pool.address]);
            expect(await rewardToken.balanceOf(dave.address)).to.be.equal(rewardsAfterOff[0]);
        });

        it("Should get rewards if rewards on after deposit and before repay", async () => {
            //rewards off
            await syntheX.connect(bob).setPoolSpeed(rewardToken.address, pool.address, 0, false);

            //check rewards
            const rewardsBefore = await syntheX.callStatic.getRewardsAccrued([rewardToken.address], dave.address, [
                pool.address
            ]);
            expect(rewardsBefore[0]).to.be.equal(0);

            //deposit collateral
            await collateral.connect(dave).approve(pool.address, parseEther("100"));
            await pool.connect(dave).deposit(collateral.address, parseEther("100"));

            //issue debt
            await synth.connect(dave).mint(parseEther("100"), dave.address, ZERO_ADDRESS);

            //3 days
            await time.increase(60 * 60 * 24 * 3);

            //check rewards
            const rewardsAfterDeposit = await syntheX.callStatic.getRewardsAccrued(
                [rewardToken.address],
                dave.address,
                [pool.address]
            );
            expect(rewardsAfterDeposit[0]).to.be.eq(0);

            //rewards on
            const speed = parseEther("0.0000001");
            await syntheX.connect(bob).setPoolSpeed(rewardToken.address, pool.address, speed, false);

            //3 days
            await time.increase(60 * 60 * 24 * 3);

            //check rewards
            const rewardsAfterOn = await syntheX.callStatic.getRewardsAccrued([rewardToken.address], dave.address, [
                pool.address
            ]);
            expect(rewardsAfterOn[0]).to.be.gt(0);

            //repay debt
            await synth.connect(dave).burn(parseEther("60"));

            //check rewards
            const rewardsAfterBurn = await syntheX
                .connect(dave)
                .callStatic.getRewardsAccrued([rewardToken.address], dave.address, [pool.address]);
            expect(rewardsAfterBurn[0]).to.be.gt(rewardsAfterOn[0]);

            //claim rewards
            expect(await rewardToken.balanceOf(dave.address)).to.be.equal(0);
            await syntheX.connect(dave).claimReward([rewardToken.address], dave.address, [pool.address]);
            expect(await rewardToken.balanceOf(dave.address)).to.be.closeTo(rewardsAfterBurn[0], speed);
        });

        it("Should issue debt correctly", async () => {
            //deposit collateral
            await collateral.connect(dave).approve(pool.address, parseEther("10"));
            await pool.connect(dave).deposit(collateral.address, parseEther("10"));

            //issue debt
            await synth.connect(dave).mint(parseEther("10"), dave.address, ZERO_ADDRESS);

            console.log(await pool.balanceOf(dave.address)); //8
            console.log(await synth.balanceOf(dave.address)); //7,9
            console.log(await synth.balanceOf(vault.address)); //0,0007999200079992

            //get balances
            const debtAmount = await pool.balanceOf(dave.address);
            const synthBalance = await synth.balanceOf(dave.address); //don't convert to usd because the price -> 1:1
            const feeAmount = await synth.balanceOf(vault.address);

            //check amounts
            expect(synthBalance.add(feeAmount)).to.be.gt(debtAmount);
        });
    });
});