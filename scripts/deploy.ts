import hre, { ethers } from "hardhat";
const { upgrades } = require("hardhat");



export async function deploy(deployments: any, config: any, deployerAddress: string) {

  // deploy SYN
  const SYN = await ethers.getContractFactory("SyntheXToken");
  const syn = await SYN.deploy();
  await syn.deployed();

  // deploy synthex
  const SyntheX = await ethers.getContractFactory("SyntheX");
  const synthex = await upgrades.deployProxy(SyntheX, [syn.address, deployerAddress, deployerAddress, deployerAddress]);
  
  // save synthex to deployments
  deployments.contracts["SyntheX"] = {
    address: synthex.address,
    source: "SyntheX",
    constructorArguments: [syn.address]
  };
  deployments.sources["SyntheX"] = synthex.interface.format("json")
  await synthex.deployed();
	await upgrades.admin.transferProxyAdminOwnership(config.admin);

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

  return { synthex, oracle };
}