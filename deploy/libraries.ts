import deployLibraries from '../tasks/pools/main'
import newDeployment from "../tasks/new";

import { utils, Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

import { _deploy } from "./utils/helper";

import dotenv from 'dotenv';
dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment, isTest: boolean = false) {
	if(!isTest) console.log(`Deploying libraries to ${hre.network.name} (${hre.network.config.chainId}) ...`);
	await newDeployment(isTest);

	const wallet = new Wallet(process.env.PRIVATE_KEY!);
	const deployer = new Deployer(hre, wallet);

	await deployLibraries(false, _deploy(deployer));
}
