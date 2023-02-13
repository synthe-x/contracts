import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract, BigNumber } from 'ethers';

describe("Testing wrapped atokens", function () {
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let waEthWETH: Contract, weth : Contract, pool: Contract, aToken: Contract, synthex: Contract, oracle: Contract;
    let exchangeRate: BigNumber, ethPrice: BigNumber[];

    const AAVE_V3_POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";

    const setup = async () => {
        [owner, user1, user2, user3] = await ethers.getSigners();
		const deployments = await loadFixture(main);
        synthex = deployments.synthex;
        oracle = deployments.oracle;
        waEthWETH = deployments.collateralTokens[6];
        weth = deployments.collateralTokens[1];
        if(!waEthWETH) throw new Error("waEthWETH not found");
        ethPrice = await oracle.getAssetPrice(weth.address);
        waEthWETH = await ethers.getContractAt("ATokenWrapper", waEthWETH.address);
        weth = deployments.collateralTokens[1];
        weth = await ethers.getContractAt("WETH9", weth.address);
        pool = await ethers.getContractAt("IPool", AAVE_V3_POOL);
        aToken = await ethers.getContractAt("MockToken", await waEthWETH.underlying());
    }

    describe("check wrapper", async () => {

        before(async () => {
            await setup();
        })

        it("check initial exchange rate", async function () {
            exchangeRate = await waEthWETH.exchangeRate();
            expect(exchangeRate).to.equal(ethers.utils.parseEther("1"))

        })

        it("get aEthWETH from aave", async () => {
            // wrap eth
            await weth.connect(user1).deposit({value: ethers.utils.parseEther("10")});
            // check balance
            expect(await weth.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("10"));

            // deposit to aave
            await weth.connect(user1).approve(pool.address, ethers.utils.parseEther("10"));
            await pool.connect(user1).deposit(weth.address, ethers.utils.parseEther("10"), user1.address, 0);
            // check balance
            expect(await aToken.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("10"));

            // get waEthWETH
            await aToken.connect(user1).approve(waEthWETH.address, ethers.utils.parseEther("10"));
            await waEthWETH.connect(user1).deposit(ethers.utils.parseEther("10"));
            // check balance
            expect(await waEthWETH.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("10"));
        })

        it("check shares after 1 year", async () => {
            await time.increase(time.duration.years(1));
            // more than 1% interest accumulated
            let newExchangeRate = await waEthWETH.exchangeRate();
            expect(newExchangeRate).to.be.greaterThan(exchangeRate.mul(101).div(100));

            // withdraw
            await waEthWETH.connect(user1).withdraw(ethers.utils.parseEther("10"));
            expect(await waEthWETH.balanceOf(user1.address)).to.equal(0);
            // check aEthWETH balance
            expect(await aToken.balanceOf(user1.address)).to.be.greaterThan(ethers.utils.parseEther("1.01"));
            // deposit it back
            await aToken.connect(user1).approve(waEthWETH.address, ethers.utils.parseEther("10"));
            await waEthWETH.connect(user1).deposit(ethers.utils.parseEther("10"));
        })
    })

    describe("deposit into synthex and check balance over time", async () => {
        it("deposit into synthex", async () => {
            // deposit into synthex
            await waEthWETH.connect(user1).approve(synthex.address, ethers.utils.parseEther("10"));
            await synthex.connect(user1).deposit(waEthWETH.address, ethers.utils.parseEther("10"));
            // check balance
            expect(await waEthWETH.balanceOf(user1.address)).to.equal(0);
            expect(await waEthWETH.balanceOf(synthex.address)).to.equal(ethers.utils.parseEther("10"));

            // check synthex balance
            const initialBalance = (await synthex.getAccountLiquidity(user1.address))[0]
            expect(initialBalance).to.closeTo(ethers.utils.parseEther("10").mul(ethPrice[0]).div(ethers.utils.parseUnits("1", ethPrice[1])), ethers.utils.parseEther("0.0001"));
        })

        it("check balance after 1 year", async () => {
            const initialBalance = (await synthex.getAccountLiquidity(user1.address))[0];
            await time.increase(time.duration.years(1));
            // more than 1% interest accumulated
            let newExchangeRate = await waEthWETH.exchangeRate();
            expect(newExchangeRate).to.be.greaterThan(exchangeRate.mul(101).div(100));

            // check synthex balance
            const balance = (await synthex.getAccountLiquidity(user1.address))[0]
            expect(balance).to.be.greaterThan(initialBalance);
        })
    })

})