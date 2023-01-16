import hre, { ethers } from "hardhat";
import { Contract } from "ethers";
import { ETH_ADDRESS, POOL_MANAGER, PRICE_ORACLE, SYNTHEX, VAULT } from '../utils/const';
const { upgrades } = require("hardhat");

export default async function main(deployerAddress: string) {
	// address manage
	const AddressManager = await ethers.getContractFactory("AddressStorage");
	const addressManager = await AddressManager.deploy(deployerAddress);
	await addressManager.deployed();
	await addressManager.setAddress(POOL_MANAGER, deployerAddress);

	// vault
	const Vault = await ethers.getContractFactory("Vault");
	const vault = await Vault.deploy(deployerAddress);
	await vault.deployed();

	await addressManager.setAddress(VAULT, vault.address);

	// deploy SYN
	const SYN = await ethers.getContractFactory("SyntheXToken");
	const syn = await SYN.deploy(deployerAddress);
	await syn.deployed();

	// deploy Sealed SYN
	const SealedSYN = await ethers.getContractFactory("SealedSYN");
	const sealedSYN = await SealedSYN.deploy(deployerAddress);
	await sealedSYN.deployed();

    // deploy synthex
    const SyntheX = await ethers.getContractFactory("SyntheX");
    const synthex = await upgrades.deployProxy(SyntheX, [sealedSYN.address, addressManager.address], {type: 'uups'});
    await synthex.deployed();

	await addressManager.setAddress(SYNTHEX, synthex.address);

    // deploy priceoracle
    const Oracle = await ethers.getContractFactory("PriceOracle");
    const oracle = await Oracle.deploy();
    await oracle.deployed();

	await addressManager.setAddress(PRICE_ORACLE, oracle.address);

	// create pool
	const SyntheXPool = await ethers.getContractFactory("SyntheXPool");
	const pool = await upgrades.deployProxy(
		SyntheXPool,
		["Crypto SyntheX", "CRYPTOX", addressManager.address]
	);
	await pool.deployed();

	// deploy staking rewards
	// SEALED_SYN_STAKING_REWARD: SYN on staking sSYN
	const StakingRewards = await ethers.getContractFactory("StakingRewards");
	const stakingRewards = await upgrades.deployProxy(StakingRewards, [syn.address, sealedSYN.address], {
		initializer: 'initialize(address,address)',
		type: 'uups'
	});

	await synthex.enableTradingPool(
		pool.address,
		ethers.utils.parseEther("0.9")
	);
	const minterRole = await sealedSYN.MINTER_ROLE();
	await sealedSYN.grantRole(minterRole, synthex.address);
	await sealedSYN.grantRole(minterRole, stakingRewards.address);
	
	await synthex.setPoolSpeed(sealedSYN.address, pool.address, ethers.utils.parseEther("0.1"));

	const ERC20X = await ethers.getContractFactory("ERC20X");
	const PriceFeed = await ethers.getContractFactory("MockPriceFeed");

	// collateral eth
	const ethPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1000", 8), 8);
	await ethPriceFeed.deployed();
	await oracle.setFeed(ETH_ADDRESS, ethPriceFeed.address);
	await synthex.enableCollateral(ETH_ADDRESS, ethers.utils.parseEther("0.9"));
    await synthex.setCollateralCap(ETH_ADDRESS, ethers.constants.MaxUint256);

	// susd
	const susd = await ERC20X.deploy("SyntheX USD", "USDx", pool.address, addressManager.address);
	await susd.deployed();
	const susdPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1", 8), 8);
	await susdPriceFeed.deployed();
	await oracle.setFeed(susd.address, susdPriceFeed.address);
	await pool.enableSynth(susd.address);
	await pool.updateFeeToken(susd.address);

	// sbtc
	const sbtc = await ERC20X.deploy("SyntheX BTC", "BTCx", pool.address, addressManager.address);
	await sbtc.deployed();
	const sbtcPriceFeed = await PriceFeed.deploy(
		ethers.utils.parseUnits("10000", 8), 8
	);
	await sbtcPriceFeed.deployed();
	await oracle.setFeed(sbtc.address, sbtcPriceFeed.address);
	await pool.enableSynth(sbtc.address);

	// seth
	const seth = await ERC20X.deploy("SyntheX ETH", "ETHx", pool.address, addressManager.address);
	await seth.deployed();
	await oracle.setFeed(seth.address, ethPriceFeed.address);
	await pool.enableSynth(seth.address);

	return { syn, synthex, oracle, ethPriceFeed, sbtcPriceFeed, pool, susd, sbtc, seth, vault, addressManager, stakingRewards, sealedSYN };
}