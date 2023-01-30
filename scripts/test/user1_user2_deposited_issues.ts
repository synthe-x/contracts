import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, Contract } from 'ethers';
import { ETH_ADDRESS } from "../utils/const";
import deploy from "./";
import { IDeploymentResult } from '../deploy';

/**
 * @dev user1 issues n1 eth
 * @dev user2 issues n2 btc
 * @dev user3 issues n3 usd
 */
export default async function main(deployer: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress, synthex: Contract, pool: Contract, seth: Contract, sbtc: Contract, susd: Contract) {
    
    
}