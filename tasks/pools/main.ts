import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { Contract } from 'ethers';
import { _deploy as _deployEVM } from '../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../scripts/utils/defender';

interface Return {
    collateralLogic: Contract,
    poolLogic: Contract,
    synthLogic: Contract
}

export default async function main(isTest: boolean = false, _deploy = _deployEVM): Promise<Return> {
    if(!isTest) console.log(`Deploying Pool Libraries ...`);

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
    // deploy contracts
    const collateralLogic = await _deploy("CollateralLogic", [], deployments, {}, config) as Contract;
    if(!isTest) console.log(`CollateralLogic deployed at ${collateralLogic.address}`);
    const poolLogic = await _deploy("PoolLogic", [], deployments, {}, config) as Contract;
    if(!isTest) console.log(`PoolLogic deployed at ${poolLogic.address}`);
    const synthLogic = await _deploy("SynthLogic", [], deployments, {}, config) as Contract;
    if(!isTest) console.log(`SynthLogic deployed at ${synthLogic.address}`);

    if((hre.network.config as any).isLive){
        try{
            hre.run("verify:verify", {
                address: collateralLogic.address,
                constructorArguments: []
            })
            .catch((err) => {
                console.log("Could not verify collateralLogic");
            })

            hre.run("verify:verify", {
                address: poolLogic.address,
                constructorArguments: []
            })
            .catch((err) => {
                console.log("Could not verify collateralLogic");
            })

            hre.run("verify:verify", {
                address: synthLogic.address,
                constructorArguments: []
            })
            .catch((err) => {
                console.log("Could not verify collateralLogic");
            })
        } catch (err) {
            console.log("Could not verify libraries");
        }
    }
    
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

    return {
        collateralLogic,
        poolLogic,
        synthLogic
    }
}

