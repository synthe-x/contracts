import hre, { ethers, OpenzeppelinDefender } from "hardhat";
import { deploy } from "./deploy";
import { initiate } from "./initiate";
import fs from "fs";

import { PRICE_ORACLE, SYNTHEX, VAULT, DEFAULT_ADMIN_ROLE, L1_ADMIN_ROLE, L2_ADMIN_ROLE, GOVERNANCE_MODULE_ROLE } from "./utils/const";

async function main() {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.name}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.name}/config.json`, "utf8"));
	
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
	const contracts = await deploy(deployments, config, deployer.address);
	// initiate the contracts
	await initiate(contracts.synthex, contracts.oracle, deployments, config, contracts.system, contracts.sealedSYN);

	// set admins
	console.log("Setting admins... 💬")

	// renounce sealed syn minter role
	await contracts.sealedSYN.renounceRole(await contracts.sealedSYN.MINTER_ROLE(), deployer.address);

	await contracts.system.grantRole(DEFAULT_ADMIN_ROLE, config.l0Admin);
	await contracts.system.grantRole(L1_ADMIN_ROLE, config.l1Admin);
	await contracts.system.grantRole(L2_ADMIN_ROLE, config.l2Admin);
	await contracts.system.grantRole(GOVERNANCE_MODULE_ROLE, config.governanceModule);

	await contracts.system.renounceRole(DEFAULT_ADMIN_ROLE, deployer.address);
	await contracts.system.renounceRole(L1_ADMIN_ROLE, deployer.address);
	await contracts.system.renounceRole(L2_ADMIN_ROLE, deployer.address);
	await contracts.system.renounceRole(GOVERNANCE_MODULE_ROLE, deployer.address);
	console.log("Admins set! 🎉")

	// save deployments
	fs.writeFileSync(
		process.cwd() + `/deployments/${hre.network.name}/config.json`,
		JSON.stringify(config, null, 2)
	);
	fs.writeFileSync(
		process.cwd() + `/deployments/${hre.network.name}/deployments.json`,
		JSON.stringify(deployments, null, 2)
	);

	console.log("Deployment complete! 🎉")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});