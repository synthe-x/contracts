import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { BigNumber, Contract } from 'ethers';
import hre, { ethers } from "hardhat";
import main from "../../scripts/main";
import { promises as fs } from "fs";
import path from 'path';
import routerMain from '../../tasks/router/main';

const VAULT = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
const STABLE_FACTORY = '0x1c99324EDC771c82A0DCCB780CC7DDA0045E50e7';
function pe(amount: number | string) {
	return ethers.utils.parseEther(`${amount}`);
}
describe("Testing balancer pool", function () {

	let synthex: any, oracle: any, pool: any, eth: any, cusd: any, ceth: any, weth: any, usdc: any, poolTokens: string[];
	let owner: any, user1: any, user2: any, user3: any, banalcerPoolId: string, balancerPoolAddress: string;
	const provider = new ethers.providers.JsonRpcProvider("https://arb-mainnet.g.alchemy.com/v2/mJSnb6p3QRZdqQIHgJerJCI5M9kul8lo");
	let balancerPool;
	let poolFactory: Contract, vault: Contract, router: Contract;
	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
	let mockPoolArgs;
	let _deployments: any;
	let deployments: any;
	const BaseVersion = { version: 3, deployment: '20230206-composable-stable-pool-v3' };

	before(async () => {
		[owner, user1, user2, user3] = await ethers.getSigners();
		_deployments = JSON.parse((await fs.readFile(path.join(__dirname + "/../../abi/ABI.json"))).toString())
		// console.log(_deployments)
		deployments = await loadFixture(main);
		// console.log(deployments)
		// console.log(deployments)
		synthex = deployments.synthex;
		eth = deployments.pools[0].collateralTokens[0];
		pool = deployments.pools[0].pool;
		// oracle = deployments.pools[0].oracle;

		ceth = deployments.pools[0].synths[1];
		cusd = deployments.pools[0].synths[2];

		poolFactory = new ethers.Contract(STABLE_FACTORY, _deployments["ComposableStablePoolFactory"], provider);
		// console.log(poolFactory.address);
		vault = new ethers.Contract(VAULT, _deployments["Balancer_Vault"], provider);
		console.log(vault.address);

		weth = new ethers.Contract(eth.address, _deployments["WETH9"], provider);

		usdc = new ethers.Contract("0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", _deployments["ERC20X"], provider);

		console.log(await hre.ethers.provider.getBlockNumber())

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
		balancerPoolAddress = args[0];
		console.log("balancerPoolAddress", balancerPoolAddress)
		balancerPool = new ethers.Contract(balancerPoolAddress, _deployments["ComposableStablePool"], provider);

		banalcerPoolId = await balancerPool.connect(user1).callStatic.getPoolId();


		console.log(banalcerPoolId, "poolId");

		// const getPool = await vault.connect(user1).getPool(banalcerPoolId);
		// console.log("getPool", getPool);

		/////////////////////////////////////
	});

	it("Mint Tokens", async () => {
		// deposit eth in synthex pool.

		const deposit = pe("100");
		await pool.connect(user2).depositETH(user2.address, { value: deposit });
		// minth cETH
		await pool.connect(user2).mint(ceth.address, pe("50"), user2.address);

		const deposit1 = pe("200");
		await pool.connect(user3).depositETH(user3.address, { value: deposit1 });
		// minth cETH
		await pool.connect(user3).mint(ceth.address, pe("100"), user3.address)

		// const userLiquidity2 = await pool.getAccountLiquidity(user2.address);
		// const userLiquidity = await pool.getAccountLiquidity(user3.address);

		// console.log(userLiquidity);
		// console.log(userLiquidity2);
	});


	it("approve contracts", async () => {
		//approve pool
		await ceth.connect(user2).approve(pool.address, pe("10000000000000000000000000"));

		//approve balancerPool
		await ceth.connect(user2).approve(balancerPoolAddress, pe("10000000000000000000000000"));

		//approve vault
		await ceth.connect(user2).approve(VAULT, pe("10000000000000000000000000"));

		//approve pool
		await weth.connect(user2).approve(pool.address, pe("10000000000000000000000000"));

		//approve balancerPool
		await weth.connect(user2).approve(balancerPoolAddress, pe("10000000000000000000000000"));

		//approve vault
		await weth.connect(user2).approve(VAULT, pe("10000000000000000000000000"));
		///////////////////////////////////////////////////////////////////
		//approve pool
		await ceth.connect(user3).approve(pool.address, pe("10000000000000000000000000"));

		//approve balancerPool
		await ceth.connect(user3).approve(balancerPoolAddress, pe("10000000000000000000000000"));

		//approve vault
		await ceth.connect(user3).approve(VAULT, pe("10000000000000000000000000"));
		//approve pool
		await weth.connect(user3).approve(pool.address, pe("10000000000000000000000000"));

		//approve balancerPool
		await weth.connect(user3).approve(balancerPoolAddress, pe("10000000000000000000000000"));

		//approve vault
		await weth.connect(user3).approve(VAULT, pe("10000000000000000000000000"));
		/////////////////////////////////////////////////////
		//approve pool
		await ceth.connect(user1).approve(pool.address, pe("10000000000000000000000000"));

		//approve balancerPool
		await ceth.connect(user1).approve(balancerPoolAddress, pe("10000000000000000000000000"));

		//approve vault
		await ceth.connect(user1).approve(VAULT, pe("10000000000000000000000000"));
		//approve pool
		await weth.connect(user1).approve(pool.address, pe("10000000000000000000000000"));

		//approve balancerPool
		await weth.connect(user1).approve(balancerPoolAddress, pe("10000000000000000000000000"));

		//approve vault
		await weth.connect(user1).approve(VAULT, pe("10000000000000000000000000"));


	});

	it("join pool first time", async () => {

		poolTokens = (await vault.connect(user2).getPoolTokens(banalcerPoolId))[0]
		// console.log(poolTokens);

		await weth.connect(user2).deposit({ value: pe(20) });

		let balance = await weth.connect(user2).balanceOf(user2.address);
		console.log(balance)
		let joinPool = await vault.connect(user2).joinPool(
			banalcerPoolId,
			user2.address,
			user2.address,
			{
				assets: poolTokens,
				maxAmountsIn: [                     // length include pool token
					pe('100000000000000000000000'),
					pe('100000000000000000000000'),
					pe('100000000000000000000000'),
				],
				userData: ethers.utils.defaultAbiCoder.encode(
					['uint256', 'uint256[]'],
					[
						0,                                // for first time use 0 and in below array add one more element for pool token
						[pe(10), pe(10), pe(1)],     // length without pool token

					]),
				fromInternalBalance: false

			}
		)

		console.log("join Pool", joinPool);
	});

	it("join pool, EXACT_TOKENS_IN_FOR_BPT_OUT", async () => {

		await weth.connect(user3).deposit({ value: pe(100) });

		let balance = await weth.connect(user3).balanceOf(user3.address);
		console.log(balance)
		let joinPool = await vault.connect(user3).joinPool(
			banalcerPoolId,
			user3.address,
			user3.address,
			{
				assets: poolTokens,
				maxAmountsIn: [                     // length include pool token
					pe('100000000000000000000000'),
					pe('100000000000000000000000'),
					pe('100000000000000000000000'),
				],
				userData: ethers.utils.defaultAbiCoder.encode(
					['uint256', 'uint256[]', 'uint256'],
					[
						1,                                // for first time use 0 and in below array add one more element for pool token
						[pe(100), pe(100)],     // length without pool token
						0

					]),
				fromInternalBalance: false

			}
		);

		console.log("join Pool EXACT_TOKENS_IN_FOR_BPT_OUT", joinPool);


	})

	it("it sould batchSwap ", async () => {

		await weth.connect(user1).deposit({ value: pe(1.5) });
		let balance = await weth.connect(user1).balanceOf(user1.address);
		console.log(balance.toString(), "balance from swap")
		console.log(poolTokens, "poolTOkens")
		let batchSwap = await (await vault.connect(user1).batchSwap(
			0,
			[
				{
					poolId: banalcerPoolId,
					assetInIndex: 1,
					assetOutIndex: 2,
					amount: pe(0.5),
					userData: "0x"
				}

			],
			poolTokens,
			{
				sender: user1.address,
				fromInternalBalance: false,
				recipient: user1.address,
				toInternalBalance: false
			},
			['0', pe(0.50), pe(-0.49)],
			1689740240
		)
		).wait(1)
		console.log("batchSwap", batchSwap.events[0].args)
	})

	it("It should swap in router for balancer", async () => {
		console.log(await hre.ethers.provider.getBlockNumber())
		router = await routerMain(weth.address, vault.address, true);
		console.log("routerAddress", router.address);
		//approve router
		await weth.connect(user1).approve(router.address, pe('10000000000'));

		await ceth.connect(user1).approve(router.address, pe("1000000000"));

		await pool.connect(user1).approve(router.address, pe("20000000000"));
		console.log("weth", await weth.connect(user1).balanceOf(user1.address))
		const swap = await (await router.connect(user1).swap(
			{
				"kind": 0,
				"swaps": [
					{
						"swap": [
							{
								"poolId": "0x64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002",
								"assetInIndex": "0",
								"assetOutIndex": "1",
								"userData": "0x",
								"amount": "1000000000000000000"
							}
						],
						"isBalancerPool": true,
						"limits": [
							"1000000000000000000",
							"-1882662266"
						],
						"assets": [
							"0x82af49447d8a07e3bd95bd0d56f35241523fbab1",
							"0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"
						]
					},
					{
						"swap": [
							{
								"poolId": "0x64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002",
								"assetInIndex": "1",
								"assetOutIndex": "0",
								"userData": "0x",
								"amount": "1882662266"
							}
						],
						"isBalancerPool": true,
						"limits": [
							"-900000000000000000",
							"1984354965"
						],
						"assets": [
							"0x82af49447d8a07e3bd95bd0d56f35241523fbab1",
							"0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"
						]
					},

				],
				"deadline": 1692683960,
				"funds": {
					"sender": user1.address,
					"recipient": user1.address,
					"fromInternalBalance": false,
					"toInternalBalance": false
				}
			}
		)).wait(1);

		console.log("Swap", swap)

		console.log("usdc", await usdc.connect(user1).balanceOf(user1.address))
		console.log("weth", await weth.connect(user1).balanceOf(user1.address))
		console.log("ceth", await ceth.connect(user1).balanceOf(user1.address))
	});

	it("It should swap in router for synthex", async () => {
		console.log(await hre.ethers.provider.getBlockNumber())
		// router = await routerMain(weth.address, vault.address, true);
		// console.log("routerAddress", router.address);
		
		console.log("ceth", await ceth.connect(user1).balanceOf(user1.address))
		const swap = await (await router.connect(user1).swap(
			{
				"kind": 0,
				"swaps": [
					{
						"swap": [
							{
								"poolId": "0xbbb3abfa2dd320d85c64e8825c1e32ad0026fae5000000000000000000000000",
								"assetInIndex": 0,
								"assetOutIndex": 1,
								"userData": "0x",
								"amount": "300000000000000000"
							}
						],
						"isBalancerPool": false,
						"limits": [
							"300000000000000000",
							"-570420511593375000000"
						],
						"assets": [
							"0xa28d78534d18324da06fc487041b1ab4a16d557d",
							"0xe379874446dd29178e68852992daa80be952c0b3"
						]
					}
				],
				"deadline": 1692683960,
				"funds": {
					"sender": user1.address,
					"recipient": user1.address,
					"fromInternalBalance": false,
					"toInternalBalance": false
				}
			}
		)).wait(1);

		console.log("Swap", swap)

		console.log("csdc", await cusd.connect(user1).balanceOf(user1.address))
		console.log("ceth", await ceth.connect(user1).balanceOf(user1.address))
	})



});

