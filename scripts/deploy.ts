import { ethers } from "hardhat";

export async function deploy() {
  // deploy synthex
  const SyntheX = await ethers.getContractFactory("SyntheX");
  const synthex = await SyntheX.deploy();
  await synthex.deployed();

  // create pool
  const SyntheXPool = await ethers.getContractFactory("SyntheXPool");
  const cryptoPool = await SyntheXPool.deploy("Crypto SyntheX", "CRYPTOX", synthex.address);
  await cryptoPool.deployed();

  await synthex.enableTradingPool(cryptoPool.address, ethers.utils.parseEther("0.9"));

  // deploy priceoracle
  const Oracle = await ethers.getContractFactory("PriceOracle");
  const oracle = await Oracle.deploy();
  await oracle.deployed();

  await synthex.setOracle(oracle.address);

  return { synthex, cryptoPool, oracle };
}