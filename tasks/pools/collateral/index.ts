import { ethers } from "hardhat";
import { CollateralArgs } from "../../../deployments/types";
import main from "./main";

const cConfig: CollateralArgs = {
    name: "Lodestar USD Coin",
    symbol: "lUSDC",
    decimals: 18,
    address: "0x605a9d845B9ab16675Db2713F30C5134BFf5e055",
    params: {
        cap: "100000000000000000000000",
        baseLTV: 7000,
        liqThreshold: 8500,
        liqBonus: 10200
    },
    price: null,
    isNew: false,
    isCToken: true,
    isAToken: false,
    poolAddressesProvider: null,
    isFeedSecondary: false,
    secondarySource: null,
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

index(cConfig, "0x685CD63b437b3A97271Ad351C4110333b17171c2", "0x4c6c8BF00017545711A6bC26B0f8040190A356e8");
