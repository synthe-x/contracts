import hre, { ethers } from "hardhat";
import { PRICE_ORACLE, SYNTHEX, VAULT, MINTER_ROLE, AUTHORIZED_SENDER } from './utils/const';
import { _deploy } from './utils/helper';
import { _deploy as _deployDefender, _propose as _proposeDefender } from './utils/defender';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export async function deploy(deployments: any, config: any, deployer: SignerWithAddress, isTest: boolean = false): Promise<IDeploymentResult> {
  const versionSuffix = `${config.version.split(".")[0]}.${config.version.split(".")[1]}.x`
  if(!isTest) console.log("Deploying ", versionSuffix, "🚀");

  let weth;
  if(config.weth){
    // attach to existing weth
    weth = await ethers.getContractAt("WETH9", config.weth);
  } else {
    if(!isTest) console.warn("WETH not found, deploying new WETH9 contract...")
    weth = await _deploy("WETH9", [], deployments);
  }

  // deploy synthex
  const synthex = await _deploy("SyntheX", [deployer.address, deployer.address, deployer.address], deployments, {upgradable: true});
  
  // vault
  const vault = await _deploy("Vault", [synthex.address], deployments);
  await synthex.setAddress(VAULT, vault.address);

  // deploy SYX
  const SYX = await _deploy("SyntheXToken", [synthex.address], deployments);

  // deploy esSYX
  const esSYX = await _deploy("EscrowedSYX", [
    synthex.address,
    SYX.address,
    weth.address,
    config.esSYX.initialRewardsDuration,
    config.esSYX.lockPeriod,
    config.esSYX.unlockPeriod,
    config.esSYX.percReleaseAtUnlock
  ], deployments);
  
  // mint initial reward tokens to synthex
  await esSYX.grantRole(AUTHORIZED_SENDER, synthex.address);
  await SYX.mint(deployer.address, ethers.utils.parseEther(config.rewardAlloc));
  await SYX.increaseAllowance(esSYX.address, ethers.utils.parseEther(config.rewardAlloc));
  await esSYX.lock(ethers.utils.parseEther(config.rewardAlloc), synthex.address);

  /* -------------------------------------------------------------------------- */
  /*                                   Others                                   */
  /* -------------------------------------------------------------------------- */
  // deploy multicall
  await _deploy("Multicall2", [], deployments);

  return { synthex, WETH: weth, SYX, esSYX, vault };
}

export interface IDeploymentResult {
  synthex: Contract;
  WETH: Contract;
  SYX: Contract;
  esSYX: Contract;
  vault: Contract;
}