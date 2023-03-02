import hre, { ethers, upgrades } from "hardhat";
import { BigNumber, Contract } from 'ethers';
import { _deploy } from "./utils/helper";
import { _deploy as _deployDefender } from "./utils/defender";
import { IDeploymentResult } from './deploy';

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
  deployments: any, 
  config: any, 
  contracts: IDeploymentResult,
  isTest: boolean = false
) {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`

  let result = {
    pools: [],
    dummyTokens: []
  } as IInitiateResult;


  for(let k = 0; k < config.pools.length; k++){
    const poolConfig = config.pools[k];
    if(!isTest) console.log(`Initializing pool ${poolConfig.name}... 🚀`);
    let poolResult = {
      pool: {} as Contract,
      oracle: {} as Contract,
      collateralTokens: [],
      collateralPriceFeeds: [],
      synths: [],
      synthPriceFeeds: []
    } as IPoolData;

    poolResult.pool = await _deploy("Pool", [
      poolConfig.name,
      poolConfig.symbol,
      contracts.synthex.address,
    ], deployments, {upgradable: true, name: 'POOL_'+poolConfig.symbol});

    await poolResult.pool.setIssuerAlloc(poolConfig.issuerAlloc);
    await contracts.synthex.setPoolSpeed(contracts.sealedSYN.address, poolResult.pool.address, poolConfig.rewardSpeed)

    for(let i = 0; i < poolConfig.collaterals.length; i++){
      let cConfig = poolConfig.collaterals[i];
      let collateral: string|Contract = cConfig.address as string;
      let feed: string|Contract = cConfig.feed as string;
  
      // handle compound based collateral (cTokens)
      if(cConfig.isCToken){
        const cToken = await ethers.getContractAt('CTokenInterface', collateral);
        const comptroller = await cToken.comptroller();
        feed = await _deploy('CompoundOracle', [comptroller, cToken.address, cConfig.decimals], deployments, {name: `${cConfig.symbol}_PriceFeed`});
        feed = feed.address;
      }
      // handle aave based collateral (aTokens)
      else if(cConfig.isAToken){
        const aToken = await ethers.getContractAt('IAToken', collateral);
        const underlying = await aToken.UNDERLYING_ASSET_ADDRESS();
        collateral = (await _deploy('ATokenWrapper', ["Wrapped "+cConfig.name, "w"+cConfig.symbol, aToken.address], deployments, {name: cConfig.symbol})).address;
        feed = await _deploy('AAVEOracle', [collateral, underlying, cConfig.poolAddressesProvider, cConfig.decimals], deployments, {name: `${cConfig.symbol}_PriceFeed`});
        feed = feed.address;
        // aToken wrapper
      }
      // handle secondary oracle feeds
      else if(cConfig.isFeedSecondary){
        // deploy secondary price feed
        feed = await _deploy('SecondaryOracle', [feed, cConfig.secondarySource], deployments, {name: `${cConfig.symbol}_PriceFeed`});
        feed = feed.address;
      }
      if(!collateral){
        // deploy collateral token
        collateral = await _deploy('MockToken', [cConfig.name, cConfig.symbol, cConfig.decimals], deployments, {name: cConfig.symbol});
      } else {
        collateral = await ethers.getContractAt('MockToken', collateral);
      }
  
      if(!feed){
        // deploy price feed
        feed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(cConfig.price, 8), 8], deployments, {name: `${cConfig.symbol}_PriceFeed`});
      } else {
        feed = await ethers.getContractAt('MockPriceFeed', feed);
      }

      // Enabling collateral
      await poolResult.pool.updateCollateral(collateral.address, {...cConfig.params, isEnabled: true, totalDeposits: 0});
      if(!isTest) console.log(`\t Collateral ${cConfig.symbol} ($${parseFloat(ethers.utils.formatUnits(await feed.latestAnswer(), await feed.decimals())).toFixed(4)}) added successfully ✅`);
  
      poolResult.collateralTokens.push(collateral);
      poolResult.collateralPriceFeeds.push(feed);
    }

    let feeToken = '';
    for(let i = 0; i < poolConfig.synths.length; i++){
      const synthConfig = poolConfig.synths[i];
      let synth: string|Contract = synthConfig.address as string;
      const symbol = poolConfig.symbol.toLowerCase() + synthConfig.symbol;
      const name = 'SyntheX ' + synthConfig.name + ' (' + poolConfig.name + ')';
      if(!synth){
        // deploy token
        synth = await _deploy('ERC20X', [name, symbol, poolResult.pool.address, contracts.synthex.address], deployments, { name: symbol, upgradable: true });
      } else {
        synth = await ethers.getContractAt('ERC20X', synth);
      }
      let feed: string|Contract = synthConfig.feed as string;

      if(synthConfig.isFeedSecondary){
        // deploy secondary price feed
        feed = await _deploy('SecondaryOracle', [feed, synthConfig.secondarySource], deployments, {name: `${symbol}_PriceFeed`});
        feed = feed.address;
      }
      if(!feed){
        // deploy price feed
        feed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(synthConfig.price, 8), 8], deployments, {name: `${symbol}_PriceFeed`});
      } else {
        feed = await ethers.getContractAt('MockPriceFeed', feed);
      }
      await poolResult.pool.addSynth(synth.address, synthConfig.mintFee, synthConfig.burnFee);
      if(!isTest) console.log(`\t\t ${name} (${symbol}) ($${parseFloat(ethers.utils.formatUnits(await feed.latestAnswer(), await feed.decimals())).toFixed(4)}) added  ✨`);
      poolResult.synths.push(synth);
      poolResult.synthPriceFeeds.push(feed);

      if(!feeToken){
        feeToken = synth.address;
      }
      if(synthConfig.isFeeToken){
        feeToken = synth.address;
      }
    }

    poolResult.oracle = await _deploy("PriceOracle", [
      contracts.synthex.address, 
      poolResult.collateralTokens.map((c) => c.address).concat(poolResult.synths.map((s) => s.address)),
      poolResult.collateralPriceFeeds.map((c) => c.address).concat(poolResult.synthPriceFeeds.map((s) => s.address)),
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      1e8
    ], deployments, {name: "PriceOracle_"+poolConfig.symbol});

    // config and unpause
    await poolResult.pool.setPriceOracle(poolResult.oracle.address);
    await poolResult.pool.setFeeToken(feeToken);
    await poolResult.pool.unpause();

    result.pools.push(poolResult);
  }

  // Dummy tokens
  if(!isTest) console.log("Deploying Dummy Tokens... 💬");
  for(let i = 0; i < config.dummyTokens.length; i++){
    result.dummyTokens.push(await _deploy(
      'MockToken',
      [
        config.dummyTokens[i].name,
        config.dummyTokens[i].symbol,
        18
      ],
      deployments,
      {name: config.dummyTokens[i].symbol}
    ))
  }
  
  if(!isTest) console.log("Trading Pools deployed successfully 🎉\n");
  return result;
}