import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { _deploy } from '../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../scripts/utils/defender';
import { Contract } from 'ethers';
import { DEFAULT_ADMIN_ROLE, L1_ADMIN_ROLE, L2_ADMIN_ROLE } from '../../scripts/utils/const';


export default async function main(isTest: boolean = false): Promise<void> {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
	const [deployer] = await ethers.getSigners();

    // get synthex contract
    const synthexAddress = deployments.contracts["SyntheX"].address;
    const SyntheX = await ethers.getContractFactory("SyntheX");
    const synthex = SyntheX.attach(synthexAddress);


    // set admins
	if(!isTest) console.log("Setting admins... 💬")

    await synthex.grantRole(DEFAULT_ADMIN_ROLE, config.l0Admin);
    await synthex.grantRole(L1_ADMIN_ROLE, config.l1Admin);
    await synthex.grantRole(L2_ADMIN_ROLE, config.l2Admin);

	if(deployer.address !== config.l0Admin) await synthex.renounceRole(DEFAULT_ADMIN_ROLE, deployer.address);
	if(deployer.address !== config.l1Admin) await synthex.renounceRole(L1_ADMIN_ROLE, deployer.address);
	if(deployer.address !== config.l2Admin) await synthex.renounceRole(L2_ADMIN_ROLE, deployer.address);
	if(!isTest) console.log("Admins set! 🎉")
}

