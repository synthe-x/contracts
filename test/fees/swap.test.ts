import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { BASIS_POINTS, ETH_ADDRESS } from "../../scripts/utils/const";

describe("Testing SwapFee", function () {

	let synthex: any, vault: any, syn: any, oracle: any, sethPriceFeed: any, sbtcPriceFeed: any, cryptoPool: any, eth: any, susd: any, sbtc: any, seth: any;
	let owner: any, user1: any, user2: any, user3: any;

	let swapFee = 0, issuerAlloc = 0;

	const setup = async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
        vault = deployments.vault;
		synthex = deployments.synthex;
        syn = deployments.SYX;
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

    describe('Swap fee', async () => { 
        before(async () => {
            await setup();
        })
        it("should update fee to 1%", async function () {
            swapFee = 100;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
            await cryptoPool.connect(owner).updateSynth(susd.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
        });

        it("user should be able to swap 10 sETH to 10000 sUSD with 100 sUSD fee", async function () {
            // user1 swaps 10 seth
            await seth.connect(user1).swap(ethers.utils.parseEther("10"), susd.address, user1.address, ethers.constants.AddressZero);
            // 10000 = 9900 + 100 (1%) fee
            let initialAmount = ethers.utils.parseEther("10000");
            let fee = initialAmount.mul(swapFee).div(BASIS_POINTS);
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee);
            // expected output should be 9900
            expect(await susd.balanceOf(user1.address)).to.be.equal(initialAmount.sub(fee));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(ethers.constants.Zero); 
        });

        it("should update fee to 0.1%", async function () {
            swapFee = 10;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
            await cryptoPool.connect(owner).updateSynth(susd.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
        });

        it("user2 should issue synths", async function () {
            // initial vault balance
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user1 swaps 10 seth
            await seth.connect(user2).swap(ethers.utils.parseEther("10"), susd.address, user2.address, ethers.constants.AddressZero);
            // 10000 = 9900 + 100 (1%) fee
            let initialAmount = ethers.utils.parseEther("10000");
            let fee = initialAmount.mul(swapFee).div(BASIS_POINTS);
            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee));
            // expected output should be 9900
            expect(await susd.balanceOf(user2.address)).to.be.equal(initialAmount.sub(fee));
            // After issuing 10 sETH, balance should be 10 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(ethers.constants.Zero); 
        });
    });

    describe("Burned fee from isserAlloc", async () => {
        before(async () => {
            await setup();
        })

        it("should update fee to 1% + 50% issuer alloc", async function () {
            issuerAlloc = 5000;
            swapFee = 100;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
            await cryptoPool.connect(owner).updateSynth(susd.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
            await cryptoPool.setIssuerAlloc(issuerAlloc);
        });

        it("user should be able to swap 10 sETH to 10000 sUSD with 50 sUSD fee + 50 sUSD burned", async function () {
            // initial liquidity of user1 and user2
            let initialUser1Debt = (await cryptoPool.getAccountLiquidity(user1.address))[2];
            let initialUser2Debt = (await cryptoPool.getAccountLiquidity(user2.address))[2];
            // user1 swaps 10 seth
            await seth.connect(user1).swap(ethers.utils.parseEther("10"), susd.address, user1.address, ethers.constants.AddressZero);
            // 10000 = 9900 + 100 (1%) fee
            let initialAmount = ethers.utils.parseEther("10000");
            let fee = initialAmount.mul(swapFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);

            // check if both user1 and user2 debt is reduced by 50/2 sUSD
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.equal(initialUser1Debt.sub(burnedIssuerAlloc.div(2)));
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.equal(initialUser2Debt.sub(burnedIssuerAlloc.div(2)));

            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(fee.sub(burnedIssuerAlloc));
            // expected output should be 9900
            expect(await susd.balanceOf(user1.address)).to.be.equal(initialAmount.sub(fee));
            // After swapping 10 sETH, balance should be 0 sETH
            expect(await seth.balanceOf(user1.address)).to.be.equal(ethers.constants.Zero); 
        });

        it("should update fee to 0.1% + 80% issuer alloc", async function () {
            issuerAlloc = 8000;
            swapFee = 10;
            await cryptoPool.connect(owner).updateSynth(seth.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
            await cryptoPool.connect(owner).updateSynth(susd.address, {mintFee: swapFee/2, isActive: true, isDisabled: false, burnFee: swapFee/2});
            await cryptoPool.setIssuerAlloc(issuerAlloc);
        });

        it("user should be able to swap 10 sETH to 10000 sUSD with 50 sUSD fee + 50 sUSD burned", async function () {
            // initial liquidity of user1 and user2
            let initialUser1Debt = (await cryptoPool.getAccountLiquidity(user1.address))[2];
            let initialUser2Debt = (await cryptoPool.getAccountLiquidity(user2.address))[2];
            // initial vault balance
            let initialVaultBalance = await susd.balanceOf(vault.address);
            // user1 swaps 10 seth
            await seth.connect(user2).swap(ethers.utils.parseEther("10"), susd.address, user2.address, ethers.constants.AddressZero);
            // 10000 = 9900 + 100 (1%) fee
            let initialAmount = ethers.utils.parseEther("10000");
            let fee = initialAmount.mul(swapFee).div(BASIS_POINTS);
            let burnedIssuerAlloc = fee.mul(issuerAlloc).div(BASIS_POINTS);

            // check if both user1 and user2 debt is reduced by 50/2 sUSD
            expect((await cryptoPool.getAccountLiquidity(user1.address))[2]).to.be.equal(initialUser1Debt.sub(burnedIssuerAlloc.div(2)));
            expect((await cryptoPool.getAccountLiquidity(user2.address))[2]).to.be.equal(initialUser2Debt.sub(burnedIssuerAlloc.div(2)));

            // vault balance should be fee
            expect(await susd.balanceOf(vault.address)).to.be.equal(initialVaultBalance.add(fee).sub(burnedIssuerAlloc));
            // expected output should be 9900
            expect(await susd.balanceOf(user2.address)).to.be.equal(initialAmount.sub(fee));
            // After swapping 10 sETH, balance should be 0 sETH
            expect(await seth.balanceOf(user2.address)).to.be.equal(ethers.constants.Zero); 
        });
    })
})