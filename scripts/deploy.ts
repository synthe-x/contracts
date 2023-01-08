import hre, { ethers } from "hardhat";
import fs from 'fs';
const { upgrades } = require("hardhat");

export async function deploy() {
  // read deployments
  const deployments = JSON.parse(fs.readFileSync( process.cwd() + `/deployments/${hre.network.name}/deployments.json`, 'utf8'));

  // deploy SYN
  const SYN = await ethers.getContractFactory("SYN");
  const syn = await SYN.deploy();
  await syn.deployed();

  // deploy synthex
  const SyntheX = await ethers.getContractFactory("SyntheX");
  const synthex = await upgrades.deployProxy(SyntheX, [syn.address]);
  await synthex.deployed();
  console.log("SyntheX deployed to:", synthex.address);

  await syn.mint(synthex.address, ethers.utils.parseEther("100000000"))
  
  // override existing deployments
  deployments.contracts = {};
  deployments.sources = {};

  // add synthex to deployments
  deployments.contracts["SyntheX"] = {
    address: synthex.address,
    source: "SyntheX",
    constructorArguments: [syn.address]
  };
  deployments.sources["SyntheX"] = synthex.interface.format("json")

  // deploy priceoracle
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

  // save deployments
  fs.writeFileSync(process.cwd() + `/deployments/${hre.network.name}/deployments.json`, JSON.stringify(deployments, null, 2));

  return { synthex, oracle };
}