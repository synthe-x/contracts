import hre, { ethers, upgrades } from "hardhat";
import { BigNumber, Contract } from 'ethers';
import { _deploy } from "./utils/helper";
import { _deploy as _deployDefender } from "./utils/defender";
import deployLibraries from '../tasks/pools/main'
import deployPool from '../tasks/pools/new/main'

import deployOracle from '../tasks/pools/oracle/main'
import initPool from '../tasks/pools/init/main'

import initCollateral from '../tasks/pools/collateral/main'
import initSynth from '../tasks/pools/synth/main'
import fs from 'fs';
import { ETH_ADDRESS } from './utils/const';


export interface IPoolData {
  pool: Contract;
  oracle: Contract;
  fallbackOracle: Contract;
  // enabled collaterals
  collateralTokens: Contract[];
  collateralPriceFeeds: Contract|null[];
  // enabled pool synths
  synths: Contract[];
  synthPriceFeeds: Contract|null[];
}

export interface IInitiateResult {
  pools: IPoolData[];
  dummyTokens: Contract[];
  libraries: {
    poolLogic: Contract;
    collateralLogic: Contract;
    synthLogic: Contract;
  }
}

export async function initiate(
  isTest: boolean = false
) {
  const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
  const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));

  let result = {
    pools: [],
    dummyTokens: [],
    libraries: {
      poolLogic: {} as Contract,
      collateralLogic: {} as Contract,
      synthLogic: {} as Contract,
    }
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

  const synthex = await ethers.getContractAt("SyntheX", deployments.contracts["SyntheX"].address);
  const esSyx = await ethers.getContractAt("EscrowedSYX", deployments.contracts["EscrowedSYX"].address);

  result.libraries = await deployLibraries(isTest);

  for(let k = 0; k < config.pools.length; k++){
    const poolConfig = config.pools[k];
    let poolResult = {
      pool: {} as Contract,
      oracle: {} as Contract,
      fallbackOracle: {} as Contract,
      collateralTokens: [],
      collateralPriceFeeds: [],
      synths: [],
      synthPriceFeeds: []
    } as IPoolData;

    poolResult.pool = await deployPool(poolConfig.name, poolConfig.symbol, weth.address, result.libraries.poolLogic.address, result.libraries.collateralLogic.address, result.libraries.synthLogic.address, isTest)

    let oracleAssets = [];
    let oracleFeeds = [];
    let pythSupportedAssets = [];
    let pythFeeds = [];
    let baseCurrency: null|string = null;
    let baseCurrencyPrice: null|string = null;
    for(let i = 0; i < poolConfig.collaterals.length; i++){
      let cConfig = poolConfig.collaterals[i];
      if(cConfig.address == ETH_ADDRESS){
        cConfig.address = weth.address;
      }
      const result = await initCollateral(cConfig, poolResult.pool, isTest)
      poolResult.collateralTokens.push(result.collateral);
      poolResult.collateralPriceFeeds.push(result.feed);
      if(result.feed){
        oracleAssets.push(result.collateral.address);
        oracleFeeds.push(result.feed.address);
      }
      // pyth
      if(cConfig.pyth){
        pythSupportedAssets.push(result.collateral.address);
        pythFeeds.push(cConfig.pyth);
      }
    }

    for(let i = 0; i < poolConfig.synths.length; i++){
      const synthConfig = poolConfig.synths[i];
      const result = await initSynth(synthConfig, synthex, poolResult.pool, isTest);
      poolResult.synths.push(result.synth);
      poolResult.synthPriceFeeds.push(result.feed);
      if(result.feed){
        oracleAssets.push(result.synth.address);
        oracleFeeds.push(result.feed.address);
      }
      if(synthConfig.isBaseCurrency){
        baseCurrency = result.synth.address;
        baseCurrencyPrice = ethers.utils.parseUnits(synthConfig.price, 8).toString();
      }
      // pyth
      if(synthConfig.pyth){
        pythSupportedAssets.push(result.synth.address);
        pythFeeds.push(synthConfig.pyth);
      }
    }

    if(!baseCurrency || !baseCurrencyPrice){
      throw new Error("Base currency not found");
    }

    if(poolConfig.pyth){
      if(oracleFeeds.length > 0){
        poolResult.fallbackOracle = await deployOracle(poolResult.pool, poolConfig.pyth, oracleAssets, oracleFeeds, ethers.constants.AddressZero, baseCurrency, baseCurrencyPrice, "PriceOracle", isTest);
      }
      poolResult.oracle = await deployOracle(poolResult.pool, poolConfig.pyth, pythSupportedAssets, pythFeeds, poolResult.fallbackOracle.address ?? ethers.constants.AddressZero, baseCurrency, baseCurrencyPrice, "PythOracle", isTest);
      if(!poolResult.fallbackOracle) {
        poolResult.fallbackOracle = poolResult.oracle;
      }
    } else {
      poolResult.oracle = await deployOracle(poolResult.pool, ethers.constants.AddressZero, oracleAssets, oracleFeeds, ethers.constants.AddressZero, baseCurrency, baseCurrencyPrice, "PriceOracle", isTest);
      poolResult.fallbackOracle = poolResult.oracle;
    }

    await initPool(poolResult.pool, synthex, esSyx.address, poolResult.oracle.address, poolConfig.issuerAlloc, poolConfig.rewardSpeed, isTest);

    // unpause to start
    await poolResult.pool.unpause();

    result.pools.push(poolResult);
  }
  
  return result;
}