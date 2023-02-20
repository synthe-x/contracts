// import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import main from '../../scripts/main';
import { Contract } from 'ethers';
import hre, { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {expect} from "chai";
const POOL_ADDR_PROVIDER = '0x9DBb24B10502aD166c198Dbeb5AB54d2d13AfcFd';
const deployments = require("../../deployments/31337/deployments.json");

describe("Testing margin", async () => {
    let Margin: Contract, USDT: Contract, WETH: Contract, BTC: Contract, Pool: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let crossPositionAddress: string;
    let orders : any[]= [];
    let signatures : string[]= [];
    let orderIds : string[]= [];

    before(async () => {
        [owner, , , , user1, user2, user3] = await ethers.getSigners();
        const MarginFactory = await ethers.getContractFactory("Margin");
        Margin = await MarginFactory.deploy(POOL_ADDR_PROVIDER);
        await Margin.deployed();

        Pool = await ethers.getContractAt("IPool", await Margin.POOL());
        WETH = await ethers.getContractAt("MockToken", deployments.contracts['WETH'].address);
        USDT = await ethers.getContractAt("MockToken", deployments.contracts['USDC'].address);
        // BTC = await ethers.getContractAt("ERC20X", deployments.contracts['DUMMYBTC'].address);
    })

    it('mint tokens', async () => {
        // mint token
        await WETH.connect(user1).transfer(owner.address, await WETH.balanceOf(user1.address));
        await WETH.connect(user2).transfer(owner.address, await WETH.balanceOf(user2.address));
        await USDT.connect(user2).transfer(owner.address, await USDT.balanceOf(user2.address));

        await WETH.connect(user1).mint(user1.address, ethers.utils.parseEther("1"));
        await WETH.connect(user2).mint(user2.address, ethers.utils.parseEther("9"));

        await WETH.connect(user1).approve(Margin.address, ethers.utils.parseEther("1"));
        await WETH.connect(user2).approve(Margin.address, ethers.utils.parseEther("9"));

        // await USDT.connect(user2).mint(user2.address ,ethers.utils.parseEther("1000"));
        // expect(await WETH.balanceOf(user1.address)).to.equal(ether.par));
        // console.log((await WETH.balanceOf(user2.address)).toString());
    })

    it('supply initial liquidity to lending pool', async () => {
        const usdtAmount = ethers.utils.parseEther("1000000");
        const wethAmount = ethers.utils.parseEther("100");

        await USDT.connect(owner).mint(owner.address, usdtAmount);
        await WETH.connect(owner).mint(owner.address, wethAmount);

        await USDT.connect(owner).approve(Pool.address, usdtAmount);
        await WETH.connect(owner).approve(Pool.address, wethAmount);

        await Pool.connect(owner).supply(USDT.address, usdtAmount, owner.address, 0);
        await Pool.connect(owner).supply(WETH.address, wethAmount, owner.address, 0);
    })

    it('create cross position', async () => {
        await Margin.connect(user1).createCrossPosition();
        crossPositionAddress = await Margin.crossPosition(user1.address);
    })
   
    it('user1 longs 1 eth with 10x leverage', async () => {
        const domain = {
            name: 'zexe',
            version: '1',
            chainId: hre.network.config.chainId,
            verifyingContract: Margin.address,
        };

        // The named list of all type definitions
        const types = {
            OpenOrder: [
                { name: 'isIsolated', type: 'bool'},
                { name: 'maker', type: 'address' },
                { name: 'token0', type: 'address' },
                { name: 'token1', type: 'address' },
                { name: 'token0Amount', type: 'uint256' },
                { name: "leverage", type: "uint16" },
                { name: 'price', type: 'uint128' },
                { name: 'expiry', type: 'uint64' },
                { name: 'nonce', type: 'uint48' },
            ],
        };

        // The data to sign
        const value = {
            isIsolated: false,
            maker: user1.address,
            token0: WETH.address,
            token1: USDT.address,
            token0Amount: ethers.utils.parseEther('1').toString(),
            leverage: 10,
            price: ethers.utils.parseEther('1000').toString(),
            expiry: ((Date.now() / 1000) + 1000).toFixed(0),
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
        // expect(await Margin.verifyOpenOrderHash(storedSignature, value)).to.equal(hash);
        orderIds.push(hash);
    })

    it('user2 sells 9 eth for 9000 usdt', async () => {
        const amount = ethers.utils.parseEther('9');
        await Margin.connect(user2).openPosition(
            orders[0],
            signatures[0],
            amount
        )

        expect(await WETH.balanceOf(user2.address)).to.equal(0);
        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('9000'));
        expect(await WETH.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('0'));
    })

    it('user1 creates order to close 50% position', async () => {
        const domain = {
            name: 'zexe',
            version: '1',
            chainId: hre.network.config.chainId,
            verifyingContract: Margin.address,
        };

        // The named list of all type definitions
        const types = {
            CloseOrder: [
                { name: 'isIsolated', type: 'bool' },
                { name: 'maker', type: 'address' },
                { name: 'token0', type: 'address' },
                { name: 'token1', type: 'address' },
                { name: 'token0Amount', type: 'uint256' },
                { name: 'token1Amount', type: 'uint256' },
                { name: 'price', type: 'uint128' },
                { name: 'expiry', type: 'uint64' },
                { name: 'nonce', type: 'uint48' },
            ],
        };

        // The data to sign
        const value = {
            isIsolated: false,
            maker: user1.address,
            token0: WETH.address,
            token1: USDT.address,
            token0Amount: ethers.utils.parseEther('5'),
            token1Amount: ethers.utils.parseEther('4500'),
            price: ethers.utils.parseEther('1000'),
            expiry: ((Date.now() / 1000) + 1000).toFixed(0),
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
        // expect(await Margin.verifyCloseOrderHash(storedSignature, value)).to.equal(hash);
        orderIds.push(hash);
    })

    it('user2 closes 50% position', async () => {
        const amount = ethers.utils.parseEther('4500');

        await USDT.connect(user2).increaseAllowance(Margin.address, amount.add(ethers.utils.parseEther('1000')));
        await Margin.connect(user2).closePosition(
            orders[1],
            signatures[1],
            amount
        ) 

        expect(await WETH.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('5'));
        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('4500'));
    })
})