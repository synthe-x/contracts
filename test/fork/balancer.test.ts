import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { BigNumber, Contract } from 'ethers';
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { promises as fs } from "fs";
import path from 'path';

const VAULT = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
const STABLE_FACTORY = '0x1c99324EDC771c82A0DCCB780CC7DDA0045E50e7';

describe("Testing balancer pool", function () {

	let synthex: any, oracle: any, pool: any, eth: any, cusd: any, cbtc: any, ceth: any, cbtcFeed: any;
	let owner: any, user1: any, user2: any, user3: any;
	const provider = new ethers.providers.JsonRpcProvider("https://arbitrum.blockpi.network/v1/rpc/public");
	let balancerPool;
	let poolFactory: Contract;
	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
	let mockPoolArgs;
	let _deployments: any;
	const BaseVersion = { version: 3, deployment: '20230206-composable-stable-pool-v3' };
	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();
		_deployments = JSON.parse((await fs.readFile(path.join(__dirname + "/../../deployments/42161/deployments.json"))).toString())

		const deployments = await loadFixture(main);
		synthex = deployments.synthex;
		eth = deployments.pools[0].collateralTokens[0];
		pool = deployments.pools[0].pool;
		oracle = deployments.pools[0].oracle;
		cbtc = deployments.pools[0].synths[0];
		cbtcFeed = deployments.pools[0].synthPriceFeeds[0];
		ceth = deployments.pools[0].synths[1];
		cusd = deployments.pools[0].synths[2];

		poolFactory = new ethers.Contract(STABLE_FACTORY, _deployments["sources"]["ComposableStablePoolFactory"], provider);

	});

	it("should create eth-ceth stable pair", async () => {
		console.log("ceth address", ceth.address, eth.address);

		mockPoolArgs = {
			vault: VAULT,
			protocolFeeProvider: "0x5ef4c5352882b10893b70DbcaA0C000965bd23c5",
			name: 'DO NOT USE - Mock Composable Stable Pool',
			symbol: 'TEST',
			tokens: [eth.address, ceth.address].sort(function (a, b) {
				return a.toLowerCase().localeCompare(b.toLowerCase());
			}),
			rateProviders: [ZERO_ADDRESS, ZERO_ADDRESS],
			tokenRateCacheDurations: [0, 0],
			exemptFromYieldProtocolFeeFlags: [false, false],
			amplificationParameter: BigNumber.from(100),
			swapFeePercentage: BigNumber.from(1e12),
			pauseWindowDuration: undefined,
			bufferPeriodDuration: undefined,
			owner: ZERO_ADDRESS,
			version: JSON.stringify({ name: 'ComposableStablePool', ...BaseVersion }),
		};
		let createbalancerPool = (await poolFactory.connect(owner).create(
			mockPoolArgs.name,
			mockPoolArgs.symbol,
			mockPoolArgs.tokens,
			mockPoolArgs.amplificationParameter,
			mockPoolArgs.rateProviders,
			mockPoolArgs.tokenRateCacheDurations,
			mockPoolArgs.exemptFromYieldProtocolFeeFlags,
			mockPoolArgs.swapFeePercentage,
			mockPoolArgs.owner
		)).wait(1)
		// creating contract factory
		let events = (await createbalancerPool).events;
		let args = events[events.length - 1].args;
		let poolAddress = args[0]
		balancerPool = new ethers.Contract(poolAddress, _deployments["sources"]["ComposableStablePool"], provider);
		console.log(poolAddress);

		let poolId = await balancerPool.getPoolId();
		console.log(poolId, "poolId")

	})
});