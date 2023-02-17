// import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import main from '../../scripts/main';
import { Contract } from 'ethers';
import hre, { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {expect} from "chai";
const POOL_ADDR_PROVIDER = '0xa31F4c0eF2935Af25370D9AE275169CCd9793DA3';
const deployments = require("../../deployments/31337/deployments.json");

describe("Testing margin", async () => {
    let Margin: Contract, USDT: Contract, WETH: Contract, BTC: Contract, Pool: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let crossPositionAddress: string;
    let orders : any[]= [];
    let signatures : string[]= [];
    let orderIds : string[]= [];

    before(async () => {
        [owner, , user1, user2, user3] = await ethers.getSigners();
        const MarginFactory = await ethers.getContractFactory("Margin");
        Margin = await MarginFactory.deploy();
        await Margin.deployed();
        // console.log("Margin", await Margin.POOL());
        console.log("WETH", deployments.contracts['WETH'].address);
        console.log("USDC", deployments.contracts['USDC'].address);

        Pool = await ethers.getContractAt("IPool", "0xD781C44726058d2971B58408c492192877FAAC17");
        USDT = await ethers.getContractAt("MockToken", deployments.contracts['WETH'].address);
        WETH = await ethers.getContractAt("MockToken", deployments.contracts['USDC'].address);
        // BTC = await ethers.getContractAt("ERC20X", deployments.contracts['DUMMYBTC'].address);
    })

    it('mint tokens', async () => {
        // await USDT.connect(user1).mint(user1.address ,ethers.utils.parseEther("10"));
        // mint token
        await WETH.connect(user1).mint(user1.address, ethers.utils.parseEther("10"));
        await WETH.connect(user2).mint(user2.address, ethers.utils.parseEther("20"));
        expect(await WETH.balanceOf(user1.address)).to.equal(ether.par));
        console.log((await WETH.balanceOf(user2.address)).toString());
    })

    it('supply initial liquidity to lending pool', async () => {


        const usdtAmount = ethers.utils.parseEther("1000000");
        const wethAmount = ethers.utils.parseEther("100");


        await USDT.connect(owner).mint(usdtAmount);
        await WETH.connect(owner).mint(wethAmount);


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
            Order: [
                { name: 'maker', type: 'address' },
                { name: 'token0', type: 'address' },
                { name: 'token1', type: 'address' },
                { name: 'amount', type: 'uint256' },
                { name: 'price', type: 'uint128' },
                { name: 'expiry', type: 'uint64' },
                { name: 'nonce', type: 'uint48' },
                { name: "leverage", type: "uint16" }
            ],
        };

        // The data to sign
        const value = {
            maker: user1.address,
            token0: WETH.address,
            token1: USDT.address,
            amount: ethers.utils.parseEther('1').toString(),
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
        console.log(value);
        // get typed hash
        const hash = ethers.utils._TypedDataEncoder.hash(domain, types, value);
        expect(await Margin.verifyOrderHash(storedSignature, value)).to.equal(hash);
        orderIds.push(hash);
    })


})