import { DeployProxyOptions, getInitializerData } from "@openzeppelin/hardhat-upgrades/dist/utils";
import { ethers, OpenzeppelinDefender } from "hardhat";
import { upgrades } from "hardhat";
import { Contract, ContractFactory, utils, Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Interface } from "ethers/lib/utils";

export const _deploy = (
	deployer: Deployer
) => {
	return async function deploy(
		contractName: string,
		args: any[],
		deployments: any,
		{upgradable = false, name = contractName} = {},
		config: any = {}
		) {

	const Contract = await deployer.loadArtifact(contractName);

	let contract: Contract;
	if (upgradable) {
		// deploy
		const impl = await deployer.deploy(Contract, []);
		const factory = new ContractFactory(Contract.abi, Contract.bytecode, deployer.zkWallet);
		const data = getInitializerData(new Interface(Contract.abi), args);
		const ProxyFactory = await deployer.loadArtifact("ERC1967Proxy");
		// wait for 2 blocks for the proxy to be deployed
		await impl.deployTransaction.wait();
		contract = await deployer.deploy(ProxyFactory, [impl.address, data]);
		contract = factory.attach(contract.address);
	} else {
		contract = await deployer.deploy(Contract, args);
	}

	deployments.contracts[name] = {
		address: contract.address,
		abi: contractName,
		constructorArguments: args,
		block: (await ethers.provider.getBlockNumber()).toString(),
	};
	deployments.sources[contractName] = Contract.abi;

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
}

};

