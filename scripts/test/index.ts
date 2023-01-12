import hre, { ethers } from "hardhat";
import { Contract } from "ethers";
import { ETH_ADDRESS } from "../utils/const";
const { upgrades } = require("hardhat");

export default async function main(deployerAddress: string) {

	// deploy SYN
	const SYN = await ethers.getContractFactory("SyntheXToken");
	const syn = await SYN.deploy();
	await syn.deployed();

    // deploy synthex
    const SyntheX = await ethers.getContractFactory("SyntheX");
    const synthex = await upgrades.deployProxy(SyntheX, [syn.address, deployerAddress, deployerAddress, deployerAddress], {type: 'uups'});
    await synthex.deployed();

    // deploy priceoracle
    const Oracle = await ethers.getContractFactory("PriceOracle");
    const oracle = await Oracle.deploy();
    await oracle.deployed();

    await synthex.setOracle(oracle.address);

	// create pool
	const SyntheXPool = await ethers.getContractFactory("SyntheXPool");
	const pool = await upgrades.deployProxy(
		SyntheXPool,
		["Crypto SyntheX", "CRYPTOX", synthex.address]
	);
	await pool.deployed();

	await pool.updateFee(ethers.utils.parseEther('0.001')); // 0.1%

	await synthex.enableTradingPool(
		pool.address,
		ethers.utils.parseEther("0.9")
	);
	await syn.mint(synthex.address, ethers.utils.parseEther("100000000"));
	await synthex.setPoolSpeed(pool.address, ethers.utils.parseEther("0.1"));

	const ERC20X = await ethers.getContractFactory("ERC20X");
	const PriceFeed = await ethers.getContractFactory("MockPriceFeed");
	const Collateral = await ethers.getContractFactory("MockToken");

	// collateral eth
	const ethPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1000", 8), 8);
	await ethPriceFeed.deployed();
	await oracle.setFeed(ETH_ADDRESS, ethPriceFeed.address);
	await synthex.enableCollateral(ETH_ADDRESS, ethers.utils.parseEther("0.9"));

	// susd
	const susd = await ERC20X.deploy("SyntheX USD", "USDx", pool.address);
	await susd.deployed();
	const susdPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1", 8), 8);
	await susdPriceFeed.deployed();
	await oracle.setFeed(susd.address, susdPriceFeed.address);
	await pool.enableSynth(susd.address);

	// sbtc
	const sbtc = await ERC20X.deploy("SyntheX BTC", "BTCx", pool.address);
	await sbtc.deployed();
	const sbtcPriceFeed = await PriceFeed.deploy(
		ethers.utils.parseUnits("10000", 8), 8
	);
	await sbtcPriceFeed.deployed();
	await oracle.setFeed(sbtc.address, sbtcPriceFeed.address);
	await pool.enableSynth(sbtc.address);

	// seth
	const seth = await ERC20X.deploy("SyntheX ETH", "ETHx", pool.address);
	await seth.deployed();
	await oracle.setFeed(seth.address, ethPriceFeed.address);
	await pool.enableSynth(seth.address);

	return { syn, synthex, oracle, ethPriceFeed, sbtcPriceFeed, pool, susd, sbtc, seth };
}