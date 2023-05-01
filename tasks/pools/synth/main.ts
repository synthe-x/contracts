import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { _deploy as _deployEVM } from '../../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../../scripts/utils/defender';
import { Contract } from 'ethers';
import { SynthArgs } from '../../../deployments/types';

export default async function main(synthConfig: SynthArgs, synthex: Contract, pool: Contract, isTest: boolean = false, _deploy = _deployEVM): Promise<{synth: Contract, feed: Contract|null}> {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
	// get pool contract
	const poolName = await pool.name();
	const poolSymbol = await pool.symbol();
	
	let synth: string|Contract = synthConfig.address as string;
	if(!synth){
		const symbol = poolSymbol.toLowerCase() + synthConfig.symbol;
		const name = 'SyntheX ' + synthConfig.name + ' (' + poolName + ')';
		const args = [name, symbol, pool.address, synthex.address];
		// deploy token
		synth = await _deploy('ERC20X', args, deployments, { name: symbol, upgradable: true }, config);
		if(!isTest) console.log(`Token ${name} (${symbol}) deployed at ${synth.address}`);
		if((hre.network.config as any).isLive){
			try{
				await hre.run("verify:verify", {
					address: synth.address,
					constructorArguments: []
				})
				.catch(err => {
					console.log("Could not verify synth", name);
				})
			} catch (err) {
				console.log("Could not verify vault");
			}
		}
	} else {
		synth = await ethers.getContractAt('ERC20X', synth);
	}
	let feed: string|Contract|null = synthConfig.feed as string;

	if(synthConfig.isFeedSecondary){
		// deploy secondary price feed
		feed = await _deploy('SecondaryOracle', [feed, synthConfig.secondarySource], deployments, {name: `${poolSymbol.toLowerCase()}${synthConfig.symbol}_PriceFeed`});
		if(!isTest) console.log(`Secondary price feed deployed at ${feed.address}`);
		feed = feed.address;
	}
	if(!feed){
		console.log('No price feed found for ' + synthConfig.symbol);
		feed = null;
		// if(!synthConfig.price) throw new Error('Price not set for ' + synthConfig.symbol);
		// // deploy price feed
		// feed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(synthConfig.price, 8), 8], deployments, {name: `${poolSymbol.toLowerCase()}${synthConfig.symbol}_PriceFeed`});
		// if(!isTest) console.log(`Price feed deployed at ${feed.address}`);
	} else {
		feed = await ethers.getContractAt('MockPriceFeed', feed);
		console.log(`Using Price Feed for ${synthConfig.symbol} ${feed.address}  ($${parseFloat(ethers.utils.formatUnits(await feed.latestAnswer(), await feed.decimals())).toFixed(4)})`);
	}

	await pool.addSynth(synth.address, {
		isActive: true,
        isDisabled: false,
        mintFee: synthConfig.mintFee,
        burnFee: synthConfig.burnFee
	});
	if(!isTest) console.log(`\t\t ${synthConfig.name} (${synthConfig.symbol}) added  ✨`);

	if(synthConfig.isFeeToken){
		// wait for 2 sec
		await new Promise(resolve => setTimeout(resolve, 60000));
		await pool.setFeeToken(synth.address);
		if(!isTest) console.log(`${synthConfig.name} (${synthConfig.symbol}) set as Fee Token ✅`);
	}

	if(!isTest){
        fs.writeFileSync(
            process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`,
            JSON.stringify(config, null, 2)
        );
        fs.writeFileSync(
            process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`,
            JSON.stringify(deployments, null, 2)
        );
    }

	return {synth, feed};
}