import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { Contract } from 'ethers';
import { _deploy as _deployEVM } from '../../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../../scripts/utils/defender';
const { defender } = require("hardhat");

export default async function main(poolAddress: string, collateralLogic: string, poolLogic: string, synthLogic: string, isTest: boolean = false, _deploy = _deployEVM) {
    if(!isTest) console.log(`Deploying Pool Libraries ...`);

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
    // deploy contracts
    const Pool = await ethers.getContractFactory("Pool", {
        libraries: {
            CollateralLogic: collateralLogic,
            PoolLogic: poolLogic,
            SynthLogic: synthLogic
        }
    });
	
    await defender.proposeUpgrade(poolAddress, Pool, {title: `Upgrade to ${config.latest}`, multisig: config.l1Admin, unsafeAllowLinkedLibraries: true});
    
    // if((hre.network.config as any).isLive){
    //     try{
    //         await hre.run("verify:verify", {
    //             address: collateralLogic.address,
    //             constructorArguments: []
    //         })
    //         .catch((err) => {
    //             console.log("Could not verify collateralLogic");
    //         })

    //         await hre.run("verify:verify", {
    //             address: poolLogic.address,
    //             constructorArguments: []
    //         })
    //         .catch((err) => {
    //             console.log("Could not verify collateralLogic");
    //         })

    //         await hre.run("verify:verify", {
    //             address: synthLogic.address,
    //             constructorArguments: []
    //         })
    //         .catch((err) => {
    //             console.log("Could not verify collateralLogic");
    //         })
    //     } catch (err) {
    //         console.log("Could not verify libraries");
    //     }
    // }
    
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
}

