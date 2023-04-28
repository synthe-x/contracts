import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { _deploy as _deployEVM } from '../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../scripts/utils/defender';
import { Contract } from 'ethers';
import { VAULT, L1_ADMIN_ROLE, L2_ADMIN_ROLE } from '../../scripts/utils/const';

export default async function routerMain(WETH9: string, vault: string, isTest: boolean = false, _deploy = _deployEVM): Promise<Contract> {
    if (!isTest) console.log(`Deploying Router to ${hre.network.name} (${hre.network.config.chainId}) ...`);


    const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
    // deploy vault
    const args: string[] = [WETH9, vault];
    const router = await _deploy("Router", args, deployments) as Contract;
    if (!isTest) console.log(`router deployed at ${router.address}`);

    if ((hre.network.config as any).isLive) {
        try {
            hre.run("verify:verify", {
                address: router.address,
                constructorArguments: []
            })
        } catch (err) {
            console.log("Could not verify router");
        }
    }

    // save deployments


    return router;
}