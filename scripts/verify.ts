import hre from 'hardhat';
import fs from 'fs';

export async function verify(){
    // read deployments
    const deployments = JSON.parse(fs.readFileSync( process.cwd() + `/deployments/${hre.network.name}/deployments.json`, 'utf8'));
    for(let i in deployments.contracts){
        await hre.run("verify:verify", {
            address: deployments.contracts[i].address,
            constructorArguments: deployments.contracts[i].constructorArguments
        });
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
verify().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});