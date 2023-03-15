import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { BASIS_POINTS, ETH_ADDRESS } from "../../scripts/utils/const";

describe("Testing MintFee", function () {

	let synthex: any, vault: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	let mintFee = 0, burnFee = 0, issuerAlloc = 0;

	const setup = async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
        vault = deployments.vault;
		synthex = deployments.synthex;
        syn = deployments.syn;
		oracle = deployments.pools[0].oracle;
		cryptoPool = deployments.pools[0].pool;
		sbtc = deployments.pools[0].synths[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];

        await cryptoPool.connect(user1).depositETH({value: ethers.utils.parseEther("50")});    // $ 50000
        expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).to.be.equal(ethers.utils.parseEther("50000"));

        await cryptoPool.connect(user2).depositETH({value: ethers.utils.parseEther("50")});    // $ 50000
        expect((await cryptoPool.getAccountLiquidity(user2.address))[1]).to.be.equal(ethers.utils.parseEther("50000"));
	};

    describe('Minting fee', async () => { 
        before(async () => {
            await setup();
        })
        it("should update fee to 1%", async function () {
            mintFee = 100;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, isActive: true, isDisabled: false, burnFee});
            // expect(await cryptoPool.mintFee()).to.equal(mintFee);
        });

        it("user should be able to mints synths", async function () {
            // user1 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user1).mint(mintAmount, user1.address, ethers.constants.AddressZero); // $ 10000
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.equal(expectedDebt.add(fee));
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee);
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(mintAmount); 
        });

        it("should update fee to 0.1%", async function () {
            mintFee = 10;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, isActive: true, isDisabled: false, burnFee});
            // expect(await cryptoPool.mintFee()).to.equal(mintFee);
        });

        it("user2 should issue synths", async function () {
            // initial checks
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user2 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user2).mint(mintAmount, user2.address, ethers.constants.AddressZero); // $ 10000
            
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.equal(expectedDebt.add(fee));
            
            // fee added to vault 
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(mintAmount);
        });

        it("user2 should swap 1 seth to sbtc", async function () {
            // user1 exchanges 1 seth to sbtc with no minting fees
            await seth.connect(user2).swap(ethers.utils.parseEther("1"), sbtc.address, user2.address, ethers.constants.AddressZero);
            expect(await sbtc.balanceOf(user2.address)).to.be.equal(ethers.utils.parseEther("0.1")); 
        })
    });

    describe("Burned fee from isserAlloc", async () => {
        before(async () => {
            await setup();
        })

        it("should update fee to 1% + 50% issuer alloc", async function () {
            mintFee = 100;
            issuerAlloc = 5000;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, burnFee, isActive: true, isDisabled: false});
            await cryptoPool.connect(owner).setIssuerAlloc(issuerAlloc)
        });

        it("user should mints synths", async function () {
            // user1 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user1).mint(mintAmount, user1.address, ethers.constants.AddressZero); // $ 10000
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.equal(expectedDebt.add(fee).sub(burnedIssuerAlloc));
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee.sub(burnedIssuerAlloc));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(mintAmount); 
        });

        it("should update fee to 0.1% + 80% issuer alloc", async function () {
            mintFee = 10;
            issuerAlloc = 8000;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, burnFee, isActive: true, isDisabled: false});
            await cryptoPool.connect(owner).setIssuerAlloc(issuerAlloc);
        });

        it("should user2 issue synths", async function () {
            // initial checks
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user2 issues 10 seth
            let mintAmount = ethers.utils.parseEther("10");
            await seth.connect(user2).mint(mintAmount, user2.address, ethers.constants.AddressZero); // $ 10000
            
            // 10000 + 100 (1%) fee
            let expectedDebt = ethers.utils.parseEther("10000")
            let fee = expectedDebt.mul(mintFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.closeTo(expectedDebt.add(fee).sub(burnedIssuerAlloc.div(2)), ethers.utils.parseEther("0.01"));
            
            // fee added to vault 
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee.sub(burnedIssuerAlloc)));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(mintAmount);
        });
    })
})