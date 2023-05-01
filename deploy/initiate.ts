import hre, { ethers, upgrades } from "hardhat";
import { BigNumber, Contract } from 'ethers';
import { _deploy } from './utils/helper';
import { _deploy as _deployDefender } from "./utils/defender";
import deployPool from '../tasks/pools/new/main'
import deployOracle from '../tasks/pools/oracle/main'
import initPool from '../tasks/pools/init/main'
import initCollateral from '../tasks/pools/collateral/main'
import initSynth from '../tasks/pools/synth/main'
import fs from 'fs';
import { ETH_ADDRESS } from './utils/const';
import { Deployer } from '@matterlabs/hardhat-zksync-deploy';
import { ContractFactory } from 'zksync-web3';

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
  weth: Contract,
  isTest: boolean = false,
  deployer: Deployer
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

  const esSYXAddress = deployments.contracts["EscrowedSYX"].address;
  if(!esSYXAddress) throw new Error("EscrowedSYX not found");

  const synthexAddress = deployments.contracts["SyntheX"].address;
  if(!synthexAddress) throw new Error("SyntheX not found");
  const synthexArtifacts = await deployer.loadArtifact("SyntheX");
  const synthexFactory = new ContractFactory(synthexArtifacts.abi, synthexArtifacts.bytecode, deployer.zkWallet);
  const synthex = synthexFactory.attach(synthexAddress);

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

    poolResult.pool = await deployPool(poolConfig.name, poolConfig.symbol, weth.address, '', '', '', isTest, _deploy(deployer))
    
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
      const result = await initCollateral(cConfig, poolResult.pool, isTest, _deploy(deployer))
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
      const result = await initSynth(synthConfig, synthex, poolResult.pool, isTest, _deploy(deployer));
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
        poolResult.fallbackOracle = await deployOracle(poolResult.pool, poolConfig.pyth, oracleAssets, oracleFeeds, ethers.constants.AddressZero, baseCurrency, baseCurrencyPrice, "PriceOracle", isTest, _deploy(deployer));
      }
      poolResult.oracle = await deployOracle(poolResult.pool, poolConfig.pyth, pythSupportedAssets, pythFeeds, poolResult.fallbackOracle.address ?? ethers.constants.AddressZero, baseCurrency, baseCurrencyPrice, "PythOracle", isTest, _deploy(deployer));
      if(!poolResult.fallbackOracle) {
        poolResult.fallbackOracle = poolResult.oracle;
      }
    } else {
      poolResult.oracle = await deployOracle(poolResult.pool, ethers.constants.AddressZero, oracleAssets, oracleFeeds, ethers.constants.AddressZero, baseCurrency, baseCurrencyPrice, "PriceOracle", isTest, _deploy(deployer));
      poolResult.fallbackOracle = poolResult.oracle;
    }

    await initPool(poolResult.pool, synthex, esSYXAddress, poolResult.oracle.address, poolConfig.issuerAlloc, poolConfig.rewardSpeed, isTest);

    // unpause to start
    await poolResult.pool.unpause();

    result.pools.push(poolResult);
  }
  
  return result;
}