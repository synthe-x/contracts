import { ethers } from "hardhat";
import { POOL_ADDRESS_PROVIDER } from "../utils/const";

export async function deploy() {
    const SpotFactory = await ethers.getContractFactory("Spot");
    const spot = await SpotFactory.deploy(POOL_ADDRESS_PROVIDER, ethers.constants.AddressZero);

    return {spot};
}
