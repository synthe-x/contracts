import hre, { ethers, upgrades } from "hardhat";
import { Contract } from 'ethers';

export async function initiate(synthex: Contract, oracle: Contract, deployments: any, config: any, addressManager: Contract) {
  
  console.log("\nDeploying Collaterals... 💬");

  for(let i in config.collaterals){
    let collateral = config.collaterals[i].address;
    if(!collateral){
      // deploy collateral token
      const token = await _deploy('MockToken', [config.collaterals[i].name, config.collaterals[i].symbol], deployments, {name: config.collaterals[i].symbol});
      collateral = token.address;
    }
    let feed = config.collaterals[i].feed;
    if(!feed){
      // deploy price feed
      const priceFeed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(config.collaterals[i].price, 8), 8], deployments, {name: `${config.collaterals[i].symbol}_PriceFeed`});
      await oracle.setFeed(collateral, priceFeed.address);
      feed = priceFeed.address;
    }
    await synthex.enableCollateral(collateral, ethers.utils.parseEther(config.collaterals[i].volatilityRatio));
    console.log(`\t Collateral ${config.collaterals[i].symbol} deployed successfully ✅`);
  }
  console.log("Collaterals deployed successfully 🎉 \n");

  console.log("Deploying Trading Pools... 💬");
  for(let i in config.tradingPools){
    // deploy pools
    const pool = await _deploy('SyntheXPool', [config.tradingPools[i].name, config.tradingPools[i].symbol, synthex.address, addressManager.address], deployments, {name: config.tradingPools[i].symbol, upgradable: true});
    // enable trading pool
    await synthex.enableTradingPool(pool.address, ethers.utils.parseEther(config.tradingPools[i].volatilityRatio))
    // set reward speed
    await synthex.setPoolSpeed(pool.address, ethers.utils.parseEther(config.tradingPools[i].rewardSpeed));
    // set fee
    await pool.updateFee(ethers.utils.parseEther(config.tradingPools[i].fee));

    console.log(`\t Trading Pool ${config.tradingPools[i].symbol} deployed successfully ✅`);

    for(let j in config.tradingPools[i].synths){
      let synth = config.tradingPools[i].synths[j].address;
      if(!synth){
        // deploy token
        const token = await _deploy('ERC20X', [config.tradingPools[i].synths[j].name, config.tradingPools[i].synths[j].symbol, pool.address], deployments, { name: config.tradingPools[i].synths[j].symbol });
        synth = token.address;
      }
      let feed =  config.tradingPools[i].synths[j].feed;
      if(!feed){
        // deploy price feed
        const priceFeed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(config.tradingPools[i].synths[j].price, 8), 8], deployments, {name: `${config.tradingPools[i].synths[j].symbol}_PriceFeed`});
        await oracle.setFeed(synth, priceFeed.address);
        feed = priceFeed.address;
      }
      await pool.enableSynth(synth);
      console.log(`\t\t Synth ${config.tradingPools[i].synths[j].symbol} added to ${config.tradingPools[i].symbol} ✨`);
    }
  }
  
  console.log("Trading Pools deployed successfully 🎉\n");
}

const _deploy = async (
	contractName: string,
	args: any[],
	deployments: any,
	{upgradable = false, name = contractName} = {},
	config: any = {},
) => {
	const Contract = await ethers.getContractFactory(contractName);
	let contract;
	if (upgradable) {
		contract = await upgrades.deployProxy(Contract, args, { type: 'uups' });
		args = [];
	} else {
		contract = await Contract.deploy(...args);
	}
	await contract.deployed();

	deployments.contracts[name] = {
		address: contract.address,
		abi: contractName,
		constructorArguments: args,
		block: (await ethers.provider.getBlockNumber()).toString(),
	};
	deployments.sources[contractName] = JSON.parse(
		Contract.interface.format("json") as string
	);

	if (upgradable) {
		const implementationAddress = await upgrades.erc1967.getImplementationAddress(contract.address);
		if(!deployments.contracts[name].implementations) deployments.contracts[name].implementations = {};
		deployments.contracts[name].implementations[config.latest] = {
			address: implementationAddress,
			source: name+'_'+config.latest,
			constructorArguments: [],
			version: config.latest,
			block: (await ethers.provider.getBlockNumber()).toString()
		};
		deployments.contracts[name].latest = implementationAddress;
		deployments.sources[name+'_'+config.latest] = contract.interface.format('json');
	}

	return contract;
};