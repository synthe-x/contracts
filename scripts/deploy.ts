import hre, { ethers } from "hardhat";
import { PRICE_ORACLE, SYNTHEX, VAULT, SEALED_SYN, STAKING } from "./utils/const";
import { _deploy } from './utils/helper';
const { upgrades } = require("hardhat");

export async function deploy(deployments: any, config: any, deployerAddress: string) {
  // deploy storage contract
  const addressManager = await _deploy("AddressStorage", [deployerAddress], deployments)
  
  // vault
  const vault = await _deploy("Vault", [config.admin], deployments);
  await addressManager.setAddress(VAULT, vault.address);

  // deploy SYN
  const SYN = await ethers.getContractFactory("SyntheXToken");
  const syn = await SYN.deploy();
  await syn.deployed();
  
  // deploy synthex
  const SyntheX = await ethers.getContractFactory("SyntheX");
  const synthex = await upgrades.deployProxy(SyntheX, [syn.address, addressManager.address], {
    initializer: 'initialize(address,address)',
    type: 'uups'
  });

  // save synthex to deployments
  deployments.contracts["SyntheX"] = {
    address: synthex.address,
    source: "SyntheX",
    constructorArguments: [] // empty needed for verification
  };
  deployments.sources["SyntheX"] = synthex.interface.format("json")
  await synthex.deployed();
  await synthex.setSafeCRatio(ethers.utils.parseEther(config.safeCRatio));

  await addressManager.setAddress(SYNTHEX, synthex.address);

  console.log(`\nSyntheX ${config.latest} deployed to: ${synthex.address}`);

  // save implementation to deployments
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(synthex.address);
  if(!deployments.contracts['SyntheX'].implementations) deployments.contracts['SyntheX'].implementations = {};
  deployments.contracts['SyntheX'].implementations[config.latest] = {
    address: implementationAddress,
    source: 'SyntheX_'+config.latest,
    constructorArguments: [],
    version: config.latest,
    block: (await ethers.provider.getBlockNumber()).toString()
  };
  deployments.sources['SyntheX_'+config.latest] = synthex.interface.format('json');

  await syn.mint(synthex.address, ethers.utils.parseEther("100000000"))

  //deploy Sealed SYN
  const SealedSYN = await ethers.getContractFactory("SealedSYN");
  const sealedSYN = await SealedSYN.deploy();
  await sealedSYN.deployed();
  console.log(`\SealedSYN ${config.latest} deployed to: ${sealedSYN.address}`);

  await addressManager.setAddress(SEALED_SYN, synthex.address);

  
  // deploy staking rewards
  const StakingRewards = await ethers.getContractFactory("StakingRewards");
  const stakingRewards = await upgrades.deployProxy(StakingRewards, [sealedSYN.address, syn.address], {
    initializer: 'initialize(address,address)',
    type: 'uups'
  });

  // save deployments
  deployments.contracts["StakingRewards"] = {
    address: stakingRewards.address,
    source: "StakingRewards",
    constructorArguments: [sealedSYN.address, syn.address] // empty needed for verification
  };
  deployments.sources["StakingRewards"] = stakingRewards.interface.format("json")
  await stakingRewards.deployed();
  await addressManager.setAddress(STAKING, stakingRewards.address);

  console.log(`\StakingRewards ${config.latest} deployed to: ${stakingRewards.address}`);

  // deploy price oracle
  const Oracle = await ethers.getContractFactory("PriceOracle");
  const oracle = await Oracle.deploy();
  await oracle.deployed();

  deployments.contracts["PriceOracle"] = {
    address: oracle.address,
    source: "PriceOracle",
    constructorArguments: []
  };
  deployments.sources["PriceOracle"] = oracle.interface.format("json")
  await addressManager.setAddress(PRICE_ORACLE, oracle.address);
  console.log("PriceOracle deployed to:", oracle.address);

  // deploy multicall
  const Multicall = await ethers.getContractFactory("Multicall2");
  const multicall = await Multicall.deploy();
  await multicall.deployed();

  deployments.contracts["Multicall2"] = {
    address: multicall.address,
    source: "Multicall2",
    constructorArguments: []
  };

  deployments.sources["Multicall2"] = multicall.interface.format("json")

  console.log("Multicall deployed to:", multicall.address);

  return { synthex, oracle, addressManager };
}