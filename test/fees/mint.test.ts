import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { BASIS_POINTS, ETH_ADDRESS } from "../../scripts/utils/const";

describe("Testing MintFee", function () {

	let synthex: any, vault: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	let mintFee = ethers.constants.Zero, burnFee = ethers.constants.Zero, swapFee = ethers.constants.Zero, liqFee = ethers.constants.Zero, liqPenalty = ethers.constants.Zero, issuerAlloc = ethers.constants.Zero;

	const setup = async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
        vault = deployments.vault;
		synthex = deployments.synthex;
        syn = deployments.syn;
		oracle = deployments.oracle;
		cryptoPool = deployments.pools[0];
		sbtc = deployments.poolSynths[0][0];
		seth = deployments.poolSynths[0][1];
		susd = deployments.poolSynths[0][2];

        await synthex.connect(user1).deposit(ETH_ADDRESS, ethers.utils.parseEther("50"), {value: ethers.utils.parseEther("50")});    // $ 50000
        expect((await synthex.getAccountLiquidity(user1.address))[0]).to.be.equal(ethers.utils.parseEther("50000"));

        await synthex.connect(user2).deposit(ETH_ADDRESS, ethers.utils.parseEther("50"), {value: ethers.utils.parseEther("50")});    // $ 50000
        expect((await synthex.getAccountLiquidity(user2.address))[0]).to.be.equal(ethers.utils.parseEther("50000"));
	};

    describe('Minting fee', async () => { 
        before(async () => {
            await setup();
        })
        it("should update fee to 1%", async function () {
            mintFee = ethers.utils.parseEther("100");
            await cryptoPool.connect(owner).updateFee(mintFee, swapFee, burnFee, liqPenalty, liqFee, issuerAlloc);
            expect(await cryptoPool.mintFee()).to.equal(mintFee);
            expect(await cryptoPool.issuerAlloc()).to.equal(issuerAlloc);
        });

        it("user should be able to mints synths", async function () {
            // user1 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user1).mint(mintAmount); // $ 10000
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            expect((await synthex.getAccountLiquidity(user1.address))[1]).to.be.equal(expectedDebt.add(fee));
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee);
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(mintAmount); 
        });

        it("should update fee to 0.1%", async function () {
            mintFee = ethers.utils.parseEther("10");
            await cryptoPool.connect(owner).updateFee(mintFee, swapFee, burnFee, liqPenalty, liqFee, issuerAlloc);
            expect(await cryptoPool.mintFee()).to.equal(mintFee);
        });

        it("user2 should issue synths", async function () {
            // initial checks
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user2 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user2).mint(mintAmount); // $ 10000
            
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            expect((await synthex.getAccountLiquidity(user2.address))[1]).to.be.equal(expectedDebt.add(fee));
            
            // fee added to vault 
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(mintAmount);
        });

        it("user2 should swap 1 seth to sbtc", async function () {
            // user1 exchanges 1 seth to sbtc with no minting fees
            await seth.connect(user2).swap(ethers.utils.parseEther("1"), sbtc.address);
            expect(await sbtc.balanceOf(user2.address)).to.be.equal(ethers.utils.parseEther("0.1")); 
        })
    });

    describe("Burned fee from isserAlloc", async () => {
        before(async () => {
            await setup();
        })

        it("should update fee to 1% + 50% issuer alloc", async function () {
            mintFee = ethers.utils.parseEther("100");
            issuerAlloc = ethers.utils.parseEther("5000");
            await cryptoPool.connect(owner).updateFee(mintFee, swapFee, burnFee, liqPenalty, liqFee, issuerAlloc);
            expect(await cryptoPool.mintFee()).to.equal(mintFee);
            expect(await cryptoPool.issuerAlloc()).to.equal(issuerAlloc);
        });

        it("user should mints synths", async function () {
            // user1 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user1).mint(mintAmount); // $ 10000
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);
            expect((await synthex.getAccountLiquidity(user1.address))[1]).to.be.equal(expectedDebt.add(fee).sub(burnedIssuerAlloc));
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee.sub(burnedIssuerAlloc));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(mintAmount); 
        });

        it("should update fee to 0.1% + 80% issuer alloc", async function () {
            mintFee = ethers.utils.parseEther("10");
            issuerAlloc = ethers.utils.parseEther("8000");
            await cryptoPool.connect(owner).updateFee(mintFee, swapFee, burnFee, liqPenalty, liqFee, issuerAlloc);
            expect(await cryptoPool.mintFee()).to.equal(mintFee);
        });

        it("should user2 issue synths", async function () {
            // initial checks
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user2 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user2).mint(mintAmount); // $ 10000
            
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);
            expect((await synthex.getAccountLiquidity(user2.address))[1]).to.be.closeTo(expectedDebt.add(fee).sub(burnedIssuerAlloc.div(2)), ethers.utils.parseEther("0.01"));
            
            // fee added to vault 
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee.sub(burnedIssuerAlloc)));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(mintAmount);
        });
    })
})