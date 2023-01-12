import { ethers } from "hardhat";
import { upgrades } from "hardhat";

export const _deploy = async (
	contractName: string,
	args: any[],
	deployments: any,
	{upgradable = false, name = contractName} = {},
	config: any = {},
) => {
	const Contract = await ethers.getContractFactory(contractName);
	let contract;
	if (upgradable) {
		contract = await upgrades.deployProxy(Contract, args, { type: 'uups' });
		args = [];
	} else {
		contract = await Contract.deploy(...args);
	}
	await contract.deployed();

	deployments.contracts[name] = {
		address: contract.address,
		abi: contractName,
		constructorArguments: args,
		block: (await ethers.provider.getBlockNumber()).toString(),
	};
	deployments.sources[contractName] = JSON.parse(
		Contract.interface.format("json") as string
	);

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
