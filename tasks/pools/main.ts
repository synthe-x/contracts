import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { Contract } from 'ethers';
import { _deploy } from '../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../scripts/utils/defender';


export default async function main(name: string, symbol: string, weth: string, isTest: boolean = false): Promise<Contract> {
    if(!isTest) console.log(`Deploying Pool ${name} to ${hre.network.name} (${hre.network.config.chainId}) ...`);

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
    const synthexAddress = deployments.contracts["SyntheX"].address;
    
    const args = [
        name,
        symbol,
        synthexAddress,
        weth
    ];

    // deploy synthex
    const pool = await _deploy("Pool", args, deployments, {upgradable: true, name: 'POOL_'+symbol}, config) as Contract;

    if(!isTest) console.log(`Pool deployed at ${pool.address}`);
    if((hre.network.config as any).isLive){
        try{
            await hre.run("verify:verify", {
                address: pool.address,
                constructorArguments: []
            })
        } catch (err) {
            console.log("Could not verify pool");
        }
    }

    _deployDefender(symbol +'_'+ config.version, pool)
    
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

    return pool;
}

