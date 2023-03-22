import type { SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers";
import { takeSnapshot } from "@nomicfoundation/hardhat-network-helpers";
import{ time } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers } from "hardhat";
import web3 from "web3"
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import type { Pool } from "../typechain-types";
import type { ERC20Mock } from "../typechain-types";
import type { SyntexMock } from "../typechain-types";
import { parseEther } from "ethers/lib/utils";



const KECCAK256 = web3.utils.soliditySha3

const DAY = 24*60*60


describe.only("Pool", function () {
    let snapshotA: SnapshotRestorer;

    // Signers.
    let deployer: SignerWithAddress, owner: SignerWithAddress, user: SignerWithAddress;

    let pool: Pool;
    let erc20: ERC20Mock;
    let paymentToken: ERC20Mock;
    let syntex: SyntexMock;

    let signers, users

    let usersMerkleProofs, leaves, usersAddresses

    before(async () => {
        // Getting of signers.
        [deployer, user] = await ethers.getSigners();
        //
        const USER_NUMBER = 10
        signers = await ethers.getSigners();
        deployer = signers[0]
        users = signers.slice(1,USER_NUMBER + 1)
        //
    
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock", deployer);
        erc20 = await ERC20Mock.deploy()
        await erc20.deployed();

        paymentToken = await ERC20Mock.deploy()
        await paymentToken.deployed();

        const SyntexMock = await ethers.getContractFactory("SyntexMock", deployer);
        syntex = await SyntexMock.deploy()
        await syntex.deployed();

        snapshotA = await takeSnapshot();
    });

    afterEach(async () => await snapshotA.restore());
    describe("", async() =>{
 
    })
    
});