import { ethers } from "hardhat";
import { deploy } from "./deploy";
import { initiate } from "./initiate";

async function main() {
  const contracts = await deploy()
  initiate(contracts.synthex, contracts.cryptoPool, contracts.oracle)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});