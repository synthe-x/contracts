import hre, { ethers } from "hardhat";
import fs from 'fs';

export async function deploy() {
  // read deployments
  const deployments = JSON.parse(fs.readFileSync( process.cwd() + `/deployments/${hre.network.name}/deployments.json`, 'utf8'));

  // deploy synthex
  const SyntheX = await ethers.getContractFactory("SyntheX");
  const synthex = await SyntheX.deploy();
  await synthex.deployed();
  
  deployments.contracts = {}
  deployments.sources = {}
  deployments.contracts["SyntheX"] = {
    address: synthex.address,
    source: "SyntheX",
    constructorArguments: []
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

  await synthex.setOracle(oracle.address);

  // save deployments
  fs.writeFileSync(process.cwd() + `/deployments/${hre.network.name}/deployments.json`, JSON.stringify(deployments, null, 2));

  return { synthex, oracle };
}