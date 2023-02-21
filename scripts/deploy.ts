import hre, { ethers } from "hardhat";
import { PRICE_ORACLE, SYNTHEX, VAULT, MINTER_ROLE, AUTHORIZED_SENDER } from './utils/const';
import { _deploy } from './utils/helper';
import { _deploy as _deployDefender, _propose as _proposeDefender } from './utils/defender';
import { Contract } from 'ethers';
import { SyntheX } from '../typechain-types/contracts/SyntheX';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export async function deploy(deployments: any, config: any, deployer: SignerWithAddress, isTest: boolean = false): Promise<IDeploymentResult> {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`
  if(!isTest) console.log("Deploying ", versionSuffix, "🚀");

  // deploy storage contract
  const system = await _deploy("System", [deployer.address, deployer.address, deployer.address, deployer.address], deployments)
  
  // deploy limit spot contract
  const spot = await _deploy("Spot",[], deployments, {upgradable: true});
  // vault
  const vault = await _deploy("Vault", [system.address], deployments);
  await system.setAddress(VAULT, vault.address);

  // deploy SYN
  const syn = await _deploy("SyntheXToken", [system.address], deployments);
  _deployDefender("SyntheXToken_"+versionSuffix, syn);

  // deploy Sealed SYN
  const sealedSYN = await _deploy("EscrowedSYN", [system.address], deployments);
  // _deployDefender("SealedSYN_"+versionSuffix, sealedSYN);
  
  // deploy synthex
  const synthex = await _deploy("SyntheX", [system.address], deployments, {upgradable: true});
  _deployDefender("SyntheX_"+versionSuffix, synthex);
  await system.setAddress(SYNTHEX, synthex.address);
  await sealedSYN.grantRole(MINTER_ROLE, synthex.address);

  await synthex.setSafeCRatio(ethers.utils.parseEther(config.safeCRatio).mul(10000));

  // deploy staking rewards : get xSYN on staking xSYN
  const stakingRewards = await _deploy("StakingRewards", [sealedSYN.address, sealedSYN.address, system.address, config.stakingRewards.days * 24 * 60 * 60], deployments)
  // _deployDefender("StakingRewards_"+versionSuffix, stakingRewards);
  await sealedSYN.grantRole(MINTER_ROLE, stakingRewards.address);
  if(Number(config.stakingRewards.reward) > 0) await stakingRewards.notifyReward(ethers.utils.parseEther(config.stakingRewards.reward));

  // deploy unlocker
  const unlocker = await _deploy(
    "TokenRedeemer", 
    [system.address, sealedSYN.address, syn.address, config.unlocker.lockupPeriod, config.unlocker.unlockPeriod, ethers.utils.parseEther(config.unlocker.percReleaseAtUnlock)], 
    deployments
  );
  // mint tokens to unlocker
  await sealedSYN.grantRole(MINTER_ROLE, deployer.address);
  await sealedSYN.mint(unlocker.address, ethers.utils.parseEther(config.unlocker.quota));

  // deploy multicall
  await _deploy("Multicall2", [], deployments);
  await _deploy("WETH9", [], deployments);

  return { synthex, spot,system, syn, sealedSYN, stakingRewards, vault, unlocker };
}

export interface IDeploymentResult {
  synthex: Contract;
  system: Contract;
  syn: Contract;
  sealedSYN: Contract;
  stakingRewards: Contract;
  vault: Contract;
  unlocker: Contract;
  spot: Contract;
}