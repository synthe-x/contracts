import hre, { ethers, OpenzeppelinDefender } from "hardhat";
import { deploy } from "./deploy";
import { initiate } from "./initiate";
import fs from "fs";

import { DEFAULT_ADMIN_ROLE, L1_ADMIN_ROLE, L2_ADMIN_ROLE, GOVERNANCE_MODULE_ROLE } from "./utils/const";

export default async function main(isTest: boolean = false) {

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
	// override existing deployments
	deployments.contracts = {};
	deployments.sources = {};

	const [deployer] = await ethers.getSigners();

	// increment version
	const version =
		config.version.split(".")[0] +
		"." +
		(parseInt(config.version.split(".")[1]) + 1) +
		".0";

	// update version
	config.version = version;
	config.latest = version;

	// deploy main contracts
	const contracts = await deploy(deployments, config, deployer);
	// initiate the contracts
	const initiates = await initiate(deployments, config, contracts);

	// set admins
	console.log("Setting admins... 💬")

	// renounce sealed syn minter role
	await contracts.sealedSYN.renounceRole(await contracts.sealedSYN.MINTER_ROLE(), deployer.address);

	await contracts.system.grantRole(DEFAULT_ADMIN_ROLE, config.l0Admin);
	await contracts.system.grantRole(L1_ADMIN_ROLE, config.l1Admin);
	await contracts.system.grantRole(L2_ADMIN_ROLE, config.l2Admin);
	await contracts.system.grantRole(GOVERNANCE_MODULE_ROLE, config.governanceModule);

	if(deployer.address !== config.l0Admin) await contracts.system.renounceRole(DEFAULT_ADMIN_ROLE, deployer.address);
	if(deployer.address !== config.l1Admin) await contracts.system.renounceRole(L1_ADMIN_ROLE, deployer.address);
	if(deployer.address !== config.l2Admin) await contracts.system.renounceRole(L2_ADMIN_ROLE, deployer.address);
	if(deployer.address !== config.governanceModule) await contracts.system.renounceRole(GOVERNANCE_MODULE_ROLE, deployer.address);
	console.log("Admins set! 🎉")

	// save deployments
    if(!isTest){
        fs.writeFileSync(
            process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`,
            JSON.stringify(config, null, 2)
        );
        fs.writeFileSync(
            process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`,
            JSON.stringify(deployments, null, 2)
        );
    }

	console.log("Deployment complete! 🎉")
	return { ...contracts, ...initiates };
}