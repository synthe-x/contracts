import hre, { ethers, upgrades } from "hardhat";
import { BigNumber, Contract } from 'ethers';
import { _deploy } from "./utils/helper";
import { _deploy as _deployDefender } from "./utils/defender";
import deployPool from '../tasks/pools/main'
import deployOracle from '../tasks/pools/oracle/main'
import initPool from '../tasks/pools/init/main'
import initCollateral from '../tasks/pools/collateral/main'
import initSynth from '../tasks/pools/synth/main'
import fs from 'fs';
import { ETH_ADDRESS } from './utils/const';


export interface IPoolData {
  pool: Contract;
  oracle: Contract;
  // enabled collaterals
  collateralTokens: Contract[];
  collateralPriceFeeds: Contract[];
  // enabled pool synths
  synths: Contract[];
  synthPriceFeeds: Contract[];
}

export interface IInitiateResult {
  pools: IPoolData[];
  dummyTokens: Contract[];
}

export async function initiate(
  isTest: boolean = false
) {
  const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
  const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));

  let result = {
    pools: [],
    dummyTokens: []
  } as IInitiateResult;

  let weth = config.weth;
  if(!weth){
    console.log("WETH not found, deploying...");
    weth = await _deploy("WETH9", [], deployments, {name: 'WETH9'}, config);

    // save deployments
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
  } else {
    weth = await ethers.getContractAt("WETH9", weth);
  }

  for(let k = 0; k < config.pools.length; k++){
    const poolConfig = config.pools[k];
    let poolResult = {
      pool: {} as Contract,
      oracle: {} as Contract,
      collateralTokens: [],
      collateralPriceFeeds: [],
      synths: [],
      synthPriceFeeds: []
    } as IPoolData;

    poolResult.pool = await deployPool(poolConfig.name, poolConfig.symbol, weth.address, isTest)
    poolResult.oracle = await deployOracle(poolResult.pool.address, isTest);

    await initPool(poolResult.pool.address, poolResult.oracle.address, poolConfig.issuerAlloc, poolConfig.rewardSpeed, isTest);
    
    for(let i = 0; i < poolConfig.collaterals.length; i++){
      let cConfig = poolConfig.collaterals[i];
      if(cConfig.address == ETH_ADDRESS){
        cConfig.address = weth.address;
      }
      const result = await initCollateral(cConfig, poolResult.pool.address, poolResult.oracle.address, isTest)
      poolResult.collateralTokens.push(result.collateral);
      poolResult.collateralPriceFeeds.push(result.feed);
    }

    for(let i = 0; i < poolConfig.synths.length; i++){
      const synthConfig = poolConfig.synths[i];
      const result = await initSynth(synthConfig, poolResult.pool.address, poolResult.oracle.address, isTest);
      poolResult.synths.push(result.synth);
      poolResult.synthPriceFeeds.push(result.feed);
    }

    // unpause to start
    await poolResult.pool.unpause();

    result.pools.push(poolResult);
  }
  
  return result;
}