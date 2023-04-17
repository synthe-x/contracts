import { ethers } from "hardhat";
import { CollateralArgs } from "../../../deployments/types";
import main from "./main";

const cConfig: CollateralArgs = {
    "name": "USD Coin",
    "symbol": "USDC",
    "decimals": 18,
    "feed": "0x1692Bdd32F31b831caAc1b0c9fAF68613682813b",
    "params": {
        "cap": "100000000000000000000000",
        "baseLTV": 7000,
        "liqThreshold": 8500,
        "liqBonus": 10200
    },
    price: null,
    isNew: false,
    isCToken: false,
    isAToken: false,
    poolAddressesProvider: null,
    isFeedSecondary: false,
    secondarySource: null,
    address: null
};

async function index(cConfig: CollateralArgs, oracleAddress: string, poolAddress: string) {

    // get oracle contract
	const Oracle = await ethers.getContractFactory("PriceOracle");
	const oracle = Oracle.attach(oracleAddress);
    
	// get pool contract
	const Pool = await ethers.getContractFactory("Pool");
	const pool = Pool.attach(poolAddress);
    
    main(cConfig, oracle, pool);
}

index(cConfig, "0x0D909F54332fe2003b6eF779FB7C8a3c5b1b9b6f", "0x705A774d9542bfd793A2b74bec245028aD6F0042");
