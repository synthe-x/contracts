import { ethers } from "hardhat";
import { CollateralArgs } from "../../../deployments/types";
import main from "./main";

const cConfig: CollateralArgs = {
    name: "Lodestar USD Coin",
    symbol: "lUSDC",
    decimals: 18,
    address: "0x7b571111dAFf9428f7563582242eD29E5949970e",
    params: {
        cap: "100000000000000000000000",
        baseLTV: 6000,
        liqThreshold: 8800,
        liqBonus: 10200
    },
    price: null,
    isNew: false,
    isCToken: true,
    isAToken: false,
    poolAddressesProvider: null,
    isFeedSecondary: false,
    secondarySource: null,
    feed: null
};

async function index(cConfig: CollateralArgs, oracleAddress: string, poolAddress: string) {

    // get oracle contract
	const Oracle = await ethers.getContractFactory("PriceOracle");
	const oracle = Oracle.attach(oracleAddress);
    
	// get pool contract
	const pool = await ethers.getContractAt("Pool", poolAddress);
    
    const result = await main(cConfig, pool);
    if(result.feed){
        // await oracle.setAssetSources([result.collateral.address], [result.feed.address]);
        console.log([result.collateral.address], [result.feed.address]);
    }
}

index(cConfig, "0x42E67C879DE46086A175eC5C2760DaF78F75045D", "0x8d6E834277E4f513BacF83B0A87524c913eF8691");
