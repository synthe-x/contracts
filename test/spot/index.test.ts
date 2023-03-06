// import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import main from '../../scripts/main';
import hre from 'hardhat';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from "chai";
import { deploy } from '../../scripts/margin/deploy';
import { POOL_ADDRESS_PROVIDER } from '../../scripts/utils/const';
const deployments = require("../../deployments/31337/deployments.json");

describe("Testing perps", async () => {
    let spot: Contract, pool: Contract, USDT: Contract, WETH: Contract, BTC: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    
    let orders: any[] = [];
    let signatures: string[] = [];
    let orderIds: string[] = [];

    before(async () => {
        [owner, user1, user2, user3] = await ethers.getSigners();
        const SpotFactory = await ethers.getContractFactory("Spot");
        spot = (await deploy()).spot;
        pool = await ethers.getContractAt("IPool", await spot.POOL());
        WETH = await ethers.getContractAt("MockToken", deployments.contracts['WETH'].address);
        USDT = await ethers.getContractAt("MockToken", deployments.contracts['USDC'].address);
    })

    it('mint tokens', async () => {
        // burn all
        await WETH.connect(user1).transfer(POOL_ADDRESS_PROVIDER, await WETH.balanceOf(user1.address));
        await USDT.connect(user1).transfer(POOL_ADDRESS_PROVIDER, await USDT.balanceOf(user1.address));
        await WETH.connect(user2).transfer(POOL_ADDRESS_PROVIDER, await WETH.balanceOf(user2.address));
        await USDT.connect(user2).transfer(POOL_ADDRESS_PROVIDER, await USDT.balanceOf(user2.address));

        await USDT.connect(user1).mint(user1.address, ethers.utils.parseEther("1000"));

        await WETH.connect(user2).mint(user2.address, ethers.utils.parseEther("1"));
    })

    it('user1 create limit order to buy 1 WETH with 1000 USDC', async () => {
        // approve
        await USDT.connect(user1).approve(spot.address, ethers.utils.parseEther("1000"));

        // create order
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
                { name: 'token0Amount', type: 'uint256' },
                { name: 'token1Amount', type: 'uint256' },
                { name: 'leverage', type: 'uint256' },
                { name: 'price', type: 'uint256' },
                { name: 'expiry', type: 'uint256' },
                { name: 'nonce', type: 'uint256' },
                { name: 'action', type: 'uint256' },
                { name: 'position', type: 'uint256' }
			],
		};

		// The data to sign
		const value = {
			maker: user1.address,
			token0: WETH.address, 
            token1: USDT.address,
			token0Amount: ethers.utils.parseEther('1'),
			token1Amount: 0,
            leverage: 1,
            price: ethers.utils.parseEther('1000'),
            expiry: ((Date.now()/1000) + 1000).toFixed(0),
            nonce: '12345',
            action: 2,
            position: 0
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
		expect(await spot.verifyOrderHash(value, storedSignature)).to.equal(hash);
        orderIds.push(hash);
    })

    it('user2 sell 1 WETH for 1000 USDT', async () => {
        // approve
        await WETH.connect(user2).approve(spot.address, ethers.utils.parseEther("1"));

        // execute order
        await spot.connect(user2).execute(
            [orders[0]],
            [signatures[0]],
            WETH.address,
            ethers.utils.parseEther('1'),
            USDT.address,
            ethers.constants.HashZero
        )

        expect(await USDT.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await WETH.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('1'));

        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('1000'));
        expect(await WETH.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('0'));
    })

    it('user1 create limit order to buy 500 USDT with 0.5 WETH', async () => {
        // approve
        await WETH.connect(user1).approve(spot.address, ethers.utils.parseEther("0.5"));

        // create order
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
                { name: 'token0Amount', type: 'uint256' },
                { name: 'token1Amount', type: 'uint256' },
                { name: 'leverage', type: 'uint256' },
                { name: 'price', type: 'uint256' },
                { name: 'expiry', type: 'uint256' },
                { name: 'nonce', type: 'uint256' },
                { name: 'action', type: 'uint256' },
                { name: 'position', type: 'uint256' }
			],
		};

		// The data to sign
		const value = {
			maker: user1.address,
			token0: USDT.address, 
            token1: WETH.address,
			token0Amount: ethers.utils.parseEther('1000').toString(),
            token1Amount: 0,
            leverage: 1,
            price: ethers.utils.parseEther('0.001'),
            expiry: ((Date.now()/1000) + 1000).toFixed(0),
            nonce: '12345',
            action: 2,
            position: 0
		};

        orders.push(value);

		// sign typed data
		const storedSignature = await user1._signTypedData(
			domain,
			types,
			value
		);
		signatures.push(storedSignature);
            // console.log(value)
		// get typed hash
		const hash = ethers.utils._TypedDataEncoder.hash(domain, types, value);
		expect(await spot.verifyOrderHash(value, storedSignature)).to.equal(hash);
        orderIds.push(hash);
    })

    it('user2 sell 500 USDT for 0.5 WETH', async () => {
        // approve
        await USDT.connect(user2).approve(spot.address, ethers.utils.parseEther("500"));

        // execute order
        await spot.connect(user2).execute(
            [orders[1]],
            [signatures[1]],
            USDT.address,
            ethers.utils.parseEther('500'),
            WETH.address,
            ethers.constants.HashZero
        )

        expect(await USDT.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('500'));
        expect(await WETH.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('0.5'));

        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('500'));
        expect(await WETH.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('0.5'));

    });

    it("cancel Order", async ()=>{
        await spot.connect(user1).cancelOrder(
            orders[1],
            signatures[1]
        )
    })
})