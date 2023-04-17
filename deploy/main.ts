import hre, { ethers } from "hardhat";
import { initiate } from "./initiate";
import newDeployment from "../tasks/new";

import deploySynthex from '../tasks/synthex/main'
import deployVault from '../tasks/vault/main'
import deployToken from '../tasks/syx/main'
import resetAdmins from '../tasks/admins/main'
import fs from 'fs';

import { utils, Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

import { _deploy } from "./utils/helper";

import dotenv from 'dotenv';
dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment, isTest: boolean = false) {
	if(!isTest) console.log(`Deploying to ${hre.network.name} (${hre.network.config.chainId}) ...`);
	await newDeployment(isTest);

	const wallet = new Wallet(process.env.PRIVATE_KEY!);
	console.log("Deployer address:", wallet.address);
	const deployer = new Deployer(hre, wallet);

	const initialBalance = await hre.ethers.provider.getBalance(wallet.address);
	console.log("Initial balance:", ethers.utils.formatEther(initialBalance), "ETH");
	
	// deploy main contracts
	let contracts: any = {};
	contracts.synthex = await deploySynthex(wallet.address, isTest, _deploy(deployer));
	contracts.vault = await deployVault(contracts.synthex, isTest, _deploy(deployer));
	let tokenDeployments = await deployToken(wallet.address, isTest, _deploy(deployer))
	contracts.SYX = tokenDeployments.SYX;
	contracts.esSYX = tokenDeployments.esSYX;
	contracts.WETH = tokenDeployments.WETH;
	
	// initiate the contracts
	const initiates = await initiate(contracts.WETH, isTest, deployer);

	// reset admins
	if(!isTest) resetAdmins(contracts.synthex, wallet.address, isTest)

	// Add Multicall and MockToken to deployments
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	deployments.contracts["Multicall2"] = {
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