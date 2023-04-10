import hre, { ethers } from "hardhat";
import { initiate } from "./initiate";
import newDeployment from "../tasks/new";

import deploySynthex from '../tasks/synthex/main'
import deployVault from '../tasks/vault/main'
import deployToken from '../tasks/syx/main'
import resetAdmins from '../tasks/admins/main'

export default async function main(isTest: boolean = true) {
	if(!isTest) console.log(`Deploying to ${hre.network.name} (${hre.network.config.chainId}) ...`);

	await newDeployment(isTest);

	const initialBalance = await hre.ethers.provider.getBalance(hre.ethers.provider.getSigner().getAddress());
	
	// deploy main contracts
	let contracts: any = {};
	contracts.synthex = await deploySynthex(isTest);
	contracts.vault = await deployVault(isTest);
	let tokenDeployments = await deployToken(isTest)
	contracts.SYX = tokenDeployments.SYX;
	contracts.esSYX = tokenDeployments.esSYX;
	contracts.WETH = tokenDeployments.WETH;
	
	// initiate the contracts
	const initiates = await initiate(isTest);

	// reset admins
	if(!isTest) resetAdmins(isTest)

	if(!isTest) console.log("Deployment complete! 🎉", ethers.utils.formatEther(initialBalance.sub(await hre.ethers.provider.getBalance(hre.ethers.provider.getSigner().getAddress()))), "ETH used");
	return { ...contracts, ...initiates };
}