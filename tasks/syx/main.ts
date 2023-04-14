import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { _deploy } from '../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../scripts/utils/defender';
import { Contract } from 'ethers';
import { AUTHORIZED_SENDER } from '../../scripts/utils/const';

export default async function main(isTest: boolean = false): Promise<{SYX: Contract, esSYX: Contract, WETH: Contract}> {
	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
    
    const synthexAddress = deployments.contracts["SyntheX"].address;

    let weth;
    if(config.weth){
        // attach to existing weth
        weth = await ethers.getContractAt("WETH9", config.weth);
    } else {
        if(!isTest) console.warn("WETH not found, deploying new WETH9 contract...")
        weth = await _deploy("WETH9", [], deployments);
    }

    const [deployer] = await ethers.getSigners();

    /* -------------------------------------------------------------------------- */
    /*                                  SYX Token                                 */
    /* -------------------------------------------------------------------------- */
    if(!isTest) console.log(`Deploying SYX Token to ${hre.network.name} (${hre.network.config.chainId}) ...`);
    const SYXArgs = [synthexAddress];
    // deploy SYX
    const SYX = await _deploy("SyntheXToken", SYXArgs, deployments, {upgradable: true}, config);
    if(!isTest) console.log(`SYX deployed at ${SYX.address}`);

    /* -------------------------------------------------------------------------- */
    /*                                 esSYX Token                                */
    /* -------------------------------------------------------------------------- */
    if(!isTest) console.log(`Deploying esSYX Token to ${hre.network.name} (${hre.network.config.chainId}) ...`);
    const esSYXArgs = [
        synthexAddress,
        SYX.address,
        weth.address,
        config.esSYX.initialRewardsDuration,
        config.esSYX.lockPeriod,
        config.esSYX.unlockPeriod,
        config.esSYX.percReleaseAtUnlock
    ]
    // deploy esSYX
    const esSYX = await _deploy("EscrowedSYX", esSYXArgs, deployments, {upgradable: true}, config);
    if(!isTest) console.log(`esSYX deployed at ${esSYX.address}`);
    
    // mint initial reward tokens to synthex
    await SYX.mint(deployer.address, ethers.utils.parseEther(config.rewardAlloc));
    await SYX.increaseAllowance(esSYX.address, ethers.utils.parseEther(config.rewardAlloc));
    await esSYX.lock(ethers.utils.parseEther(config.rewardAlloc), synthexAddress);
    await esSYX.grantRole(AUTHORIZED_SENDER, synthexAddress);

    if((hre.network.config as any).isLive){
        try{
            await hre.run("verify:verify", {
                address: esSYX.address,
                constructorArguments: []
            })
        } catch (err) {
            console.log("Could not verify esSYX");
        }

        try{
            await hre.run("verify:verify", {
                address: SYX.address,
                constructorArguments: []
            })
        } catch (err) {
            console.log("Could not verify SYX");
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

    return { esSYX, SYX, WETH: weth };
}