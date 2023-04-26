import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import hre from 'hardhat';
import fs from 'fs';
import { ETH_ADDRESS } from '../../deploy/utils/const';
import { EvmPriceServiceConnection } from '@pythnetwork/pyth-evm-js';

import deployOracle from "../../tasks/pools/oracle/pyth"

describe("Testing the complete flow", function () {

	let cryptoPool: any, weth: any, cusd: any, cbtc: any, ceth: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await main(false);
        cryptoPool = deployments.pools[0].pool;
        cbtc = deployments.pools[0].synths[0];
        ceth = deployments.pools[0].synths[1];
        cusd = deployments.pools[0].synths[2];
	});

	it("create pyth oracle", async function () {
        // if(hre.network.name === 'hardhat') {
        //     return;
        // }
        const config = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/5/config.json`, "utf8"));
        const deployments = JSON.parse(fs.readFileSync(process.cwd() + `/deployments/5/deployments.json`, "utf8"));

        const assets = [];
        const feeds = [];
		for(let i in config.pools[0].collaterals){
            const feed = config.pools[0].collaterals[i].pyth;
            if(feed){
                let asset = config.pools[0].collaterals[i].address;
                if (asset == ETH_ADDRESS) asset = config.weth;
                assets.push(asset);
                feeds.push(feed.feedId);
            }
        }
        for(let i in config.pools[0].synths){
            const feed = config.pools[0].synths[i].pyth;
            if(feed){
                assets.push(deployments.contracts[config.pools[0].symbol.toLowerCase() + config.pools[0].synths[i].symbol].address);
                feeds.push(feed.feedId);
            }
        }

        console.log(feeds);

        const pythOracle = await deployOracle(
            cryptoPool,
            "0xff1a0f4744e8582DF1aE09D5611b887B6a12925C",
            assets,
            feeds,
            ethers.constants.AddressZero,
            cusd.address,
            ethers.utils.parseUnits("1", 8).toString(),
            false
        );

        console.log("PythOracle deployed at", pythOracle.address);

        const resp = await pythOracle.getAssetsPrices(
            [cusd.address, ceth.address, cbtc.address]
        );

        console.log(resp);


	});
});