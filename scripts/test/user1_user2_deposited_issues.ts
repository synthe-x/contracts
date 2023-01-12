import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "ethers";
import { ETH_ADDRESS } from "../utils/const";
import deploy from "./index";

/**
 * @dev user1 issues n1 eth
 * @dev user2 issues n2 btc
 * @dev user3 issues n3 usd
 */
export default async function main(deployerAddress: string, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress) {
    const deployments = await deploy(deployerAddress);
    const { synthex, pool, seth, sbtc, susd } = deployments;

    await synthex.connect(user1).enterAndDeposit(ETH_ADDRESS, ethers.utils.parseEther("100"), {value: ethers.utils.parseEther("100")});
    await synthex.connect(user2).enterAndDeposit(ETH_ADDRESS, ethers.utils.parseEther("100"), {value: ethers.utils.parseEther("100")});
    await synthex.connect(user3).enterAndDeposit(ETH_ADDRESS, ethers.utils.parseEther("100"), {value: ethers.utils.parseEther("100")});

    await synthex.connect(user1).enterAndIssue(pool.address, seth.address, ethers.utils.parseEther("25")); // $ 25000
    await synthex.connect(user2).enterAndIssue(pool.address, sbtc.address, ethers.utils.parseEther("2.5")); // $ 25000
    await synthex.connect(user3).enterAndIssue(pool.address, susd.address, ethers.utils.parseEther("25000")); // $ 25000

    return deployments;
}