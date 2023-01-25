import hre, { ethers, OpenzeppelinDefender } from "hardhat";
import { deploy } from "../deploy";
import initiate from "./initiate";
import fs from "fs";

import { PRICE_ORACLE, SYNTHEX, VAULT, DEFAULT_ADMIN_ROLE, L1_ADMIN_ROLE, L2_ADMIN_ROLE, GOVERNANCE_MODULE_ROLE } from "../utils/const";

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export default async function main(deployer: SignerWithAddress, l0Admin = deployer, l1Admin = deployer, l2Admin = deployer, governanceModule = deployer) {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/test/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/test/config.json`, "utf8"));
	
	// override existing deployments
	deployments.contracts = {};
	deployments.sources = {};

	// deploy main contracts
	const contracts = await deploy(deployments, config, deployer.address);
	// initiate the contracts
	const otherContracts =  await initiate(contracts.synthex, contracts.oracle, deployments, config, contracts.system, contracts.sealedSYN);

	// set admins
	await contracts.sealedSYN.renounceRole(await contracts.sealedSYN.MINTER_ROLE(), deployer.address);

	await contracts.system.grantRole(DEFAULT_ADMIN_ROLE, l0Admin.address);
	await contracts.system.renounceRole(L1_ADMIN_ROLE, deployer.address);
	await contracts.system.renounceRole(L2_ADMIN_ROLE, deployer.address);
	await contracts.system.renounceRole(GOVERNANCE_MODULE_ROLE, deployer.address);
	await contracts.system.grantRole(L1_ADMIN_ROLE, l1Admin.address);
	await contracts.system.grantRole(L2_ADMIN_ROLE, l2Admin.address);
	await contracts.system.grantRole(GOVERNANCE_MODULE_ROLE, governanceModule.address);
	await contracts.system.renounceRole(DEFAULT_ADMIN_ROLE, deployer.address);


    return {...contracts, ...otherContracts};
}