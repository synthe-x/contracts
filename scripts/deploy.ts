import hre, { ethers } from "hardhat";
import { PRICE_ORACLE, SYNTHEX, VAULT } from "./utils/const";
import { _deploy } from './utils/helper';
import { _deploy as _deployDefender, _propose as _proposeDefender } from './utils/defender';

import { BigNumber } from 'ethers';
const { upgrades } = require("hardhat");

export async function deploy(deployments: any, config: any, deployerAddress: string) {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`

  // deploy storage contract
  const system = await _deploy("System", [deployerAddress, deployerAddress, deployerAddress, deployerAddress], deployments)
  
  // vault
  const vault = await _deploy("Vault", [system.address], deployments);
  await system.setAddress(VAULT, vault.address);

  // deploy SYN
  const syn = await _deploy("SyntheXToken", [system.address], deployments);
  // _deployDefender("SyntheXToken_"+versionSuffix, syn);

  // deploy Sealed SYN
  const sealedSYN = await _deploy("SealedSYN", [system.address], deployments);
  // _deployDefender("SealedSYN_"+versionSuffix, sealedSYN);
  
  // deploy synthex
  const synthex = await _deploy("SyntheX", [sealedSYN.address, system.address, ethers.utils.parseEther(config.safeCRatio)], deployments, {upgradable: true});
  _deployDefender("SyntheX_"+versionSuffix, synthex);
  await system.setAddress(SYNTHEX, synthex.address);
  await sealedSYN.grantMinterRole(synthex.address);

  // deploy staking rewards : get xSYN on staking xSYN
  const stakingRewards = await _deploy("StakingRewards", [sealedSYN.address, sealedSYN.address, system.address], deployments)
  // _deployDefender("StakingRewards_"+versionSuffix, stakingRewards);
  await sealedSYN.grantMinterRole(stakingRewards.address);

  // deploy price oracle
  const oracle = await _deploy("PriceOracle", [system.address], deployments);
  await system.setAddress(PRICE_ORACLE, oracle.address);
  // _deployDefender("PriceOracle_"+versionSuffix, oracle);

  // deploy unlocker
  const unlocker = await _deploy(
    "TokenUnlocker", 
    [system.address, sealedSYN.address, syn.address, config.unlocker.lockupPeriod, config.unlocker.unlockPeriod, ethers.utils.parseEther(config.unlocker.percReleaseAtUnlock)], 
    deployments
  );

  // deploy multicall
  await _deploy("Multicall2", [], deployments);

  return { synthex, oracle, system, syn, sealedSYN, stakingRewards, vault, unlocker };
}