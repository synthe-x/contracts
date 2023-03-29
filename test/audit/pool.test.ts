import type { SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers";
import { takeSnapshot } from "@nomicfoundation/hardhat-network-helpers";
import{ time } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import web3 from "web3"
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import type { Pool } from "../typechain-types";
import type { ERC20Mock } from "../typechain-types";
import type { SyntexMock } from "../typechain-types";
import type { OracleMock } from "../typechain-types";
import type { ERC20X } from "../typechain-types";
import { parseEther } from "ethers/lib/utils";
import { BigNumber } from "ethers";



const KECCAK256 = web3.utils.soliditySha3

const DAY = 24*60*60


describe.only("Pool", function () {
    let snapshotA: SnapshotRestorer;

    // Signers.
    let deployer: SignerWithAddress, owner: SignerWithAddress;
    let user_1: SignerWithAddress;
    let user_2: SignerWithAddress;
    let pool: Pool;
    let erc20: ERC20Mock;
    let erc20_2: ERC20Mock;
    let paymentToken: ERC20Mock;
    let erc20X: ERC20X
    let syntex: SyntexMock;
    let oracle: OracleMock;

    let signers, users

    let usersMerkleProofs, leaves, usersAddresses
    
    const ERC_20_PRICE = 1e8 // 1 USD
    const USD_DECIMALS = 1e8
    const BASE_POINTS = 10000
    

    before(async () => {
        // Getting of signers.
        
        const USER_NUMBER = 10
        signers = await ethers.getSigners();
        deployer = signers[0]
        users = signers.slice(1,USER_NUMBER + 1)
        user_1 = users[0]
        user_2 = users[1]

        //
    
        const ERC20Mock = await ethers.getContractFactory("ERC20Mock", deployer);
        erc20 = await ERC20Mock.deploy()
        await erc20.deployed();

        erc20_2 = await ERC20Mock.deploy()
        await erc20_2.deployed();

        const OracleMock = await ethers.getContractFactory("OracleMock", deployer)
        oracle = await OracleMock.deploy()
        await oracle.deployed()

        paymentToken = await ERC20Mock.deploy()
        await paymentToken.deployed();

        const SyntexMock = await ethers.getContractFactory("SyntexMock", deployer);
        syntex = await SyntexMock.deploy()
        await syntex.deployed();


        //
        const Pool = await ethers.getContractFactory("Pool", deployer)
        pool = await upgrades.deployProxy(Pool, [
            "Pool name",// string memory _name,
            "SMBL",// string memory _symbol,
            syntex.address// address _synthex
        ])

        const ERC20X = await ethers.getContractFactory("ERC20X", deployer)
        erc20X = await upgrades.deployProxy( ERC20X,
            [
                "ERC20X", // string memory _name,
                "ERC20x",// string memory _symbol,
                pool.address,// address _pool,
                syntex.address// address _synthex
            ],
            { unsafeAllow: ['delegatecall'] }

        )

        await pool.setPriceOracle(oracle.address)
        
        await oracle.setPrice(erc20.address, ERC_20_PRICE)

        snapshotA = await takeSnapshot();
    });

    afterEach(async () => await snapshotA.restore());

    describe("", async() => {
        
        describe("enterCollateral", function () {
            it("user can enter collateral", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   

                expect(await pool.connect(user_1).enterCollateral(erc20.address))
                    .to.emit(pool, "CollateralEntered")
                    .withArgs(user_1.address, erc20.address)

                expect(await pool.accountMembership(erc20.address, user_1.address))
                    .to.be.true
            })
            it("user cannot enter collateral twice", async () =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
                await pool.connect(user_1).enterCollateral(erc20.address)
                 
                await expect(pool.connect(user_1).enterCollateral(erc20.address))
                    .to.be.revertedWith("5")
                 
            })
            it("cannot enter not acitve  collateral", async() =>{
                await expect( pool.connect(user_1).enterCollateral(erc20.address))
                    .to.be.revertedWith("10")
            
            })
            it.skip("user can exit collateral", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
                await pool.connect(user_1).enterCollateral(erc20.address)

                await pool.connect(user_1).exitCollateral(erc20.address)
    
            })
        })
        describe("deposit", async() =>{
            it("user can deposit collateral", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
    
                await pool.connect(user_1).enterCollateral(erc20.address)
                
                const AMOUNT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await pool.unpause()
    
                expect(await pool.connect(user_1).deposit(erc20.address, AMOUNT))
                    .to.emit(pool, "Deposit").withArgs(user_1.address, erc20.address, AMOUNT)
            })
            it("user cannot deposit while contract on pause", async() =>{
                const AMOUNT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await expect(pool.connect(user_1).deposit(erc20.address, AMOUNT))
                    .to.be.revertedWith("Pausable: paused") 
            })
            it("user can deposit collateral he hasn't entered", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
    
                const AMOUNT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await pool.unpause()
    
                expect(await pool.connect(user_1).deposit(erc20.address, AMOUNT))
                    .to.emit(pool, "Deposit").withArgs(user_1.address, erc20.address, AMOUNT)
            })
            it("user cannot deposit when collateral has exceeded capacity", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
    
                const AMOUNT = parseEther("2")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await pool.unpause()
                await expect(pool.connect(user_1).deposit(erc20.address, AMOUNT))
                    .to.be.revertedWith("8")
            })
    
        })
        describe("withdraw", function () {
            it("user can withdraw collateral", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
    
                await pool.connect(user_1).enterCollateral(erc20.address)
                
                const AMOUNT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await pool.unpause()
    
                await pool.connect(user_1).deposit(erc20.address, AMOUNT)
                //
                await pool.connect(user_1).withdraw(erc20.address, AMOUNT)

                expect(await erc20.balanceOf(user_1.address)).to.be.eq(AMOUNT)

            })
            it("!!!CRITICAL!!! user cannot withdraw collateral he doesn't own", async() =>{
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
                await pool.connect(user_1).enterCollateral(erc20.address)
                
                const AMOUNT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await pool.unpause()
    
                await pool.connect(user_1).deposit(erc20.address, AMOUNT)
                //
                await pool.connect(user_2).withdraw(erc20.address, AMOUNT)
                // await expect(pool.connect(user_2).withdraw(erc20.address, AMOUNT))
                //     .to.be.reverted
                console.log("HAS TO BE ZERO", await erc20.balanceOf(user_2.address))
            })
        })
        describe("mint", function () {
            it.skip("user can mint", async() =>{
                // await pool.unpause()
                //deposit collateral
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : 8000,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
                await pool.connect(user_1).enterCollateral(erc20.address)
                const AMOUNT_TO_DEPOSIT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT_TO_DEPOSIT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT_TO_DEPOSIT)
                await pool.unpause()
                await pool.connect(user_1).deposit(erc20.address, AMOUNT_TO_DEPOSIT)
                    
                const MINT_FEE = 0
                const BURN_FEE = 0
                await pool.addSynth(erc20X.address, MINT_FEE, BURN_FEE)

                const AMOUNT = parseEther("1")
                const RECIPIENT = user_1.address
                const REFERED_BY = ethers.constants.AddressZero
                
                await erc20X.connect(user_1).mint(AMOUNT, RECIPIENT, REFERED_BY)

            })
            it("cannot mint with insufficient  user collateral", async() =>{
                await pool.unpause()
                const MINT_FEE = 0
                const BURN_FEE = 0
                await pool.addSynth(erc20X.address, MINT_FEE, BURN_FEE)

                const AMOUNT = parseEther("1")
                const RECIPIENT = user_1.address
                const REFERED_BY = ethers.constants.AddressZero
                
                await expect(erc20X.connect(user_1).mint(AMOUNT, RECIPIENT, REFERED_BY))
                    .to.be.revertedWith("6") 
            })
        })
        describe("getAccountLiquidity", function() {
            it("getAccountLiquidity", async() =>{
                const BASE_LTV = 8000
                
                await pool.updateCollateral(
                    erc20.address, 
                    {
                        isActive : true,
                        cap : parseEther("1000"),
                        totalDeposits : parseEther("1000"),
                        baseLTV : BASE_LTV,
                        liqThreshold : 9000,
                        liqBonus : 10000 // 0
                    }
                )   
    
                await pool.connect(user_1).enterCollateral(erc20.address)
                
                const AMOUNT = parseEther("1")
                await erc20.mint(user_1.address, AMOUNT )
                await erc20.connect(user_1).increaseAllowance(pool.address, AMOUNT)
                await pool.unpause()
    
                await pool.connect(user_1).deposit(erc20.address, AMOUNT)
                    
                // console.log("accountCollateralBalance",
                //     ethers.utils.formatEther(await pool.accountCollateralBalance(user.address, erc20.address))
                // )
                
                // console.log("accountCollateralBalance calculated",
                //     ethers.utils.formatEther(AMOUNT.mul(ERC_20_PRICE).div(USD_DECIMALS))
                // )

                let res = await pool.getAccountLiquidity(user_1.address)
                
                expect(ethers.utils.formatEther(res.collateral))
                    .to.be.eq(ethers.utils.formatEther(
                        AMOUNT
                            .mul(ERC_20_PRICE).div(USD_DECIMALS)
                    )
                    )

                expect(res.liquidity)
                    .to.be.eq(
                        AMOUNT
                            .mul(BASE_LTV).div(BASE_POINTS)
                            .mul(ERC_20_PRICE).div(USD_DECIMALS)
                    )
                // int256 liquidity;
                // uint256 collateral;
                // uint256 debt;
            })
        })

    })
})