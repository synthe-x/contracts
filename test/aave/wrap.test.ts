import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { ETH_ADDRESS } from "../../scripts/utils/const";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Contract } from 'ethers';

describe("Testing wrapped atokens", function () {
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let waEthWETH: Contract, weth : Contract, pool: Contract, aToken: Contract;

    const AAVE_V3_POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";

    before(async () => {
        [owner, user1, user2, user3] = await ethers.getSigners();
		const deployments = await loadFixture(main);
        waEthWETH = deployments.collateralTokens[6];
        if(!waEthWETH) throw new Error("waEthWETH not found");
        waEthWETH = await ethers.getContractAt("ATokenWrapper", waEthWETH.address);
        weth = deployments.collateralTokens[1];
        weth = await ethers.getContractAt("WETH9", weth.address);
        pool = await ethers.getContractAt("IPool", AAVE_V3_POOL);
        aToken = await ethers.getContractAt("MockToken", await waEthWETH.underlying());
    })

    it("check initial exchange rate", async function () {
        expect(await waEthWETH.exchangeRate()).to.equal(ethers.utils.parseEther("1"))
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
        expect(await waEthWETH.exchangeRate()).to.be.greaterThan(ethers.utils.parseEther("1.01"));
        // withdraw
        await waEthWETH.connect(user1).withdraw(ethers.utils.parseEther("10"));
        expect(await waEthWETH.balanceOf(user1.address)).to.equal(0);
        // check aEthWETH balance
        expect(await aToken.balanceOf(user1.address)).to.be.greaterThan(ethers.utils.parseEther("1.01"));
    })
})