// import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
// import main from '../../scripts/main';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const POOL_ADDR_PROVIDER = '0xa31F4c0eF2935Af25370D9AE275169CCd9793DA3';
const deployments = require("../../deployments/31337/deployments.json");

describe("Testing perps", async () => {
    let perps: Contract, USDCX: Contract, WETHX: Contract, synthex: Contract, pool: Contract, LINKX: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let crossPositionAddress: string;

    before(async () => {
        [owner, , user1, user2, user3] = await ethers.getSigners();
        const PerpsFactory = await ethers.getContractFactory("Perps");
        perps = await PerpsFactory.deploy(POOL_ADDR_PROVIDER, deployments.contracts['CRY'].address);
        await perps.deployed();

        synthex = await ethers.getContractAt("SyntheX", deployments.contracts['SyntheX'].address);
        pool = await ethers.getContractAt("IPool", await perps.POOL());
        USDCX = await ethers.getContractAt("ERC20X", deployments.contracts['cryUSDCx'].address);
        WETHX = await ethers.getContractAt("ERC20X", deployments.contracts['cryWETHx'].address);
        LINKX = await ethers.getContractAt("ERC20X", deployments.contracts['cryLINKx'].address);
    })

    it('mint tokens', async () => {
        await synthex.connect(user1).depositETH({value: ethers.utils.parseEther("1")});

        await USDCX.connect(user1).mint(ethers.utils.parseEther("100"));
        await WETHX.connect(user1).mint(ethers.utils.parseEther("0.1"));
    })

    it('supply initial liquidity to lending pool', async () => {
        await synthex.connect(owner).depositETH({value: ethers.utils.parseEther("100")});

        const usdcxAmount = ethers.utils.parseEther("10000");
        const wethxAmount = ethers.utils.parseEther("10");
        const linkxAmount = ethers.utils.parseEther("1000");

        await USDCX.connect(owner).mint(usdcxAmount);
        await WETHX.connect(owner).mint(wethxAmount);
        await LINKX.connect(owner).mint(linkxAmount);

        await USDCX.connect(owner).approve(pool.address, usdcxAmount);
        await WETHX.connect(owner).approve(pool.address, wethxAmount);
        await LINKX.connect(owner).approve(pool.address, linkxAmount);

        await pool.connect(owner).supply(USDCX.address, usdcxAmount, owner.address, 0);
        await pool.connect(owner).supply(WETHX.address, wethxAmount, owner.address, 0);
        await pool.connect(owner).supply(LINKX.address, linkxAmount, owner.address, 0);
    })

    it('create cross position', async () => {
        await perps.connect(user1).createCrossPosition();
        crossPositionAddress = await perps.crossPosition(user1.address);
    })

    it('user1 longs 0.1 eth with 50x leverage', async () => {
        const baseAmount = ethers.utils.parseEther("0.1");
        await perps.connect(user1).openPosition(WETHX.address, baseAmount, USDCX.address, 25);
    })

    it('user1 closes 50% of 5 ETH long', async () => {
        const baseAmount = ethers.utils.parseEther("2.5");
        await perps.connect(user1).closePosition(USDCX.address, baseAmount, WETHX.address);
    })

    // it('user2 shorts 100 usd on eth with 50x leverage', async () => {
    //     const baseAmount = ethers.utils.parseEther("100");
    //     await USDCX.connect(user1).approve(pool.address, baseAmount);
    //     await pool.connect(user1).supply(USDCX.address, baseAmount, crossPositionAddress, 0);
    //     await perps.connect(user1).openPosition(USDCX.address, baseAmount, WETHX.address, 25);
    // });
})