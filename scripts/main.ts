import hre, { ethers } from "hardhat";
import { initiate } from "./initiate";
import newDeployment from "../tasks/new";

import deploySynthex from '../tasks/synthex/main'
import deployVault from '../tasks/vault/main'
import deployToken from '../tasks/syx/main'
import resetAdmins from '../tasks/admins/main'
import fs from 'fs';

export default async function main(isTest: boolean = true) {
	if(!isTest) console.log(`Deploying to ${hre.network.name} (${hre.network.config.chainId}) ...`);
	await newDeployment(isTest);

	const initialBalance = await hre.ethers.provider.getBalance(hre.ethers.provider.getSigner().getAddress());
	
	const [deployer] = await ethers.getSigners();

	// deploy main contracts
	let contracts: any = {};
	contracts.synthex = await deploySynthex(deployer.address, isTest);
	contracts.vault = await deployVault(contracts.synthex, isTest);
	let tokenDeployments = await deployToken(deployer.address, isTest)
	contracts.SYX = tokenDeployments.SYX;
	contracts.esSYX = tokenDeployments.esSYX;
	contracts.WETH = tokenDeployments.WETH;
	
	// initiate the contracts
	const initiates = await initiate(isTest);

	// reset admins
	if(!isTest) resetAdmins(contracts.synthex, deployer.address, isTest)

	// Add Multicall and MockToken to deployments
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	if(!deployments.contracts["Multicall2"]) deployments.contracts["Multicall2"] = {
		address: config.multicall ?? "",
		abi: "Multicall2"
	}
	deployments.sources["Multicall2"] = (await ethers.getContractFactory("Multicall2")).interface.format("json")
	deployments.sources["MockToken"] = (await ethers.getContractFactory("MockToken")).interface.format("json")

	// save deployments
	fs.writeFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, JSON.stringify(deployments, null, 2));
	
	if(!isTest) console.log("Deployment complete! 🎉", ethers.utils.formatEther(initialBalance.sub(await hre.ethers.provider.getBalance(hre.ethers.provider.getSigner().getAddress()))), "ETH used");
	return { ...contracts, ...initiates };
}