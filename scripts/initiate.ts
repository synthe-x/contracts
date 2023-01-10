import hre, { ethers, upgrades } from "hardhat";
import { Contract } from 'ethers';

export async function initiate(synthex: Contract, oracle: Contract, deployments: any, config: any) {
  const MockToken = await ethers.getContractFactory("MockToken");
  const ERC20X = await ethers.getContractFactory("ERC20X");
  const PriceFeed = await ethers.getContractFactory("MockPriceFeed");

  console.log("\nDeploying Collaterals... 💬");
  for(let i in config.collaterals){
    let collateral = config.collaterals[i].address;
    if(!collateral){
      // deploy collateral token
      const token = await MockToken.deploy(config.collaterals[i].name, config.collaterals[i].symbol);
      collateral = token.address;
      deployments.contracts[config.collaterals[i].symbol] = {
        address: collateral,
        source: "MockToken",
        constructorArguments: [config.collaterals[i].name, config.collaterals[i].symbol]
      };
      deployments.sources["MockToken"] = MockToken.interface.format("json")
    }
    let feed = config.collaterals[i].feed;
    if(!feed){
      // deploy price feed
      const priceFeed = await PriceFeed.deploy(ethers.utils.parseUnits(config.collaterals[i].price, 8), 8);
      await oracle.setFeed(collateral, priceFeed.address, 10);
      feed = priceFeed.address;
    }
    await synthex.enableCollateral(collateral, ethers.utils.parseEther(config.collaterals[i].volatilityRatio));
    console.log(`\t Collateral ${config.collaterals[i].symbol} deployed`);
  }

  console.log("Collaterals deployed successfully ✅ \n");
  const SyntheXPool = await ethers.getContractFactory("SyntheXPool");
  console.log("Deploying Trading Pools... 💬");

  for(let i in config.tradingPools){
    // deploy pools
    const pool = await upgrades.deployProxy(SyntheXPool, [config.tradingPools[i].name, config.tradingPools[i].symbol, synthex.address]);
    // enable trading pool
    await synthex.enableTradingPool(pool.address, ethers.utils.parseEther(config.tradingPools[i].volatilityRatio))
    // set reward speed
    await synthex.setPoolSpeed(pool.address, ethers.utils.parseEther(config.tradingPools[i].rewardSpeed));
    // set fee
    await pool.updateFee(ethers.utils.parseEther(config.tradingPools[i].fee));
    // add to deployments
    deployments.contracts[config.tradingPools[i].symbol] = {
      address: pool.address,
      source: "SyntheXPool",
      constructorArguments: [config.tradingPools[i].name, config.tradingPools[i].symbol, synthex.address]
    };
    deployments.sources["SyntheXPool"] = SyntheXPool.interface.format("json")
    console.log(`\t Trading Pool ${config.tradingPools[i].symbol} deployed`)

    for(let j in config.tradingPools[i].synths){
      let synth = config.tradingPools[i].synths[j].address;
      if(!synth){
        // deploy token
        const token = await ERC20X.deploy(config.tradingPools[i].synths[j].name, config.tradingPools[i].synths[j].symbol, pool.address);
        synth = token.address;
        deployments.contracts[config.tradingPools[i].synths[j].symbol] = {
          address: synth,
          source: "ERC20X",
          constructorArguments: [config.tradingPools[i].synths[j].name, config.tradingPools[i].synths[j].symbol, pool.address]
        };
        deployments.sources["ERC20X"] = ERC20X.interface.format("json")
      }
      let feed =  config.tradingPools[i].synths[j].feed;
      if(!feed){
        // deploy price feed
        const priceFeed = await PriceFeed.deploy(ethers.utils.parseUnits(config.tradingPools[i].synths[j].price, 8), 8);
        await oracle.setFeed(synth, priceFeed.address, 10);
        feed = priceFeed.address;
      }
      await pool.enableSynth(synth);
      console.log(`\t\t Synth ${config.tradingPools[i].synths[j].symbol} added`);
    }
  }
  console.log("Trading Pools deployed successfully ✅\n");
}