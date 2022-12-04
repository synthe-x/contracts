import { ethers } from "hardhat";
import { Contract } from 'ethers';

export async function initiate(synthex: Contract, pool: Contract, oracle: Contract) {
  const ERC20X = await ethers.getContractFactory("ERC20X");
  const PriceFeed = await ethers.getContractFactory("PriceFeed");
  const Collateral = await ethers.getContractFactory("MockToken");
  
  // collateral eth
  const eth = await Collateral.deploy("Ethereum", "ETH");
  const ethPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1000", 8));
  await ethPriceFeed.deployed();
  await oracle.setFeed(eth.address, ethPriceFeed.address, 10);

  await synthex.enableCollateral(eth.address, ethers.utils.parseEther("0.9"));
  
  // susd
  const susd = await ERC20X.deploy("Synth USD", "sUSD", pool.address);
  await susd.deployed();
  const susdPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1", 8));
  await susdPriceFeed.deployed();
  await oracle.setFeed(susd.address, susdPriceFeed.address, 10);
  await pool.enableSynth(susd.address);

  // sbtc
  const sbtc = await ERC20X.deploy("Synth BTC", "sBTC", pool.address);
  await sbtc.deployed();
  const sbtcPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("10000", 8));
  await sbtcPriceFeed.deployed();
  await oracle.setFeed(sbtc.address, sbtcPriceFeed.address, 10);
  await pool.enableSynth(sbtc.address);

  // seth
  const seth = await ERC20X.deploy("Synth ETH", "sETH", pool.address);
  await seth.deployed();
  const sethPriceFeed = await PriceFeed.deploy(ethers.utils.parseUnits("1000", 8));
  await sethPriceFeed.deployed();
  await oracle.setFeed(seth.address, sethPriceFeed.address, 10);
  await pool.enableSynth(seth.address);

  return { susd, sbtc, seth, eth };
}