// {
// 	"kind": 0,
// 	"swaps": [
// 		{
// 			"swap": [
// 				{
// 					"poolId": "0x19ff30f9b2d32bfb0f21f2db6c6a3a8604eb8c2b00000000000000000000041c",
// 					"assetInIndex": "0",
// 					"assetOutIndex": "1",
// 					"userData": "0x",
// 					"amount": "1000000000000000000"
// 				}
// 			],
// 			"isBalancerPool": true,
// 			"limits": [
// 				pe(1),
// 				pe(-0.997490050036464600)
// 			],
// 			"assets": [
// 				"0x82af49447d8a07e3bd95bd0d56f35241523fbab1",
// 				"0xa28d78534d18324da06fc487041b1ab4a16d557d"
// 			]
// 		},
// 		{
// 			"swap": [
// 				{
// 					"poolId": "0xbbb3abfa2dd320d85c64e8825c1e32ad0026fae5000000000000000000000000",
// 					"assetInIndex": 0,
// 					"assetOutIndex": 1,
// 					"userData": "0x",
// 					"amount": "997490050036464700"
// 				}
// 			],
// 			"isBalancerPool": false,
// 			"limits": [
// 				pe(0.997490050036464600),
// 				pe(-1906.1600825832545)
// 			],
// 			"assets": [
// 				"0xa28d78534d18324da06fc487041b1ab4a16d557d",
// 				"0xe379874446dd29178e68852992daa80be952c0b3"
// 			]
// 		}
// 	],
// 	"deadline": 1692683960,
// 	"funds": {
// 		"sender": user1.address,
// 		"recipient": user1.address,
// 		"fromInternalBalance": false,
// 		"toInternalBalance": false
// 	}
// }