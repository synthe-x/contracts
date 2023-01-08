import hre, { ethers } from "hardhat";
import fs from "fs";

async function upgrade() {
	const deployments = JSON.parse(
		fs.readFileSync(
			process.cwd() + `/deployments/${hre.network.name}/deployments.json`,
			"utf8"
		)
	);

    // upgrade version
	const config = JSON.parse(
		fs.readFileSync(
			process.cwd() + `/deployments/${hre.network.name}/config.json`,
			"utf8"
		)
	);
	config.latest = config.latest.split(".")[0] +
		"." +
		config.latest.split(".")[1]+
		"." +
        (parseInt(config.latest.split(".")[2]) + 1);
	

	const SyntheX = await ethers.getContractFactory("SyntheX");
	const synthex = await SyntheX.deploy();
    await synthex.deployed();

    console.log("SyntheX upgraded to:", synthex.address);
    
    deployments.contracts['SyntheX'].implementations[config.latest] = {
        address: synthex.address,
        source: 'SyntheX_'+config.latest,
        constructorArguments: [],
        version: config.latest,
		block: (await ethers.provider.getBlockNumber()).toString()
    };
    deployments.sources['SyntheX_'+config.latest] = JSON.parse(synthex.interface.format('json') as string);

	fs.writeFileSync(
		process.cwd() + `/deployments/${hre.network.name}/deployments.json`,
		JSON.stringify(deployments, null, 2)
	);
    fs.writeFileSync(
		process.cwd() + `/deployments/${hre.network.name}/config.json`,
		JSON.stringify(config, null, 2)
	);
}

upgrade().then(() => process.exit(0)).catch(error => {
    console.log(error);
})