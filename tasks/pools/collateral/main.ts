import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { _deploy as _deployEVM } from '../../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../../scripts/utils/defender';
import { Contract } from 'ethers';
import { CollateralArgs } from '../../../deployments/types';

export default async function main(cConfig: CollateralArgs, pool: Contract, isTest: boolean = false, _deploy = _deployEVM): Promise<{collateral: Contract, feed: Contract|null}> {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
	// get collateral
	let collateral: string|Contract = cConfig.address as string;
	let feed: string|Contract|null = cConfig.feed;
	
	// handle compound based collateral (cTokens)
	if(cConfig.isCToken){
		const cToken = await ethers.getContractAt('CTokenInterface', collateral);
		const comptroller = await cToken.comptroller();
		feed = await _deploy('CompoundOracle', [comptroller, cToken.address, cConfig.decimals], deployments, {name: `${cConfig.symbol}_PriceFeed`});
		if(!isTest) console.log(`Deployed CompoundOracle for ${cConfig.symbol} at ${feed.address}`);
		feed = feed.address;
	}
	// handle aave based collateral (aTokens)
	else if(cConfig.isAToken){
		const aToken = await ethers.getContractAt('IAToken', collateral);
		const underlying = await aToken.UNDERLYING_ASSET_ADDRESS();
		collateral = (await _deploy('ATokenWrapper', ["Wrapped "+cConfig.name, "w"+cConfig.symbol, aToken.address], deployments, {name: cConfig.symbol})).address;
		if(!isTest) console.log(`Deployed ATokenWrapper for ${cConfig.symbol} at ${collateral}`);
		feed = await _deploy('AAVEOracle', [collateral, underlying, cConfig.poolAddressesProvider, cConfig.decimals], deployments, {name: `${cConfig.symbol}_PriceFeed`});
		if(!isTest) console.log(`Deployed AAVEOracle for ${cConfig.symbol} at ${feed.address}`);
		feed = feed.address;
		// aToken wrapper
	}
	// handle secondary oracle feeds
	else if(cConfig.isFeedSecondary){
		// deploy secondary price feed
		feed = await _deploy('SecondaryOracle', [feed, cConfig.secondarySource], deployments, {name: `${cConfig.symbol}_PriceFeed`});
		if(!isTest) console.log(`Deployed SecondaryOracle for ${cConfig.symbol} at ${feed.address}`);
		feed = feed.address;
	}
	if(!collateral){
		// deploy collateral token
		collateral = await _deploy('MockToken', [cConfig.name, cConfig.symbol, cConfig.decimals], deployments, {name: cConfig.symbol});
		if(!isTest) console.log(`Deployed MockToken for ${cConfig.symbol} at ${collateral.address}`);
	} else {
		collateral = await ethers.getContractAt('MockToken', collateral);
	}

	if(!feed){
		console.log("No price feed found for " + cConfig.symbol);
		feed = null;
		// if(!cConfig.price) throw new Error(`Price for ${cConfig.symbol} not found!`);
		// // deploy price feed
		// feed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(cConfig.price, 8), 8], deployments, {name: `${cConfig.symbol}_PriceFeed`});
		// if(!isTest) console.log(`Deployed MockPriceFeed for ${cConfig.symbol} at ${feed.address}`);
	} else {
		feed = await ethers.getContractAt('MockPriceFeed', feed);
		if(!isTest) console.log(`Using PriceFeed for ${cConfig.symbol} ($${parseFloat(ethers.utils.formatUnits(await feed.latestAnswer(), await feed.decimals())).toFixed(4)}) at ${feed.address}`);
	}

	// Enabling collateral
	await pool.updateCollateral(collateral.address, {...cConfig.params, isActive: true, totalDeposits: 0});

	if(!isTest) console.log(`\t Collateral ${cConfig.symbol} added successfully ✅`);

	return {collateral, feed};
}

