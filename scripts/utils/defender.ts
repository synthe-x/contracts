import { Contract, ethers } from 'ethers';
import hre, { OpenzeppelinDefender } from 'hardhat';
import { AbiInterfaceParams } from "hardhat-openzeppelin-defender/dist/src/OpenzeppelinDefender/Utils/models/types";

export const _deploy = async (contractName: string, contract: Contract) => {
	return;
    if(!hre.network.config.chainId) throw new Error('ChainId not found in network config');
    if(hre.network.name == "hardhat") return;
    // Add contract to openzeppelin defender
    console.log(`\tAdding ${contractName} to openzeppelin defender... 💬`);
    // get the abi in json string using the contract interface
    const AbiJsonString = OpenzeppelinDefender.Utils.AbiJsonString(
        contract.interface
    );

    //Obtaining the name of the network through the chainId of the network
    const networkName = OpenzeppelinDefender.Utils.fromChainId(
        Number(hre.network.config.chainId!)
    );

    //add the contract to the admin
    const option = {
        network: networkName!,
        address: contract.address,
        name: contractName,
        abi: AbiJsonString as string,
    };

    await OpenzeppelinDefender.AdminClient.addContract(option);
    console.log(
        `\t${contractName} added to openzeppelin defender! 🎉`
    );
}

export const _propose = async (
    contractName: string,
	contract: Contract,
	functionName: string,
	args: any[],
    caller: string
) => {
    if(!hre.network.config.chainId) throw new Error('ChainId not found in network config');
    if(hre.network.name == "hardhat") return;
			
	// obtaining the parameters of an event or function through the contract interface
	const params: AbiInterfaceParams = {
		abiInterface: contract.interface,
		name: functionName,
		type: "function",
	};
			
	const {inputs,name} = OpenzeppelinDefender.Utils.getAbiInterfaceParams(params);

	// adding a new contract to the admin and creating a proposal
	const option = {
		contract: {
		  network: OpenzeppelinDefender.Utils.fromChainId(hre.network.config.chainId!)!,
		  address: contract.address,
		  name: contractName,
		  abi: contract.interface.format(ethers.utils.FormatTypes.json)
		},
		title: `Call ${functionName} on ${contractName}`,
		description: `This is a proposal to call the function ${functionName} with args ${args.toString()} on ${contractName} contract`,
		type: "custom", 
		functionInterface: {
		  name: name,
		  inputs: inputs,
		},
		functionInputs: args,
		via: caller,
		viaType:'EOA'
	};

    await OpenzeppelinDefender.AdminClient.createProposal(option as any);
			
}