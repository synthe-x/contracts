import type { SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers";
import { takeSnapshot } from "@nomicfoundation/hardhat-network-helpers";
import{ time } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import web3 from "web3"
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import type { Pool } from "../../typechain-types";
import type { ERC20Mock } from "../../typechain-types";
import type { SyntexMock } from "../../typechain-types";
import type { OracleMock } from "../../typechain-types";
import type { ERC20X } from "../../typechain-types";
import type { SyntheX } from "../../typechain-types";
import { parseEther } from "ethers/lib/utils";
import { BigNumber } from "ethers";

const DAY = 24*60*60
const toEther = ethers.utils.formatEther

describe("Pool", function () {
    let snapshotA: SnapshotRestorer;

    // Signers.
    let deployer: SignerWithAddress, owner: SignerWithAddress;
    let user_1: SignerWithAddress;
    let user_2: SignerWithAddress;
    let referee: SignerWithAddress;
    let vault: SignerWithAddress;
    let pool: Pool;
    let erc20: ERC20Mock;
    let erc20_2: ERC20Mock;
    let paymentToken: ERC20Mock;
    let erc20X: ERC20X;
    let feeToken: ERC20X;
    // let syntex: SyntexMock;
    let synteX: SyntheX;
    let oracle: OracleMock;

    let signers, users

    let usersMerkleProofs, leaves, usersAddresses
    
    const ERC_20_PRICE = 1e8 
    const ERC_20_X_PRICE = 5e8
    const FEE_TOKEN_PRICE = 5e8
    const USD_DECIMALS = 1e8
    const BASE_POINTS = 10000

    const VAULT_KECCAK256 = "0x68fc488efe30251cadb6ac88bdeef3f1a5e6048808baf387258d1d78e986720c"
    

    before(async () => {
        // Getting of signers.
        
        const USER_NUMBER = 10
        signers = await ethers.getSigners();
        deployer = signers[0]
        users = signers.slice(1,USER_NUMBER + 1)
        user_1 = users[0]
        user_2 = users[1]
        referee = signers[USER_NUMBER + 2]
        vault = signers[USER_NUMBER + 3]
    
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

        const SyntheX = await ethers.getContractFactory("SyntheX");
        synteX = (await upgrades.deployProxy(SyntheX,
             [deployer.address, deployer.address, deployer.address])) as SyntheX;

        //set vault for Syntex
        await synteX.setAddress(VAULT_KECCAK256, vault.address )

        const Pool = await ethers.getContractFactory("Pool", deployer)
        pool = await upgrades.deployProxy(Pool, [
            "Pool name",// string memory _name,
            "SMBL",// string memory _symbol,
            synteX.address// address _synthex
        ]) as Pool

        const ERC20X = await ethers.getContractFactory("ERC20X", deployer)
        erc20X = await upgrades.deployProxy( ERC20X,
            [
                "ERC20X", // string memory _name,
                "ERC20x",// string memory _symbol,
                pool.address,// address _pool,
                synteX.address// address _synthex
            ],
            { unsafeAllow: ['delegatecall'] }
        ) as ERC20X

        feeToken = await upgrades.deployProxy( ERC20X,
            [
                "ERC20X", // string memory _name,
                "ERC20x",// string memory _symbol,
                pool.address,// address _pool,
                synteX.address// address _synthex
            ],
            { unsafeAllow: ['delegatecall'] }
        ) as ERC20X

        await pool.setFeeToken(feeToken.address)

        await pool.setPriceOracle(oracle.address)
        
        await oracle.setPrice(erc20.address, ERC_20_PRICE)
        

        await oracle.setPrice(erc20X.address, ERC_20_X_PRICE)
        await oracle.setPrice(feeToken.address, FEE_TOKEN_PRICE)

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
            it("user can mint", async() =>{
                //setup collareal
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
                
                //deposit collateral
                await pool.connect(user_1).deposit(erc20.address, AMOUNT_TO_DEPOSIT)
                    
                const MINT_FEE = 0
                const BURN_FEE = 0
                await pool.addSynth(erc20X.address, MINT_FEE, BURN_FEE)

                const AMOUNT = parseEther("100000")
                const RECIPIENT = user_1.address
                          
                await erc20X.connect(user_1).mint(AMOUNT, RECIPIENT, referee.address)
                console.log(toEther(await pool.balanceOf(user_1.address)))
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