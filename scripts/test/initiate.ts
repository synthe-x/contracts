import hre, { ethers } from "hardhat";
import { Contract } from "ethers";
import { ETH_ADDRESS } from '../utils/const';
const { upgrades } = require("hardhat");

export default async function initiatePool(synthex: Contract, oracle: Contract, deployments: any, config: any, addressStorage: Contract, sealedSYN: Contract) {

	// create pool
	const SyntheXPool = await ethers.getContractFactory("DebtPool");
	const pool = await upgrades.deployProxy(
		SyntheXPool,
		["Crypto SyntheX", "CRYPTOX", addressStorage.address]
	);
	await pool.deployed();

	await synthex.enableTradingPool(
		pool.address,
		ethers.utils.parseEther("0.9")
	);
	
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
	const susd = await ERC20X.deploy("SyntheX USD", "USDx", pool.address, addressStorage.address);
	await susd.deployed();
	const susdPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1", 8), 8);
	await susdPriceFeed.deployed();
	await oracle.setFeed(susd.address, susdPriceFeed.address);
	await pool.enableSynth(susd.address);
	await pool.updateFeeToken(susd.address);

	// sbtc
	const sbtc = await ERC20X.deploy("SyntheX BTC", "BTCx", pool.address, addressStorage.address);
	await sbtc.deployed();
	const sbtcPriceFeed = await PriceFeed.deploy(
		ethers.utils.parseUnits("10000", 8), 8
	);
	await sbtcPriceFeed.deployed();
	await oracle.setFeed(sbtc.address, sbtcPriceFeed.address);
	await pool.enableSynth(sbtc.address);

	// seth
	const seth = await ERC20X.deploy("SyntheX ETH", "ETHx", pool.address, addressStorage.address);
	await seth.deployed();
	await oracle.setFeed(seth.address, ethPriceFeed.address);
	await pool.enableSynth(seth.address);


	return { ethPriceFeed, sbtcPriceFeed, pool, susd, sbtc, seth };
}