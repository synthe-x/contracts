// import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import main from '../../scripts/main';
import { Contract } from 'ethers';
import hre, { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {expect} from "chai";
import { deploy } from '../../scripts/margin/deploy';
const POOL_ADDR_PROVIDER = '0x4C2F7092C2aE51D986bEFEe378e50BD4dB99C901';
const deployments = require("../../deployments/31337/deployments.json");

describe("Testing margin", async () => {
    let spot: Contract, USDT: Contract, WETH: Contract, BTC: Contract, pool: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let crossPositionAddress: string;
    let orders : any[]= [];
    let signatures : string[]= [];
    let orderIds : string[]= [];

    before(async () => {
        [owner, user1, user2, user3] = await ethers.getSigners();
        const SpotFactory = await ethers.getContractFactory("Spot");
        spot = (await deploy()).spot;
        pool = await ethers.getContractAt("IPool", await spot.POOL());
        WETH = await ethers.getContractAt("MockToken", deployments.contracts['WETH'].address);
        USDT = await ethers.getContractAt("MockToken", deployments.contracts['USDC'].address);
    })

    it('mint tokens', async () => {
        // mint token
        await WETH.connect(user1).transfer(owner.address, await WETH.balanceOf(user1.address));
        await WETH.connect(user2).transfer(owner.address, await WETH.balanceOf(user2.address));
        await USDT.connect(user2).transfer(owner.address, await USDT.balanceOf(user2.address));

        await WETH.connect(user1).mint(user1.address, ethers.utils.parseEther("1"));
        await WETH.connect(user2).mint(user2.address, ethers.utils.parseEther("10"));

        await WETH.connect(user1).approve(spot.address, ethers.utils.parseEther("1"));
        await WETH.connect(user2).approve(spot.address, ethers.utils.parseEther("10"));

        // await USDT.connect(user2).mint(user2.address ,ethers.utils.parseEther("1000"));
        // expect(await WETH.balanceOf(user1.address)).to.equal(ether.par));
        // console.log((await WETH.balanceOf(user2.address)).toString());
    })

    it('supply initial liquidity to lending pool', async () => {
        const usdtAmount = ethers.utils.parseEther("1000000");
        const wethAmount = ethers.utils.parseEther("100");

        await USDT.connect(owner).mint(owner.address, usdtAmount);
        await WETH.connect(owner).mint(owner.address, wethAmount);

        await USDT.connect(owner).approve(pool.address, usdtAmount);
        await WETH.connect(owner).approve(pool.address, wethAmount);

        await pool.connect(owner).supply(USDT.address, usdtAmount, owner.address, 0);
        await pool.connect(owner).supply(WETH.address, wethAmount, owner.address, 0);
    })

    it('create cross position', async () => {
        await spot.connect(user1).createPosition([WETH.address, USDT.address]);
        // require(await spot.totalPositions(user1.address)).to.equal('1');
        // require(await spot.position(user1.address, 0)).to.not.equal(ethers.constants.AddressZero);
    })
   
    it('user1 longs 1 eth with 10x leverage', async () => {
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
        
        const value = {
            maker: user1.address,
            token0: WETH.address,
            token1: USDT.address,
            token0Amount: ethers.utils.parseEther('1').toString(),
            token1Amount: ethers.utils.parseEther('1000').toString(),
            leverage: 10,
            price: ethers.utils.parseEther('1000').toString(),
            expiry: ((Date.now() / 1000) + 1000).toFixed(0),
            nonce: '12345',
            action: 0,
            position: 0,
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

    it('user2 sells 9 eth for 9000 usdt', async () => {
        const amount = ethers.utils.parseEther('9');

        await spot.connect(user2).execute(
            orders,
            signatures,
            WETH.address,
            amount,
            USDT.address,
            ethers.constants.HashZero
        );

        expect(await WETH.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('1'));
        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('9000'));
        expect(await WETH.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('0'));
        // console.log(await WETH.balanceOf(user2.address))
        // console.log(await USDT.balanceOf(user2.address))
        // console.log(await WETH.balanceOf(user1.address))
        // console.log(await USDT.balanceOf(user1.address))
        // console.log('________');
    })

    it('user1 creates order to close 50% position', async () => {
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
            token0Amount: ethers.utils.parseEther('1').toString(),
            token1Amount: ethers.utils.parseEther('4500').toString(),
            leverage: 10,
            price: ethers.utils.parseEther('1000').toString(),
            expiry: ((Date.now() / 1000) + 1000).toFixed(0),
            nonce: '12346',
            action: 1,
            position: 0,
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
        expect(await spot.verifyOrderHash(value,storedSignature)).to.equal(hash);
        orderIds.push(hash);
        // console.log("value", value);
    })

    it('user2 closes 50% position', async () => {
        const amount = ethers.utils.parseEther('9200');

        await USDT.connect(user2).increaseAllowance(spot.address, amount.add(ethers.utils.parseEther('9200')));
       
        // console.log(await WETH.balanceOf(user2.address));
        // console.log(await USDT.balanceOf(user2.address));
        await spot.connect(user2).execute(
            orders,
            signatures,
            USDT.address,
            amount,
            WETH.address,
            ethers.constants.HashZero
        )
        // let crossPosition = await Margin.crossPosition(user1.address);
        // console.log("getUserAccountData",await Pool.getUserAccountData(crossPosition));
        // console.log("getUserConfiguration",await Pool.getUserConfiguration(crossPosition));
        // console.log("getUserEMode",await Pool.getUserEMode(crossPosition));
        // console.log("getReserveNormalizedIncome",await Pool.getReserveNormalizedIncome(crossPosition));
        // console.log("getReserveData",await Pool.getReserveData(crossPosition));
        // console.log(await WETH.balanceOf(user1.address));
        // console.log(await USDT.balanceOf(user1.address));
        // console.log(await WETH.balanceOf(user2.address));
        // console.log(await USDT.balanceOf(user2.address));
        expect(await WETH.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('5'));
        expect(await USDT.balanceOf(user2.address)).to.equal(ethers.utils.parseEther('4500'));
    })
    // cancelOrder(Order memory order, bytes memory signature)
    it("cancel Order", async ()=>{

        await spot.connect(user1).cancelOrder(
            orders[1],
            signatures[1]
        )
    })
})