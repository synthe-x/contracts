import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { _deploy } from '../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../scripts/utils/defender';
import { Contract } from 'ethers';
import { VAULT, L1_ADMIN_ROLE, L2_ADMIN_ROLE } from '../../scripts/utils/const';

export default async function main(isTest: boolean = false): Promise<Contract> {
    if(!isTest) console.log(`Deploying Vault to ${hre.network.name} (${hre.network.config.chainId}) ...`);

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
	const [deployer] = await ethers.getSigners();

    // synthex contract
    const synthex = await ethers.getContractAt("SyntheX", deployments.contracts["SyntheX"].address) as Contract;
    
    const args = [deployments.contracts["SyntheX"].address]

    // deploy vault
    const vault = await _deploy("Vault", args, deployments, { upgradable: true }) as Contract;
    if(!isTest) console.log(`Vault deployed at ${vault.address}`);
    await synthex.setAddress(VAULT, vault.address);
    if(!isTest) console.log(`Vault address set in SyntheX`);

    if((hre.network.config as any).isLive){
        try{
            await hre.run("verify:verify", {
                address: vault.address,
                constructorArguments: []
            })
        } catch (err) {
            console.log("Could not verify vault");
        }
    }

    // _deployDefender("SyntheX" +'_'+ config.version, synthex);
    
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

    return vault;
}