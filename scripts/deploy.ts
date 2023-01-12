import hre, { ethers } from "hardhat";
import { _deploy } from './utils/helper';
const { upgrades } = require("hardhat");

export async function deploy(deployments: any, config: any, deployerAddress: string) {
  // deploy storage contract
  const addressManager = await _deploy("AddressManager", [], deployments)

  //Vault
  const vault = await _deploy("Vault", [config.admin], deployments);
  
  await addressManager.setAddress(ethers.utils.id("VAULT"), vault.address);

  // deploy SYN
  const SYN = await ethers.getContractFactory("SyntheXToken");
  const syn = await SYN.deploy();
  await syn.deployed();
  await addressManager.setAddress(ethers.utils.id("SYN"), syn.address);

  // deploy synthex
  const SyntheX = await ethers.getContractFactory("SyntheX");
  const synthex = await upgrades.deployProxy(SyntheX, [syn.address, config.admin, config.pauser, config.poolManager, addressManager.address], {
    initializer: 'initialize(address,address,address,address,address)',
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

  await addressManager.setAddress(ethers.utils.id("SYNTHEX"), synthex.address);

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
  await addressManager.setAddress(ethers.utils.id("PRICE_ORACLE"), oracle.address);

  console.log("PriceOracle deployed to:", oracle.address);
  await synthex.setOracle(oracle.address);

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