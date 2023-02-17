import hre, { ethers, upgrades } from "hardhat";
import { BigNumber, Contract } from 'ethers';
import { _deploy } from "./utils/helper";
import { _deploy as _deployDefender } from "./utils/defender";
import { IDeploymentResult } from './deploy';

export interface IInitiateResult {
  // enabled collaterals
  collateralTokens: Contract[];
  collateralPriceFeeds: Contract[];
  // enabled debt pools with synths
  pools: Contract[];
  poolSynths: Contract[][];
  poolSynthPriceFeeds: Contract[][];
  dummyTokens: Contract[]
}

export async function initiate(
  deployments: any, 
  config: any, 
  contracts: IDeploymentResult,
  isTest: boolean = false
) {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`

  let result = {
    collateralTokens: [],
    collateralPriceFeeds: [],
    pools: [],
    poolSynths: [],
    poolSynthPriceFeeds: [],
    dummyTokens: []
  } as IInitiateResult;

  /* -------------------------------------------------------------------------- */
  /*                                 Collaterals                                */
  /* -------------------------------------------------------------------------- */
  if(!isTest) console.log("\nDeploying Collaterals... 💬");
  let assets = [];
  let feeds = [];
  let oracles = []
  for(let i = 0; i < config.collaterals.length; i++){
    let collateral: string|Contract = config.collaterals[i].address as string;
    let feed: string|Contract = config.collaterals[i].feed as string;

    // handle compound based collateral (cTokens)
    if(config.collaterals[i].isCToken){
      const cToken = await ethers.getContractAt('CTokenInterface', collateral);
      const comptroller = await cToken.comptroller();
      feed = await _deploy('CompoundOracle', [comptroller, cToken.address, config.collaterals[i].decimals], deployments, {name: `${config.collaterals[i].symbol}_PriceFeed`});
      feed = feed.address;
    }
    // handle aave based collateral (aTokens)
    else if(config.collaterals[i].isAToken){
      const aToken = await ethers.getContractAt('IAToken', collateral);
      const underlying = await aToken.UNDERLYING_ASSET_ADDRESS();
      collateral = (await _deploy('ATokenWrapper', ["Wrapped "+config.collaterals[i].name, "w"+config.collaterals[i].symbol, aToken.address], deployments, {name: config.collaterals[i].symbol})).address;
      feed = await _deploy('AAVEOracle', [collateral, underlying, config.collaterals[i].poolAddressesProvider, config.collaterals[i].decimals], deployments, {name: `${config.collaterals[i].symbol}_PriceFeed`});
      feed = feed.address;
      // aToken wrapper
    }
    // handle secondary oracle feeds
    else if(config.collaterals[i].isFeedSecondary){
      // deploy secondary price feed
      feed = await _deploy('SecondaryOracle', [feed, config.collaterals[i].secondarySource], deployments, {name: `${config.collaterals[i].symbol}_PriceFeed`});
      feed = feed.address;
    }
    if(!collateral){
      // deploy collateral token
      collateral = await _deploy('MockToken', [config.collaterals[i].name, config.collaterals[i].symbol, config.collaterals[i].decimals], deployments, {name: config.collaterals[i].symbol});
    } else {
      collateral = await ethers.getContractAt('MockToken', collateral);
    }

    if(!feed){
      // deploy price feed
      feed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(config.collaterals[i].price, 8), 8], deployments, {name: `${config.collaterals[i].symbol}_PriceFeed`});
    } else {
      feed = await ethers.getContractAt('MockPriceFeed', feed);
    }

    assets.push(collateral.address); 
    feeds.push(feed.address);
    await contracts.synthex.enableCollateral(collateral.address, ethers.utils.parseEther(config.collaterals[i].volatilityRatio).mul(10000));
    await contracts.synthex.setCollateralParams(collateral.address, config.collaterals[i].params);
    if(!isTest) console.log(`\t Collateral ${config.collaterals[i].symbol} ($${parseFloat(ethers.utils.formatUnits(await feed.latestAnswer(), await feed.decimals())).toFixed(4)}) added successfully ✅`);

    result.collateralTokens.push(collateral);
    result.collateralPriceFeeds.push(feed);
  }

  // deploy price oracle
  oracles.push(await _deploy("PriceOracle", [
    contracts.system.address, 
    assets,
    feeds,
    ethers.constants.AddressZero,
    ethers.constants.AddressZero,
    1e8
  ], deployments));
  await contracts.synthex.setPriceOracle(oracles[0].address);
  // _deployDefender("PriceOracle_"+versionSuffix, oracle);


  if(!isTest) console.log("Collaterals added successfully 🎉 \n");

  /* -------------------------------------------------------------------------- */
  /*                                 Debt pools                                 */
  /* -------------------------------------------------------------------------- */
  if(!isTest) console.log("Deploying Debt Pools... 💬");
  for(let i = 0; i < config.tradingPools.length; i++){
    // deploy pools
    const pool = await _deploy('DebtPool', [config.tradingPools[i].name, config.tradingPools[i].symbol, contracts.system.address], deployments, {name: config.tradingPools[i].symbol, upgradable: true});

    // enable trading pool
    await contracts.synthex.enableTradingPool(pool.address, ethers.utils.parseEther(config.tradingPools[i].volatilityRatio).mul(10000))
    // set reward speed
    await contracts.synthex.setPoolSpeed(contracts.sealedSYN.address, pool.address, ethers.utils.parseEther(config.tradingPools[i].rewardSpeed));
    // set fee
    await pool.updateFee(
      ethers.utils.parseEther(config.tradingPools[i].mintFee), 
      ethers.utils.parseEther(config.tradingPools[i].swapFee), 
      ethers.utils.parseEther(config.tradingPools[i].burnFee), 
      ethers.utils.parseEther(config.tradingPools[i].liquidationFee),
      ethers.utils.parseEther(config.tradingPools[i].liquidationPenalty),
      ethers.utils.parseEther(config.tradingPools[i].issuerAlloc)
    );
    
    if(!isTest) console.log(`\t ${config.tradingPools[i].name} (${config.tradingPools[i].symbol}) deployed successfully ✅`);
    result.pools.push(pool);
    result.poolSynths.push([]);
    result.poolSynthPriceFeeds.push([]);

    if(config.tradingPools[i].synths.length == 0){
      if(!isTest) console.log(`\t\t No Synths added to ${config.tradingPools[i].symbol} 🤷‍♂️`);
      continue;
    }
    _deployDefender(config.tradingPools[i].symbol+'_'+versionSuffix, pool);

    let feeToken = '';
    assets = [];
    feeds = [];
    for(let j = 0; j < config.tradingPools[i].synths.length; j++){
      let synth: string|Contract = config.tradingPools[i].synths[j].address as string;
      const symbol = config.tradingPools[i].symbol.toLowerCase() + config.tradingPools[i].synths[j].symbol;
      const name = 'SyntheX ' + config.tradingPools[i].synths[j].name + ' ' + config.tradingPools[i].symbol;
      if(!synth){
        // deploy token
        synth = await _deploy('ERC20X', [name, symbol, pool.address, contracts.system.address], deployments, { name: symbol, upgradable: true });
      } else {
        synth = await ethers.getContractAt('ERC20X', synth);
      }
      let feed: string|Contract = config.tradingPools[i].synths[j].feed as string;

      if(config.tradingPools[i].synths[j].isFeedSecondary){
        // deploy secondary price feed
        feed = await _deploy('SecondaryOracle', [feed, config.tradingPools[i].synths[j].secondarySource], deployments, {name: `${symbol}_PriceFeed`});
        feed = feed.address;
      }
      if(!feed){
        // deploy price feed
        feed = await _deploy('MockPriceFeed', [ethers.utils.parseUnits(config.tradingPools[i].synths[j].price, 8), 8], deployments, {name: `${symbol}_PriceFeed`});
      } else {
        feed = await ethers.getContractAt('MockPriceFeed', feed);
      }
      assets.push(synth.address);
      feeds.push(feed.address);
      await pool.enableSynth(synth.address);
      if(!isTest) console.log(`\t\t ${name} (${symbol}) ($${parseFloat(ethers.utils.formatUnits(await feed.latestAnswer(), await feed.decimals())).toFixed(4)}) added  ✨`);
      result.poolSynths[i].push(synth);
      result.poolSynthPriceFeeds[i].push(feed);

      if(!feeToken){
        feeToken = synth.address;
      }
      if(config.tradingPools[i].synths[j].isFeeToken){
        feeToken = synth.address;
      }
    }

    // deploy price oracle
    oracles.push(await _deploy("PriceOracle", [
      contracts.system.address, 
      assets,
      feeds,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      1e8
    ], deployments));
    await pool.setPriceOracle(oracles[i+1].address);
    // _deployDefender("PriceOracle_"+versionSuffix, oracle);

    await pool.updateFeeToken(feeToken);
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