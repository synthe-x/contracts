import hre, { ethers, OpenzeppelinDefender } from "hardhat";
import fs from "fs";

export default async function main(isTest: boolean = false) {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
	// override existing deployments
	deployments.contracts = {};
	deployments.sources = {};

	// increment version
	const version =
		config.version.split(".")[0] +
		"." +
		(parseInt(config.version.split(".")[1]) + 1) +
		".0";

	// update version
	config.version = version;
	config.latest = version;

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

	if(!isTest) console.log(`Started new deployment ${config.version} 🚀`);
}