import hre, { upgrades } from "hardhat";
import fs from "fs";

async function main() {
	const config = JSON.parse(
		fs.readFileSync(
			process.cwd() + `/deployments/${hre.network.name}/config.json`,
			"utf8"
		)
	);

	console.log("Transferring ownership of ProxyAdmin...");
	// The owner of the ProxyAdmin can upgrade our contracts
	await upgrades.admin.transferProxyAdminOwnership(config.admin);
	console.log("Transferred ownership of ProxyAdmin to:", config.admin);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
