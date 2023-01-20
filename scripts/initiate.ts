import hre, { ethers, upgrades } from "hardhat";
import { Contract } from 'ethers';
import { _deploy } from "./utils/helper";
import { _deploy as _deployDefender } from "./utils/defender";


export async function initiate(synthex: Contract, oracle: Contract, deployments: any, config: any, system: Contract, rewardToken: Contract) {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`

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
      feed = priceFeed.address;
    }
    await oracle.setFeed(collateral, feed);
    await synthex.enableCollateral(collateral, ethers.utils.parseEther(config.collaterals[i].volatilityRatio));
    await synthex.setCollateralCap(collateral, ethers.utils.parseEther(config.collaterals[i].cap));
    console.log(`\t Collateral ${config.collaterals[i].symbol} deployed successfully ✅`);
  }
  console.log("Collaterals deployed successfully 🎉 \n");

  console.log("Deploying Debt Pools... 💬");
  for(let i in config.tradingPools){
    // deploy pools
    const pool = await _deploy('DebtPool', [config.tradingPools[i].name, config.tradingPools[i].symbol, system.address], deployments, {name: config.tradingPools[i].symbol, upgradable: true});

    // enable trading pool
    await synthex.enableTradingPool(pool.address, ethers.utils.parseEther(config.tradingPools[i].volatilityRatio))
    // set reward speed
    await synthex.setPoolSpeed(rewardToken.address, pool.address, ethers.utils.parseEther(config.tradingPools[i].rewardSpeed));
    // set fee
    await pool.updateFee(ethers.utils.parseEther(config.tradingPools[i].fee), ethers.utils.parseEther(config.tradingPools[i].issuerAlloc));
    
    console.log(`\t Trading Pool ${config.tradingPools[i].symbol} deployed successfully ✅`);

    if(config.tradingPools[i].synths.length == 0){
      console.log(`\t\t No Synths added to ${config.tradingPools[i].symbol} 🤷‍♂️`);
      continue;
    }
    _deployDefender(config.tradingPools[i].symbol+'_'+versionSuffix, pool);

    let feeToken = '';
    for(let j in config.tradingPools[i].synths){
      let synth = config.tradingPools[i].synths[j].address;
      
      if(!synth){
        // deploy token
        const token = await _deploy('ERC20X', [config.tradingPools[i].synths[j].name, config.tradingPools[i].synths[j].symbol, pool.address, system.address], deployments, { name: config.tradingPools[i].synths[j].symbol });
        synth = token.address;
      }
      let feed =  config.tradingPools[i].synths[j].feed;
      if(!feed){
        // deploy price feed
        const priceFeed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(config.tradingPools[i].synths[j].price, 8), 8], deployments, {name: `${config.tradingPools[i].synths[j].symbol}_PriceFeed`});
        feed = priceFeed.address;
      }
      await oracle.setFeed(synth, feed);
      await pool.enableSynth(synth);
      console.log(`\t\t Synth ${config.tradingPools[i].synths[j].symbol} added to ${config.tradingPools[i].symbol} ✨`);

      if(!feeToken){
        feeToken = synth;
      }
      if(config.tradingPools[i].synths[j].isFeeToken){
        feeToken = synth;
      }
    }

    await pool.updateFeeToken(feeToken);
  }
  
  console.log("Trading Pools deployed successfully 🎉\n");
}