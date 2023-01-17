import hre, { ethers } from "hardhat";
import { PRICE_ORACLE, SYNTHEX, VAULT } from "./utils/const";
import { _deploy } from './utils/helper';
import { _deploy as _deployDefender, _propose as _proposeDefender } from './utils/defender';

import { BigNumber } from 'ethers';
const { upgrades } = require("hardhat");

export async function deploy(deployments: any, config: any, deployerAddress: string) {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`

  // deploy storage contract
  const addressStorage = await _deploy("AddressStorage", [deployerAddress, deployerAddress, deployerAddress, deployerAddress], deployments)
  
  // vault
  const vault = await _deploy("Vault", [addressStorage.address], deployments);
  await addressStorage.setAddress(VAULT, vault.address);

  // deploy SYN
  const syn = await _deploy("SyntheXToken", [addressStorage.address], deployments);
  _deployDefender("SyntheXToken_"+versionSuffix, syn);

  // deploy Sealed SYN
  const sealedSYN = await _deploy("SealedSYN", [config.l0Admin], deployments);
  _deployDefender("SealedSYN_"+versionSuffix, sealedSYN);
  
  // deploy synthex
  const synthex = await _deploy("SyntheX", [sealedSYN.address, addressStorage.address, ethers.utils.parseEther(config.safeCRatio)], deployments, {upgradable: true});
  _deployDefender("SyntheX_"+versionSuffix, synthex);
  await addressStorage.setAddress(SYNTHEX, synthex.address);

  // deploy staking rewards : get xSYN on staking xSYN
  const stakingRewards = await _deploy("StakingRewards", [sealedSYN.address, sealedSYN.address, addressStorage.address], deployments)
  _deployDefender("StakingRewards_"+versionSuffix, stakingRewards);

  // deploy price oracle
  const oracle = await _deploy("PriceOracle", [addressStorage.address], deployments);
  await addressStorage.setAddress(PRICE_ORACLE, oracle.address);
  _deployDefender("PriceOracle_"+versionSuffix, oracle);

  // deploy multicall
  await _deploy("Multicall2", [], deployments);

  return { synthex, oracle, addressStorage, syn, sealedSYN, stakingRewards, vault };
}