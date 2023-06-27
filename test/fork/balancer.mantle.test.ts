import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { BigNumber, Contract } from 'ethers';
import hre, { ethers } from "hardhat";
import main from "../../scripts/main";
import { promises as fs } from "fs";
import path from 'path';
import routerMain from '../../tasks/router/main';

import { EvmPriceServiceConnection } from "@pythnetwork/pyth-evm-js"

const VAULT = '0xc08e0bC5981622E3f70b8406ff9F19BbcEDa5bF1';
const STABLE_FACTORY = '0x648b82c9E963B808455184043fa6F5d968Bbc993';
const MANTLE_ADDRESS = "0x55f317247632d42584848064a0cc0190fe1f6c58";
const USDC_ADDRESS = "0x0134369386a3aebcf0704946c0df89fe78fa2b50";
const PROTOCOL_FEE_PROVIDER = "0x76d918A2cCEa990FFbB34caaa30a9c2729404599"
function pe(amount: number | string) {
	return ethers.utils.parseEther(`${amount}`);
}
describe("Testing balancer pool", function () {

	let pool: any, eth: any, cusd: any, ceth: any, weth: any, usdc: any, poolTokens: string[];
	let owner: any, user1: any, user2: any, user3: any, banalcerPoolId: string, balancerPoolAddress: string;
	const provider = new ethers.providers.JsonRpcProvider("https://rpc.testnet.mantle.xyz");
	let balancerPool;
	let poolFactory: Contract, vault: Contract, router: Contract;
	const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
	let mockPoolArgs;
	let _deployments: any;
	let deployments: any;
	const BaseVersion = { version: 3, deployment: '20230206-composable-stable-pool-v3' };
    let priceFeedUpdateData: string[];
	before(async () => {
		[owner, user1, user2, user3] = await ethers.getSigners();
		_deployments = JSON.parse((await fs.readFile(path.join(__dirname + "/../../abi/ABI.json"))).toString())

		deployments = await loadFixture(main);

		eth = deployments.pools[0].collateralTokens[0];
		pool = deployments.pools[0].pool;

		ceth = deployments.pools[0].synths[1];
		cusd = deployments.pools[0].synths[2];

		poolFactory = new ethers.Contract(STABLE_FACTORY, _deployments["ComposableStablePoolFactory"], provider);

		vault = new ethers.Contract(VAULT, _deployments["Balancer_Vault"], provider);
		// console.log(vault.address);

		weth = new ethers.Contract(MANTLE_ADDRESS, _deployments["WETH9"], provider);

		usdc = new ethers.Contract(USDC_ADDRESS, _deployments["ERC20X"], provider);
		// console.log(await hre.ethers.provider.getBlockNumber())
        console.log(ceth.address);

        const pythPriceService = new EvmPriceServiceConnection('https://xc-testnet.pyth.network');

        priceFeedUpdateData = await pythPriceService.getPriceFeedsUpdateData([
            "0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722",
            "0x0e9ec6a3f2fba0a3df73db71c84d736b8fc1970577639c9456a2fee0c8f66d93",
            "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6",
            "0x1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588",
            "0xecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a",
            "0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b",
            "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6",
            "0xbfaf7739cb6fe3e1c57a0ac08e1d931e9e6062d476fa57804e165ab572b5b621",
            "0xafcc9a5bb5eefd55e12b6f0b4c8e6bccf72b785134ee232a5d175afd082e8832",
            "0xa29b53fbc56604ef1f2b65e89e48b0f09bb77b3fb890f4c70ee8cbd68a12a94b",
            "0xabb1a3382ab1c96282e4ee8c847acc0efdb35f0564924b35f3246e8f401b2a3d",
            "0x4e10201a9ad79892f1b4e9a468908f061f330272c7987ddc6506a254f77becd7",
          ]);
      
	});
    

	it("should create eth-ceth stable pair", async () => {

		mockPoolArgs = {
			vault: VAULT,
			protocolFeeProvider: PROTOCOL_FEE_PROVIDER,
			name: 'DO NOT USE - Mock Composable Stable Pool',
			symbol: 'TEST',
			tokens: [MANTLE_ADDRESS, ceth.address].sort(function (a, b) {
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
		// console.log("balancerPoolAddress", balancerPoolAddress)
		expect(balancerPoolAddress).length(42);
		balancerPool = new ethers.Contract(balancerPoolAddress, _deployments["ComposableStablePool"], provider);

		banalcerPoolId = await balancerPool.connect(user1).callStatic.getPoolId();

		expect(banalcerPoolId).length(66);
		// console.log(banalcerPoolId, "poolId");

	});
    /*
	it("Mint Tokens", async () => {
		// deposit eth in synthex pool.

		const deposit = pe("100");
		const mintAmount = pe("50");
		await pool.connect(user2).depositETH(user2.address, { value: deposit });
		// minth cETH
		await pool.connect(user2).mint(ceth.address, mintAmount, user2.address);

		await pool.connect(user3).depositETH(user3.address, { value: deposit });
		// minth cETH
		await pool.connect(user3).mint(ceth.address, mintAmount, user3.address)

		// const user2Liquidity = await pool.getAccountLiquidity(user2.address);
		// const user3Liquidity = await pool.getAccountLiquidity(user3.address);
		const user2EthBalance = (await ceth.connect(user2).balanceOf(user2.address)).toString();
		const user3EthBalance = (await ceth.connect(user3).balanceOf(user3.address)).toString();
		expect(user2EthBalance).to.equal(mintAmount);
		expect(user3EthBalance).to.equal(mintAmount);

	});


	it("approve contracts", async () => {
		const approveAmount = pe("1000000000000");
		//approve pool
		await ceth.connect(user2).approve(pool.address, approveAmount);
		await weth.connect(user2).approve(pool.address, approveAmount);

		//approve balancerPool
		await ceth.connect(user2).approve(balancerPoolAddress, approveAmount);
		await weth.connect(user2).approve(balancerPoolAddress, approveAmount);

		//approve vault
		await ceth.connect(user2).approve(VAULT, approveAmount);
		await weth.connect(user2).approve(VAULT, approveAmount);

		///////////////////////////////////////////////////////////////////
		//approve pool
		await ceth.connect(user3).approve(pool.address, approveAmount);
		await weth.connect(user3).approve(pool.address, approveAmount);

		//approve balancerPool
		await ceth.connect(user3).approve(balancerPoolAddress, approveAmount);
		await weth.connect(user3).approve(balancerPoolAddress, approveAmount);

		//approve vault
		await ceth.connect(user3).approve(VAULT, approveAmount);
		await weth.connect(user3).approve(VAULT, approveAmount);

		/////////////////////////////////////////////////////
		//approve pool
		await ceth.connect(user1).approve(pool.address, approveAmount);
		await weth.connect(user1).approve(pool.address, approveAmount);

		//approve balancerPool
		await ceth.connect(user1).approve(balancerPoolAddress, approveAmount);
		await weth.connect(user1).approve(balancerPoolAddress, approveAmount);

		//approve vault
		await ceth.connect(user1).approve(VAULT, approveAmount);
		await weth.connect(user1).approve(VAULT, approveAmount);
	});

	it("join pool first time", async () => {

		poolTokens = (await vault.connect(user2).getPoolTokens(banalcerPoolId))[0];

		await weth.connect(user2).deposit({ value: pe(20) });

		let joinPoolTx = await (await vault.connect(user2).joinPool(
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
						0,                           // for first time use 0 and in below array add one more element for pool token
						[pe(1), pe(10), pe(10)],     // length without pool token
					]),
				fromInternalBalance: false

			}
		)
		).wait(1);

		expect(joinPoolTx.events[joinPoolTx.events.length - 1].args[3][1].toString()).to.equal(pe(10));
		expect(joinPoolTx.events[joinPoolTx.events.length - 1].args[3][2].toString()).to.equal(pe(10));
	});

	it("join pool, EXACT_TOKENS_IN_FOR_BPT_OUT", async () => {
		const MAX_AMOUNT = pe('100000000000000000000000');
		const joinAmount = pe(50);
		await weth.connect(user3).deposit({ value: joinAmount });

		let joinPoolTx = await (await vault.connect(user3).joinPool(
			banalcerPoolId,
			user3.address,
			user3.address,
			{
				assets: poolTokens,
				maxAmountsIn: [                     // length include pool token
					MAX_AMOUNT,
					MAX_AMOUNT,
					MAX_AMOUNT,
				],
				userData: ethers.utils.defaultAbiCoder.encode(
					['uint256', 'uint256[]', 'uint256'],
					[
						1,                            // for first time use 0 and in below array add one more element for pool token
						[joinAmount, joinAmount],     // length without pool token
						0
					]),
				fromInternalBalance: false

			}
		)).wait(1);
		// console.log(joinPoolTx.events[joinPoolTx.events.length -1].args);
		expect(joinPoolTx.events[joinPoolTx.events.length - 1].args[3][1].toString()).to.equal(joinAmount);
		expect(joinPoolTx.events[joinPoolTx.events.length - 1].args[3][2].toString()).to.equal(joinAmount);
	})

	it("it sould batchSwap ", async () => {
		const amountIn = pe(0.5);
		await weth.connect(user1).deposit({ value: amountIn });
		// Get initial balances
		let initialWethBalance = await weth.connect(user1).balanceOf(user1.address);
		let initialCethBalance = await ceth.connect(user1).balanceOf(user1.address);

		// Perform batch swap
		let batchSwapTx = await (await vault.connect(user1).batchSwap(
			0,
			[
				{
					poolId: banalcerPoolId,
					assetInIndex: 1,
					assetOutIndex: 2,
					amount: amountIn,
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
			['0', amountIn, pe(-0.49)],
			1689740240
		)).wait(1);

		// console.log(batchSwapTx.events[0].args);
		// Get final balances
		let finalWethBalance = await weth.connect(user1).balanceOf(user1.address);
		let finalCethBalance = await ceth.connect(user1).balanceOf(user1.address);

		// Check that the balances changed as expected
		expect(finalWethBalance.sub(initialWethBalance)).to.equal(`${-batchSwapTx.events[0].args[3].toString()}`);
		expect(finalCethBalance.sub(initialCethBalance)).to.equal(`${batchSwapTx.events[0].args[4].toString()}`);
	})

	it("It should swap in router for balancer", async () => {

		const amountIn = pe(1);
		await weth.connect(user1).deposit({ value: amountIn });

		router = await routerMain(weth.address, vault.address, true);
		//approve router
		await weth.connect(user1).approve(router.address, pe('1'));

		await ceth.connect(user1).approve(router.address, pe("0.3"));

		const deadline = Math.round(Date.now() / 1000 + 60 * 60);

		let initialAssetInBalance = await weth.connect(user1).balanceOf(user1.address);
		let initialAssetOutBalance = await usdc.connect(user1).balanceOf(user1.address);
		
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
								"amount": amountIn
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

				"funds": {
					"sender": user1.address,
					"recipient": user1.address,
					"fromInternalBalance": false,
					"toInternalBalance": false
				},

				"deadline": deadline,
			}
		)).wait(1);

		// Get final balances
		let finalAssetInBalance = await weth.connect(user1).balanceOf(user1.address);
		let finalAssetOutBalance = await usdc.connect(user1).balanceOf(user1.address);
		// expect(finalAssetOutBalance.sub(initialAssetOutBalance)).to.be.gt(0);
	});

	it("It should swap in router for synthex pool", async () => {

		let initialAssetInBalance = await ceth.connect(user1).balanceOf(user1.address);
		let initialAssetOutBalance = await cusd.connect(user1).balanceOf(user1.address);
		const swap = await (await router.connect(user1).swap(
			{
				"kind": 0,
				"swaps": [
					{
						"swap": [
							{
								"poolId": "0x000000000000000000000000bbb3abfa2dd320d85c64e8825c1e32ad0026fae5",
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
				"funds": {
					"sender": user1.address,
					"recipient": user1.address,
					"fromInternalBalance": false,
					"toInternalBalance": false
				},
				"deadline": 1692683960,
			}
		)).wait(1);

		// Get final balances
		let finalAssetInBalance = await ceth.connect(user1).balanceOf(user1.address);
		let finalAssetOutBalance = await cusd.connect(user1).balanceOf(user1.address);
		// Check that the balances changed as expected
		expect(finalAssetInBalance.sub(initialAssetInBalance)).to.equal("-300000000000000000");
		expect(finalAssetOutBalance.sub(initialAssetOutBalance)).to.be.gt(0);

	})
	it("It should swap in router for synthex with permit", async () => {

		const domain = {
			name: await ceth.name(),
			version: "1",
			chainId: hre.network.config.chainId,
			verifyingContract: ceth.address,
		};

		const Permit = [
			{ name: "owner", type: "address" },
			{ name: "spender", type: "address" },
			{ name: "value", type: "uint256" },
			{ name: "nonce", type: "uint256" },
			{ name: "deadline", type: "uint256" },
		];

		const deadline = Math.round(Date.now() / 1000 + 60 * 60);
	
		const permit = {
			owner: user1.address,
			spender: router.address,
			value: "100000000000000000",
			nonce: (await ceth.nonces(user1.address)).toHexString(),
			deadline,
		};

		const signature = await user1._signTypedData(domain, { Permit }, permit);
		const { v, r, s } = ethers.utils.splitSignature(signature);
		

		const swapDatas = {
			"kind": 0,
			"swaps": [
				{
					"swap": [
						{
							"poolId": "0x000000000000000000000000bbb3abfa2dd320d85c64e8825c1e32ad0026fae5",
							"assetInIndex": 0,
							"assetOutIndex": 1,
							"userData": "0x",
							"amount": "100000000000000000"
						}
					],
					"isBalancerPool": false,
					"limits": [
						"100000000000000000",
						"0"
					],
					"assets": [
						"0xa28d78534d18324da06fc487041b1ab4a16d557d",
						"0xe379874446dd29178e68852992daa80be952c0b3"
					]
				}
			],
			"funds": {
				"sender": user1.address,
				"recipient": user1.address,
				"fromInternalBalance": false,
				"toInternalBalance": false
			},
			"deadline": deadline,
		};
		const itf = new ethers.utils.Interface(_deployments["Router"]);

		const permitArgs = ["100000000000000000", deadline, "0xa28d78534d18324da06fc487041b1ab4a16d557d", { v, r, s }];

		const data = [
			router.interface.encodeFunctionData("permitRouter", permitArgs),
			router.interface.encodeFunctionData("swap", [swapDatas]),
		];
		let initialAssetInBalance = await ceth.connect(user1).balanceOf(user1.address);
		let initialAssetOutBalance = await cusd.connect(user1).balanceOf(user1.address);

		const resp = await (await router.connect(user1).multicall(data)).wait(1);

		// Get final balances
		let finalAssetInBalance = await ceth.connect(user1).balanceOf(user1.address);
		let finalAssetOutBalance = await cusd.connect(user1).balanceOf(user1.address);

		// Check that the balances changed as expected
		expect(finalAssetInBalance.sub(initialAssetInBalance)).to.equal("-100000000000000000");
		expect(finalAssetOutBalance.sub(initialAssetOutBalance)).to.be.gt(0);
		// // console.log(resp);
		// console.log("csdc", await cusd.connect(user1).balanceOf(user1.address));
		// console.log("ceth", await ceth.connect(user1).balanceOf(user1.address));
	})*/

});

