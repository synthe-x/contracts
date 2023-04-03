import type { SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers";
import { takeSnapshot } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { SyntheX, Pool, ERC20X, IWETH } from "../../typechain-types";

const parseEther = ethers.utils.parseEther;
const toBN = ethers.BigNumber.from;
const ZERO_ADDRESS = ethers.constants.ZERO_ADDRESS;
const provider = ethers.provider;

describe.only("ERC20X", function () {
    let snapshotA: SnapshotRestorer;

	let syntheX: SyntheX;
    let pool: Pool;
    let erc20X: ERC20X;
    let weth: IWETH;
    
    let deployer: SignerWithAddress, owner: SignerWithAddress, user: SignerWithAddress;

	before(async () => {
		[deployer, owner, user] = await ethers.getSigners();

        const SyntheX = await ethers.getContractFactory("SyntheX");
        syntheX = (await upgrades.deployProxy(SyntheX, [deployer.address, owner.address, user.address])) as SyntheX;

        const Weth = await ethers.getContractFactory("WETH9");
        weth = (await Weth.deploy()) as IWETH;

        const Pool = await ethers.getContractFactory("Pool");
        pool = (await upgrades.deployProxy(Pool, ["Test", "TST", syntheX.address, weth.address])) as Pool;

        const ERC20X = await ethers.getContractFactory("ERC20X", deployer)
        erc20X = await upgrades.deployProxy(ERC20X, [
                "ERC20X",
                "ERC20x",
                pool.address,
                syntheX.address
            ],
            { unsafeAllow: ['delegatecall'] }
        ) as ERC20X

        snapshotA = await takeSnapshot();
	});

    afterEach(async function () {
        await snapshotA.restore();
    });

    it.skip("Should not set uncorrect pool address at initialization", async function () {
        // redeploy ERC20X
        const ERC20X = await ethers.getContractFactory('ERC20X')
        let testErc20x = await ERC20X.deploy()
        await testErc20x.deployed()
        expect(testErc20x.address).to.be.not.equal(ZERO_ADDRESS);

        // try uncorrect init ERC20X
        await expect(testErc20x.initialize(testName, testSymbol, owner.address, syntheX.address)).to.be.reverted;
	});

    it.skip("Should not set uncorrect syntheX address at initialization", async function () {
        // try uncorrect init ERC20X
        await expect(await ERC20X.deploy("Test", "TST", pool.address, syntheX.address)).to.be.reverted;
	});

    it("Should not mint if contract paused", async function () {
        // try mint
        let amount = 100;
        let recipient = owner.address;
        let referredBy = owner.address;
        let stringError = "Pausable: paused";
        await expect(erc20X.mint(amount, recipient, referredBy)).to.be.revertedWith(stringError);
	});

    it("Should not .mintInternal() if sender is not Pool contract", async function () {
        // try mintInternal
        let amount = 100;
        let account = owner.address;
        let stringError = "15";
        await expect(erc20X.mintInternal(account, amount)).to.be.revertedWith(stringError);
	});

    it("Should not .burnInternal() if sender is not Pool contract", async function () {
        // try burnInternal
        let amount = 100;
        let account = owner.address;
        let stringError = "15";
        await expect(erc20X.burnInternal(account, amount)).to.be.revertedWith(stringError);
	});

    it("Should not mint amount = 0", async function () {
        // try mint
        let amount = 0;
        let recipient = user.address;
        let referredBy = owner.address;
        let stringError = "7";
        await expect(erc20X.mint(amount, recipient, referredBy)).to.be.revertedWith(stringError);
	});

    it("Should not burn amount = 0", async function () {
        // try burn
        let amount = 0;
        let stringError = "7";
        await expect(erc20X.burn(amount)).to.be.revertedWith(stringError);
	});

    it("Should not swap amount = 0", async function () {
        // try swap
        let amount = 0;
        let synthTo = syntheX.address;
        let recipient = user.address;
        let referredBy = owner.address;
        let stringError = "7";
        await expect(erc20X.swap(amount, synthTo, recipient, referredBy)).to.be.revertedWith(stringError);
	});

    it("Should not liquidate amount = 0", async function () {
        // try liquidate
        let account = owner.address;
        let amount = 0;
        let outAsset = user.address;
        let stringError = "7";
        await expect(erc20X.liquidate(account, amount, outAsset)).to.be.revertedWith(stringError);
	});

    it("Should update flash fee", async function () {
        let newFlashFee = await erc20X.BASIS_POINTS();
        console.log(newFlashFee);
        newFlashFee = parseEther("1");
        console.log(newFlashFee);
        let event = "FlashFeeUpdated";
        expect(await erc20X.connect(user).updateFlashFee(newFlashFee)).to.emit(erc20X, event);
	});

    it("Should not update flash fee if sender is not L1 admin", async function () {
        let newFlashFee = 1;
        let stringError = "2";
        await expect(erc20X.updateFlashFee(newFlashFee)).to.be.revertedWith(stringError);
	});

    it(".burnInternal() should work correct", async function () {
        // deploy Pool mock
        const PoolMock = await ethers.getContractFactory('PoolMock')
        let poolMock = await PoolMock.deploy()
        await poolMock.deployed()
        expect(poolMock.address).to.be.not.equal(ZERO_ADDRESS);

        // init Pool mock
        await poolMock.connect(user2).initialize(testName, testSymbol, syntheX.address);

        // deploy ERC20X used Mock
        const ERC20XMock = await ethers.getContractFactory('ERC20XMock')
        let erc20XMock = await ERC20XMock.deploy()
        await erc20XMock.deployed()
        expect(erc20XMock.address).to.be.not.equal(ZERO_ADDRESS);

        // init ERC20X used Mock
        await erc20XMock.initialize(testName, testSymbol, poolMock.address, syntheX.address);

        // set ERC20X token address to Pool mock
        await poolMock.setAddressERC20X(erc20XMock.address);

        // burn (revert from ERC20.sol, not from ERC20X.sol)
        let account = owner.address;
        let amount = 100;
        let stringError = "ERC20: burn amount exceeds balance";
        await expect(poolMock.burnERC20X(account, amount)).to.be.revertedWith(stringError);
	});

    it("Should get flash fee from contract-inheritor", async function () {
        // deploy Pool mock
        const PoolMock = await ethers.getContractFactory('PoolMock')
        let poolMock = await PoolMock.deploy()
        await poolMock.deployed()
        expect(poolMock.address).to.be.not.equal(ZERO_ADDRESS);

        // init Pool mock
        await poolMock.connect(user2).initialize(testName, testSymbol, syntheX.address);

        // deploy ERC20X used Mock
        const ERC20XMock = await ethers.getContractFactory('ERC20XMock')
        let erc20XMock = await ERC20XMock.deploy()
        await erc20XMock.deployed()
        expect(erc20XMock.address).to.be.not.equal(ZERO_ADDRESS);

        // init ERC20X used Mock
        await erc20XMock.initialize(testName, testSymbol, poolMock.address, syntheX.address);

        // set ERC20X token address to Pool mock
        await poolMock.setAddressERC20X(erc20XMock.address);

        // get flash fee
        let token = erc20X.address;
        let amount = 100;
        let flashFee = await erc20XMock.getFlashFee(token, amount);
        expect(flashFee).to.be.equal(0);
	});

    it("Should get flash fee receiver from contract-inheritor", async function () {
        // deploy Pool mock
        const PoolMock = await ethers.getContractFactory('PoolMock')
        let poolMock = await PoolMock.deploy()
        await poolMock.deployed()
        expect(poolMock.address).to.be.not.equal(ZERO_ADDRESS);

        // init Pool mock
        await poolMock.connect(user2).initialize(testName, testSymbol, syntheX.address);

        // deploy ERC20X used Mock
        const ERC20XMock = await ethers.getContractFactory('ERC20XMock')
        let erc20XMock = await ERC20XMock.deploy()
        await erc20XMock.deployed()
        expect(erc20XMock.address).to.be.not.equal(ZERO_ADDRESS);

        // init ERC20X used Mock
        await erc20XMock.initialize(testName, testSymbol, poolMock.address, syntheX.address);

        // set ERC20X token address to Pool mock
        await poolMock.setAddressERC20X(erc20XMock.address);

        // get flash fee receiver
        let flashFeeReceiver = await erc20XMock.getFlashFeeReceiver();
        expect(flashFeeReceiver).to.be.equal(ZERO_ADDRESS);
	});
});
