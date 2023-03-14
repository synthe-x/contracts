import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { BASIS_POINTS, ETH_ADDRESS } from "../../scripts/utils/const";

describe("Testing BurnFee", function () {

	let synthex: any, vault: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	let mintFee = 0, burnFee = 0, issuerAlloc = 0;

	const setup = async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
        vault = deployments.vault;
		synthex = deployments.synthex;
		oracle = deployments.pools[0].oracle;
		cryptoPool = deployments.pools[0].pool;
		sbtc = deployments.pools[0].synths[0];
		seth = deployments.pools[0].synths[1];
		susd = deployments.pools[0].synths[2];

        await cryptoPool.connect(user1).depositETH({value: ethers.utils.parseEther("50")});    // $ 50000
        expect((await cryptoPool.getAccountLiquidity(user1.address))[1]).to.be.equal(ethers.utils.parseEther("50000"));

        await cryptoPool.connect(user2).depositETH({value: ethers.utils.parseEther("50")});    // $ 50000
        expect((await cryptoPool.getAccountLiquidity(user2.address))[1]).to.be.equal(ethers.utils.parseEther("50000"));

        // Mint synths
        await seth.connect(user1).mint(ethers.utils.parseEther("10"), user1.address, ethers.constants.AddressZero); // $ 10000
        await seth.connect(user2).mint(ethers.utils.parseEther("10"), user2.address, ethers.constants.AddressZero); // $ 10000
	};

    describe('Burn fee', async () => { 
        before(async () => {
            await setup();
        })
        it("should update fee to 1%", async function () {
            burnFee = 100;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, isActive: true, isDisabled: false, burnFee});
        });

        it("user should be able to burn 1 sETH with 10 sUSD fee", async function () {
            // user1 burns 1.01 seth for repaying $1000 debt (1% fee)
            await seth.connect(user1).burn(ethers.utils.parseEther("1.01"));
            // 1010 = 1000 + 10 (1%) fee
            let initialAmount = ethers.utils.parseEther("1000");
            let fee = initialAmount.mul(burnFee).div(BASIS_POINTS);
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee);
            // expected remaining debt should be 9000
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.equal(ethers.utils.parseEther("9000"));
            // After burning 1.01 sETH, balance should be 8.99 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(ethers.utils.parseEther("8.99")); 
        });

        it("should update fee to 0.1%", async function () {
            burnFee = 10;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, isActive: true, isDisabled: false, burnFee});
        });

        it("user2 should issue synths", async function () {
            // initial vault balance
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user1 burns 1.001 seth for repaying $1000 debt (0.1% fee)
            await seth.connect(user2).burn(ethers.utils.parseEther("1.001"));
            // 1010 = 1000 + 1 (0.1%) fee
            let initialAmount = ethers.utils.parseEther("1000");
            let fee = initialAmount.mul(burnFee).div(BASIS_POINTS);
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee));
            // expected remaining debt should be 9000
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.equal(ethers.utils.parseEther("9000"));
            // After burning 1.01 sETH, balance should be 8.99 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(ethers.utils.parseEther("8.999")); 
        });
    });

    describe("Burned fee from isserAlloc", async () => {
        before(async () => {
            await setup();
        })

        it("should update fee to 1% + 50% issuer alloc", async function () {
            burnFee = 100;
            issuerAlloc = 5000;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, isActive: true, isDisabled: false, burnFee});
            await cryptoPool.connect(owner).setIssuerAlloc(issuerAlloc);
        });

        it("user should be able to swap 10 sETH to 10000 sUSD with 50 sUSD fee + 50 sUSD burned", async function () {
            // initial liquidity of user1 and user2
            let initialUser1Debt = (await cryptoPool.getAccountLiquidity(user1.address))[2];
            let initialUser2Debt = (await cryptoPool.getAccountLiquidity(user2.address))[2];
            // user1 swaps 10 seth
            await seth.connect(user1).burn(ethers.utils.parseEther("1.01"));
            // 10000 = 9900 + 100 (1%) fee
            let initialAmount = ethers.utils.parseEther("1000");
            let fee = initialAmount.mul(burnFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);

            // check if both user1 and user2 debt is reduced by 50/2 sUSD
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.closeTo(
                initialUser1Debt.sub(initialAmount).sub(burnedIssuerAlloc.mul(9).div(19)), ethers.utils.parseEther("0.001"));
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.closeTo(initialUser2Debt.sub(burnedIssuerAlloc.mul(10).div(19)), ethers.utils.parseEther("0.001"));

            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee.sub(burnedIssuerAlloc));
            // After burning 1.01 sETH, balance should be 8.99 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(ethers.utils.parseEther("8.99")) 
        });

        it("should update fee to 0.1% + 80% issuer alloc", async function () {
            burnFee = 10;
            issuerAlloc = 8000;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee, isActive: true, isDisabled: false, burnFee});
            await cryptoPool.connect(owner).setIssuerAlloc(issuerAlloc);
        });

        it("user should be able to burn 1 sETH for $1000 with 2 sUSD fee + 8 sUSD burned", async function () {
            // initial liquidity of user1 and user2
            let initialUser1Debt = (await cryptoPool.getAccountLiquidity(user1.address))[2];
            let initialUser2Debt = (await cryptoPool.getAccountLiquidity(user2.address))[2];
            // initial vault balance
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user1 swaps 10 seth
            await seth.connect(user2).burn(ethers.utils.parseEther("1.001"));
            // 10000 = 9900 + 100 (1%) fee
            let initialAmount = ethers.utils.parseEther("1000");
            let fee = initialAmount.mul(burnFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);

            // check if both user1 and user2 debt is reduced by 50/2 sUSD
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.closeTo(initialUser1Debt.sub(burnedIssuerAlloc.div(2)), ethers.utils.parseEther("0.001"));
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.closeTo(initialUser2Debt.sub(initialAmount).sub(burnedIssuerAlloc.div(2)), ethers.utils.parseEther("0.001"));

            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee.sub(burnedIssuerAlloc)));
            // After burning 1.01 sETH, balance should be 8.99 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(ethers.utils.parseEther("8.999")) 
        });
    })
})