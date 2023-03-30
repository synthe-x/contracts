import hre, { ethers, upgrades } from 'hardhat';
import fs from 'fs';
import { Contract } from 'ethers';
import { _deploy } from '../../../scripts/utils/helper';
import { _deploy as _deployDefender } from '../../../scripts/utils/defender';


export default async function main(poolAddress: string, oracleAddress: string, issuerAlloc: string, rewardSpeed: string, isTest: boolean = false): Promise<void> {
    if(!isTest) console.log(`Initializing Pool ${poolAddress} to ${hre.network.name} (${hre.network.config.chainId}) ...`);

	// read deployments and config
	const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/deployments.json`, "utf8"));
	const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/${hre.network.config.chainId}/config.json`, "utf8"));
	
    const esSYXAddress = deployments.contracts["EscrowedSYX"].address;
    const synthexAddress = deployments.contracts["SyntheX"].address;

    // pool contract
    const Pool = await ethers.getContractFactory("Pool");
    const pool = Pool.attach(poolAddress);

    // synthex contract
    const SyntheX = await ethers.getContractFactory("SyntheX");
    const synthex = SyntheX.attach(synthexAddress);

    await pool.setPriceOracle(oracleAddress);
    if(!isTest) console.log(`Price oracle set to ${oracleAddress}`);
    await pool.setIssuerAlloc(issuerAlloc);
    if(!isTest) console.log(`Issuer allocation set to ${Number(issuerAlloc)/100}%`);
    await synthex.setPoolSpeed(esSYXAddress, pool.address, rewardSpeed, true)
    if(!isTest) console.log(`Reward speed set to ${ethers.utils.formatEther(rewardSpeed)} SYX per second`);

    if(!isTest) console.log(`Pool initialized!`);
}