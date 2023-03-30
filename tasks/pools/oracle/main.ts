import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { Contract } from 'ethers';
import { _deploy } from '../../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../../scripts/utils/defender';


export default async function main(poolAddress: string, isTest: boolean = false): Promise<Contract> {
    if(!isTest) console.log(`Deploying PriceOracle for ${poolAddress} to ${hre.network.name} (${hre.network.config.chainId}) ...`);

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
    const synthexAddress = deployments.contracts["SyntheX"].address;

    // get pool contract
    const pool = await ethers.getContractAt("Pool", poolAddress);
    const pool_symbol = await pool.symbol();
    const args = [
        synthexAddress, 
        [],
        [],
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        1e8
      ]

    // deploy synthex
    const oracle = await _deploy("PriceOracle", args, deployments, {name: 'PriceOracle_'+pool_symbol}) as Contract;

    if(!isTest) console.log(`PriceOracle deployed at ${oracle.address}`);
    if((hre.network.config as any).isLive){
        try{
            await hre.run("verify:verify", {
                address: oracle.address,
                constructorArguments: args
            })
        } catch (err) {
            console.log("Could not verify oracle");
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

    return oracle;
}

