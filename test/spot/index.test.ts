// import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import main from '../../scripts/main';
import hre from 'hardhat';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import main from '../../scripts/main';
import { expect } from "chai";

describe("Testing perps", async () => {
    let spot: Contract, USDT: Contract, WETH: Contract, BTC: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    
    let orders: any[] = [];
    let signatures: string[] = [];
    let orderIds: string[] = [];

    before(async () => {
        [owner, user1, user2, user3] = await ethers.getSigners();
        const deployments = await loadFixture(main);
        spot = deployments.spot;
        USDT = deployments.dummyTokens[0];
        WETH = deployments.dummyTokens[1];
        BTC = deployments.dummyTokens[2];
    })

    it('mint tokens', async () => {
        await USDT.connect(user1).mint(user1.address, ethers.utils.parseEther("1000"));
        await WETH.connect(user2).mint(user2.address, ethers.utils.parseEther("1"));

        await USDT.connect(user1).approve(spot.address, ethers.utils.parseEther("1000"));
        await WETH.connect(user2).approve(spot.address, ethers.utils.parseEther("1"));
    })

    it('user1 create limit order to buy 1 WETH with 1000 USDC', async () => {
        const domain = {
			name: 'zexe',
			version: '1',
			chainId: hre.network.config.chainId,
			verifyingContract: spot.address,
		};

		// The named list of all type definitions
		const types = {
			Order: [
				{ name: 'maker', type: 'address' },
				{ name: 'token0', type: 'address' },
				{ name: 'token1', type: 'address' },
				{ name: 'amount', type: 'uint256' },
				{ name: 'price', type: 'uint128' },
                { name: 'expiry', type: 'uint64' },
				{ name: 'nonce', type: 'uint48' }
			],
		};

		// The data to sign
		const value = {
			maker: user1.address,
			token0: WETH.address, 
            token1: USDT.address,
			amount: ethers.utils.parseEther('1').toString(),
            price: ethers.utils.parseEther('1000'),
            expiry: ((Date.now()/1000) + 1000).toFixed(0),
            nonce: '12345'
		};

        orders.push(value);

		// sign typed data
		const storedSignature = await user1._signTypedData(
			domain,
			types,
			value
		);
		signatures.push(storedSignature);

		// get typed hash
		const hash = ethers.utils._TypedDataEncoder.hash(domain, types, value);
		expect(await spot.verifyOrderHash(storedSignature, value)).to.equal(hash);
        orderIds.push(hash);
    })

    it('user2 sell 1 WETH for 1000 USDT', async () => {
        await spot.connect(user2).executeLimitOrder(
            signatures[0],
            orders[0],
            ethers.utils.parseEther('1')
        )

        expect(await USDT.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await WETH.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('1'));

        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('1000'));
        expect(await WETH.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('0'));
    })
})