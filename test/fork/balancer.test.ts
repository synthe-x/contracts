import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";

const VAULT = '';
const STABLE_FACTORY = '';

describe("Testing the complete flow", function () {

	let synthex: any, oracle: any, pool: any, eth: any, cusd: any, cbtc: any, ceth: any, cbtcFeed: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
        eth = deployments.pools[0].collateralTokens[0];
		pool = deployments.pools[0].pool;
		oracle = deployments.pools[0].oracle;
		cbtc = deployments.pools[0].synths[0];
		cbtcFeed = deployments.pools[0].synthPriceFeeds[0];
		ceth = deployments.pools[0].synths[1];
		cusd = deployments.pools[0].synths[2];
	});

    it("should create eth-ceth stable pair", async () => {
        console.log("ceth address", ceth.address, eth.address);
    })

    it("join 10 ETH + 10 cETH", async () => {})
});