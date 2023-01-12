import hre, { ethers, OpenzeppelinDefender } from "hardhat";
import { deploy } from "./deploy";
import { initiate } from "./initiate";
import fs from "fs";

async function main() {
	// read deployments and config
	const deployments = JSON.parse(
		fs.readFileSync(
			process.cwd() + `/deployments/${hre.network.name}/deployments.json`,
			"utf8"
		)
	);
	const config = JSON.parse(
		fs.readFileSync(
			process.cwd() + `/deployments/${hre.network.name}/config.json`,
			"utf8"
		)
	);
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

	const synthex = contracts.synthex;

	// initiate the contracts
	await initiate(contracts.synthex, contracts.oracle, deployments, config, contracts.addressManager);

	await synthex.renounceRole(await synthex.ADMIN_ROLE(), deployer.address);
	await synthex.renounceRole(
		await synthex.POOL_MANAGER_ROLE(),
		deployer.address
	);

	if (hre.network.name !== "hardhat") {
		// Add contract to openzeppelin defender
		console.log("Adding contract to openzeppelin defender... 💬");
		// get the abi in json string using the contract interface
		const AbiJsonString = OpenzeppelinDefender.Utils.AbiJsonString(
			synthex.interface
		);

		//Obtaining the name of the network through the chainId of the network
		const networkName = OpenzeppelinDefender.Utils.fromChainId(
			Number(hre.network.config.chainId!)
		);

		//add the contract to the admin
		const option = {
			network: networkName!,
			address: synthex.address,
			name: `SyntheX ${config.version.split(".")[0]}.${
				config.version.split(".")[1]
			}.x`,
			abi: AbiJsonString as string,
		};

		await OpenzeppelinDefender.AdminClient.addContract(option);
		console.log(
			`SyntheX ${config.version} added to openzeppelin defender! 🎉`
		);
	}

	// save deployments
	fs.writeFileSync(
		process.cwd() + `/deployments/${hre.network.name}/config.json`,
		JSON.stringify(config, null, 2)
	);
	fs.writeFileSync(
		process.cwd() + `/deployments/${hre.network.name}/deployments.json`,
		JSON.stringify(deployments, null, 2)
	);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});