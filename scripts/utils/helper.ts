import { DeployProxyOptions } from "@openzeppelin/hardhat-upgrades/dist/utils";
import { ethers, OpenzeppelinDefender } from "hardhat";
import { upgrades } from "hardhat";
import { utils, Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

export const _deploy = async (
	contractName: string,
	args: any[],
	deployments: any,
	{upgradable = false, name = contractName, libraries = {}} = {},
	config: any = {},
) => {
	const Contract = await ethers.getContractFactory(contractName, {libraries});
	let contract;
	if (upgradable) {
		// wrap it
		const deployProxyParams: DeployProxyOptions = { type: 'uups', unsafeAllowLinkedLibraries: true } as DeployProxyOptions;
		// deploy
		contract = await upgrades.deployProxy(Contract, args, deployProxyParams);
		args = [];
	} else {
		contract = await Contract.deploy(...args);
	}
	contract = await contract.deployed();

	deployments.contracts[name] = {
		address: contract.address,
		abi: contractName,
		constructorArguments: args,
		block: (await ethers.provider.getBlockNumber()).toString(),
	};
	deployments.sources[contractName] = Contract.interface.format("json");

	if (upgradable) {
		const implementationAddress = await upgrades.erc1967.getImplementationAddress(contract.address);
		if(!deployments.contracts[name].implementations) deployments.contracts[name].implementations = {};
		deployments.contracts[name].implementations[config.latest] = {
			address: implementationAddress,
			source: name+'_'+config.latest,
			constructorArguments: [],
			version: config.latest,
			block: (await ethers.provider.getBlockNumber()).toString()
		};
		deployments.contracts[name].latest = implementationAddress;
		deployments.sources[name+'_'+config.latest] = contract.interface.format('json');
	}
	return contract;
};

