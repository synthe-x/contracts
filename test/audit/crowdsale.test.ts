import type { SnapshotRestorer } from "@nomicfoundation/hardhat-network-helpers";
import { takeSnapshot } from "@nomicfoundation/hardhat-network-helpers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import web3 from "web3"
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import type { Crowdsale } from "../../typechain-types";
import type { ERC20Mock } from "../../typechain-types";
import type { SyntexMock } from "../../typechain-types";
import { parseEther } from "ethers/lib/utils";

const { MerkleTree } = require('merkletreejs')

const KECCAK256 = web3.utils.soliditySha3

const DAY = 24 * 60 * 60
const ETHER_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
const ETHER_RATE = parseEther("1")
const PAYMENT_TOKEN_RATE = parseEther("1")
const DECIMALS = parseEther("1")
const INVALID_PROOF =
    [
        '0x4306ceff26c1e104939fabc1d917760e45551281e46ed897561f29a31ef875f3',
        '0x11b8eb5570cba0bb401776e0de86c277b085e62cf3c1503934bf88e34c710eea'
    ]
let ROOT: any

describe("Crowdsale", function () {
    let snapshotA: SnapshotRestorer;

    // Signers.
    let deployer: SignerWithAddress, owner: SignerWithAddress, user: SignerWithAddress;

    let crowdsale: Crowdsale;
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
        users = signers.slice(1, USER_NUMBER + 1)
        usersAddresses = users.map(x => x.address)

        leaves = usersAddresses.map(x => KECCAK256(x))

        const tree = new MerkleTree(leaves, KECCAK256, { sortPairs: true })
        ROOT = "0x" + tree.getRoot().toString('hex')

        usersMerkleProofs = leaves.map(x => tree.getHexProof(x))
        //

        const ERC20Mock = await ethers.getContractFactory("ERC20Mock", deployer);
        erc20 = await ERC20Mock.deploy()
        await erc20.deployed();

        paymentToken = await ERC20Mock.deploy()
        await paymentToken.deployed();

        const SyntexMock = await ethers.getContractFactory("SyntexMock", deployer);
        syntex = await SyntexMock.deploy()
        await syntex.deployed();


        // Deployment of the factory.
        const Crowdsale = await ethers.getContractFactory("Crowdsale", deployer);
        const START_TIME = (await ethers.provider.getBlock("latest")).timestamp + DAY

        crowdsale = await upgrades.deployProxy( 
            Crowdsale,
            [
                syntex.address,// address _synthex, 
                erc20.address,// address _token, 
                START_TIME,// uint256 _startTime, 
                START_TIME + DAY * 10,// uint256 _endTime, 
                DAY,// uint256 _lockPeriod, 
                DAY,// uint256 _unlockPeriod, 
                10,// uint256 _percUnlockAtRelease, 
                ROOT,// bytes32 _merkleRoot, 
                DAY,// uint256 _whitelistDuration, 
                parseEther("10")// uint256 _whitelistCap 
            ]
        ) as Crowdsale;
        await crowdsale.deployed();

        // price for token in ether
        await crowdsale.updateRate(ETHER_ADDRESS, ETHER_RATE)

        await crowdsale.updateRate(paymentToken.address, PAYMENT_TOKEN_RATE)

        await erc20.mint(crowdsale.address, parseEther("20"))

        owner = deployer;

        snapshotA = await takeSnapshot();
    });

    afterEach(async () => await snapshotA.restore());
    describe("constructor", async () => {
        it("start time cannot be in in the past", async () => {

            const Crowdsale = await ethers.getContractFactory("Crowdsale", deployer);
            const START_TIME = (await ethers.provider.getBlock("latest")).timestamp - DAY

            await expect(
                upgrades.deployProxy( 
                    Crowdsale,
                    [
                        syntex.address,// address _synthex, 
                        erc20.address,// address _token, 
                        START_TIME,// uint256 _startTime, 
                        START_TIME + DAY * 10,// uint256 _endTime, 
                        DAY,// uint256 _lockPeriod, 
                        DAY,// uint256 _unlockPeriod, 
                        10,// uint256 _percUnlockAtRelease, 
                        ROOT,// bytes32 _merkleRoot, 
                        DAY,// uint256 _whitelistDuration, 
                        parseEther("10")// uint256 _whitelistCap 
                    ]
                )
            ).to.be.revertedWith("26")
        })
        it("start time cannot be greater than end time", async () => {

            const Crowdsale = await ethers.getContractFactory("Crowdsale", deployer);
            const START_TIME = (await ethers.provider.getBlock("latest")).timestamp + DAY


            await expect(
                upgrades.deployProxy( 
                    Crowdsale,
                    [
                        syntex.address,// address _synthex, 
                        erc20.address,// address _token, 
                        START_TIME,// uint256 _startTime, 
                        START_TIME - DAY,// uint256 _endTime, 
                        DAY,// uint256 _lockPeriod, 
                        DAY,// uint256 _unlockPeriod, 
                        10,// uint256 _percUnlockAtRelease, 
                        ROOT,// bytes32 _merkleRoot, 
                        DAY,// uint256 _whitelistDuration, 
                        parseEther("10")// uint256 _whitelistCap 
                    ]
                )
            ).to.be.revertedWith("26")
        })
        it("syntex cannot be zero address", async () => {

            const Crowdsale = await ethers.getContractFactory("Crowdsale", deployer);
            const START_TIME = (await ethers.provider.getBlock("latest")).timestamp + DAY

            await expect(
                upgrades.deployProxy( 
                    Crowdsale,
                    [
                        ethers.constants.AddressZero,// address _synthex, 
                        erc20.address,// address _token, 
                        START_TIME,// uint256 _startTime, 
                        START_TIME + DAY * 10,// uint256 _endTime, 
                        DAY,// uint256 _lockPeriod, 
                        DAY,// uint256 _unlockPeriod, 
                        10,// uint256 _percUnlockAtRelease, 
                        ROOT,// bytes32 _merkleRoot, 
                        DAY,// uint256 _whitelistDuration, 
                        parseEther("10")// uint256 _whitelistCap 
                    ]
                )
            ).to.be.revertedWith("28")
        })
        it("token cannot be zero address", async () => {

            const Crowdsale = await ethers.getContractFactory("Crowdsale", deployer);
            const START_TIME = (await ethers.provider.getBlock("latest")).timestamp + DAY

            await expect(
                upgrades.deployProxy( 
                    Crowdsale,
                    [
                        syntex.address,// address _synthex, 
                        ethers.constants.AddressZero,// address _token, 
                        START_TIME,// uint256 _startTime, 
                        START_TIME + DAY * 10,// uint256 _endTime, 
                        DAY,// uint256 _lockPeriod, 
                        DAY,// uint256 _unlockPeriod, 
                        10,// uint256 _percUnlockAtRelease, 
                        ROOT,// bytes32 _merkleRoot, 
                        DAY,// uint256 _whitelistDuration, 
                        parseEther("10")// uint256 _whitelistCap 
                    ]
                )
            ).to.be.revertedWith("28")
        })
    })
    describe("whitelist buy with ether", function () {
        it("whitelisted user can buy tokens with ether", async () => {
            //start crowdsale
            await time.increase(DAY)

            const ETH_SEND_TO_CONTRACT = parseEther("2")
            let tx = await crowdsale.connect(users[0]).buyWithETH_w(usersMerkleProofs[0], { value: ETH_SEND_TO_CONTRACT })
            let recipt = await tx.wait()
            const USER_REQUEST_ID = [recipt.events[0].args.requestId]

            // wait till start + unlock period
            await time.increase(2 * DAY)

            await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)

            expect(await erc20.balanceOf(users[0].address)).to.be.eq(ETH_SEND_TO_CONTRACT.div(ETHER_RATE).mul(DECIMALS))
        });
        it("whitelisted user cannot unlock the same id twice", async () => {
            //start crowdsale
            await time.increase(DAY)

            const ETH_SEND_TO_CONTRACT = parseEther("2")
            let tx = await crowdsale.connect(users[0]).buyWithETH_w(usersMerkleProofs[0], { value: ETH_SEND_TO_CONTRACT })
            let recipt = await tx.wait()
            const USER_REQUEST_ID = [recipt.events[0].args.requestId]

            // wait till start + unlock period
            await time.increase(2 * DAY)

            await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)
            expect(await erc20.balanceOf(users[0].address)).to.be.eq(ETH_SEND_TO_CONTRACT.div(ETHER_RATE).mul(DECIMALS))
            await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)

            expect(await erc20.balanceOf(users[0].address)).to.be.eq(ETH_SEND_TO_CONTRACT.div(ETHER_RATE).mul(DECIMALS))
        });
        it("whitelisted user cannot buy tokens with before crowdsale start", async () => {
            const ETH_SEND_TO_CONTRACT = parseEther("2")
            await expect(crowdsale.connect(users[0]).buyWithETH_w(usersMerkleProofs[0], { value: ETH_SEND_TO_CONTRACT }))
                .to.be.rejectedWith("26")

        });
        it("whitelisted user cannot buy tokens with invalid proof", async () => {
            //start crowdsale
            await time.increase(DAY)
            const ETH_SEND_TO_CONTRACT = parseEther("2")
            await expect(crowdsale.connect(users[0]).buyWithETH_w(INVALID_PROOF, { value: ETH_SEND_TO_CONTRACT }))
                .to.be.rejectedWith("25")
        });
        it("whitelisted user cannot buy tokens with for 0 ether", async () => {
            //start crowdsale
            await time.increase(DAY)
            const ETH_SEND_TO_CONTRACT = 0
            await expect(crowdsale.connect(users[0]).buyWithETH_w(usersMerkleProofs[0], { value: ETH_SEND_TO_CONTRACT }))
                .to.be.rejectedWith("7")
        });
        it("whitelisted user cannot buy more tokens than whitelist capitalization", async () => {
            //start crowdsale
            await time.increase(DAY)

            const ETH_SEND_TO_CONTRACT = parseEther("11")

            await expect(crowdsale.connect(users[0]).buyWithETH_w(usersMerkleProofs[0], { value: ETH_SEND_TO_CONTRACT }))
                .to.be.revertedWith("8")
        });
        it("user canot buy tokens when contract on pause", async () => {
            await crowdsale.pause()
            await expect(crowdsale.connect(users[0]).buyWithETH_w(usersMerkleProofs[0], { value: 1 }))
                .to.be.revertedWith("Pausable: paused")
        })
        it("unlock cannot be called while contract on pause", async () => {
            const ANY_BYTES32 = ["0x626c756500000000000000000000000000000000000000000000000000000000"]
            await crowdsale.pause()
            await expect(crowdsale.unlock(ANY_BYTES32)).to.be.revertedWith("Pausable: paused")
        })
    });
    describe("whitelist buy with token", function () {
        it("whitelisted user can buy tokens with payments tokens", async () => {
            //start crowdsale
            await time.increase(DAY)
            const PAYMENT_TOKEN_AMOUNT = parseEther("2")
            await paymentToken.mint(users[0].address, PAYMENT_TOKEN_AMOUNT)

            await paymentToken.connect(users[0]).increaseAllowance(crowdsale.address, PAYMENT_TOKEN_AMOUNT)
            let tx = await crowdsale.connect(users[0])
                .buyWithToken_w(paymentToken.address, PAYMENT_TOKEN_AMOUNT, usersMerkleProofs[0])
            let recipt = await tx.wait()
            const USER_REQUEST_ID = [recipt.events[2].args.requestId]

            // wait unlock period + unlock period
            await time.increase(2 * DAY)

            await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)

            expect(await erc20.balanceOf(users[0].address))
                .to.be.eq(PAYMENT_TOKEN_AMOUNT.div(PAYMENT_TOKEN_RATE).mul(DECIMALS))
        });
        it("whitelisted user cannot buy tokens with paymetn tokens before crowdsale start", async () => {
            const PAYMENT_TOKEN_AMOUNT = parseEther("2")
            await expect(
                crowdsale.connect(users[0]).buyWithToken_w(paymentToken.address, PAYMENT_TOKEN_AMOUNT, usersMerkleProofs[0]))
                .to.be.reverted
        });
        it("whitelisted user cannot buy tokens with invalid proof", async () => {
            //start crowdsale
            await time.increase(DAY)

            const INVALID_PROOF =
                [
                    '0x4306ceff26c1e104939fabc1d917760e45551281e46ed897561f29a31ef875f3',
                    '0x11b8eb5570cba0bb401776e0de86c277b085e62cf3c1503934bf88e34c710eea'
                ]
            const PAYMENT_TOKEN_AMOUNT = parseEther("2")
            await expect(crowdsale.connect(users[0]).buyWithToken_w(paymentToken.address, PAYMENT_TOKEN_AMOUNT, INVALID_PROOF))
                .to.be.rejectedWith("25")
        });
        it("whitelisted user cannot buy tokens for 0 payment tokens", async () => {
            //start crowdsale
            await time.increase(DAY)
            const PAYMENT_TOKEN_AMOUNT = 0
            await expect(crowdsale.connect(users[0]).buyWithToken_w(paymentToken.address, PAYMENT_TOKEN_AMOUNT, usersMerkleProofs[0]))
                .to.be.rejectedWith("7")
        });
        it("whitelisted user cannot buy more tokens than whitelist capitalization", async () => {
            //start crowdsale
            await time.increase(DAY)

            const PAYMENT_TOKEN_AMOUNT = parseEther("11")
            await paymentToken.mint(users[0].address, PAYMENT_TOKEN_AMOUNT)
            await paymentToken.connect(users[0]).increaseAllowance(crowdsale.address, PAYMENT_TOKEN_AMOUNT)
            await expect(crowdsale.connect(users[0]).buyWithToken_w(paymentToken.address, PAYMENT_TOKEN_AMOUNT, usersMerkleProofs[0]))
                .to.be.revertedWith("8")
        });
        it("user canot buy tokens when contract on pause", async () => {
            const PAYMENT_TOKEN_AMOUNT = parseEther("1")
            await crowdsale.pause()
            await expect(crowdsale.buyWithToken_w(paymentToken.address, PAYMENT_TOKEN_AMOUNT, usersMerkleProofs[0]))
                .to.be.revertedWith("Pausable: paused")
        })
    })
    describe("buy with eth", function () {
        it("user can buy tokens with ether", async () => {
            //start crowdsale + wait whitelist period
            await time.increase(DAY + DAY)

            const ETH_SEND_TO_CONTRACT = parseEther("2")
            let tx = await crowdsale.connect(users[0]).buyWithETH({ value: ETH_SEND_TO_CONTRACT })
            let recipt = await tx.wait()
            const USER_REQUEST_ID = [recipt.events[0].args.requestId]

            await time.increase(2 * DAY)

            await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)

            expect(await erc20.balanceOf(users[0].address)).to.be.eq(ETH_SEND_TO_CONTRACT.div(ETHER_RATE).mul(DECIMALS))
        });
        it("user cannot buy tokens with ether before whitelist period ends", async () => {
            //start crowdsale
            await time.increase(DAY)

            const ETH_SEND_TO_CONTRACT = parseEther("2")
            await expect(crowdsale.connect(users[0]).buyWithETH({ value: ETH_SEND_TO_CONTRACT }))
                .to.be.reverted
        });
        it("whitelisted user cannot buy tokens with for 0 ether", async () => {
            //start crowdsale + wait whitelist period
            await time.increase(DAY + DAY)
            const ETH_SEND_TO_CONTRACT = 0
            await expect(crowdsale.connect(users[0]).buyWithETH({ value: ETH_SEND_TO_CONTRACT }))
                .to.be.reverted
        });
        it("user canot buy tokens when contract on pause", async () => {
            const ETH_SEND_TO_CONTRACT = parseEther("2")
            await crowdsale.pause()
            await expect(crowdsale.connect(users[0]).buyWithETH({ value: ETH_SEND_TO_CONTRACT }))
                .to.be.revertedWith("Pausable: paused")
        })
    })
    describe("buy with token", function () {
        it("user can buy tokens with payment tokens", async () => {
            //start crowdsale + wait whitelist period
            await time.increase(DAY + DAY)

            const PAYMENT_TOKEN_AMOUNT = parseEther("2")
            await paymentToken.mint(users[0].address, PAYMENT_TOKEN_AMOUNT)
            await paymentToken.connect(users[0]).increaseAllowance(crowdsale.address, PAYMENT_TOKEN_AMOUNT)

            let tx = await crowdsale.connect(users[0]).buyWithToken(paymentToken.address, PAYMENT_TOKEN_AMOUNT)
            let recipt = await tx.wait()
            const USER_REQUEST_ID = [recipt.events[2].args.requestId]

            await time.increase(2 * DAY)

            await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)

            expect(await erc20.balanceOf(users[0].address)).to.be.eq(PAYMENT_TOKEN_AMOUNT.div(PAYMENT_TOKEN_RATE).mul(DECIMALS))
        });
        it("user cannot buy tokens with payment tokens before crowdsale start", async () => {
            const PAYMENT_TOKEN_AMOUNT = parseEther("2")
            await expect(
                crowdsale.connect(users[0]).buyWithToken(paymentToken.address, PAYMENT_TOKEN_AMOUNT))
                .to.be.reverted
        });
        it("whitelisted user cannot buy tokens for 0 payment tokens", async () => {
            //start crowdsale
            await time.increase(DAY)
            const PAYMENT_TOKEN_AMOUNT = 0
            await expect(crowdsale.connect(users[0]).buyWithToken(paymentToken.address, PAYMENT_TOKEN_AMOUNT))
                .to.be.revertedWith("7")
        });
        it("user canot buy tokens when contract on pause", async () => {
            const PAYMENT_TOKEN_AMOUNT = parseEther("1")
            await crowdsale.pause()
            await expect(crowdsale.buyWithToken(paymentToken.address, PAYMENT_TOKEN_AMOUNT))
                .to.be.revertedWith("Pausable: paused")
        })


    })
    describe("admin function", function () {
        it("endSale", async () => {
            await crowdsale.endSale();
        })
        it("admin cannot endSale after sale end", async () => {
            await time.increase(DAY * 15)
            await expect(crowdsale.endSale()).to.be.reverted
        })
        it("l1 admin can withdraw tokens from contract", async () => {
            const AMOUNT_TO_WITHDRAW = parseEther("1")
            await paymentToken.mint(crowdsale.address, AMOUNT_TO_WITHDRAW)
            await crowdsale.withdraw(paymentToken.address, AMOUNT_TO_WITHDRAW)

            expect(await paymentToken.balanceOf(deployer.address)).to.be.equal(AMOUNT_TO_WITHDRAW)
        })
        it("l1 admin can withdraw ether from contract", async () => {
            const BALANCE_BEFORE = await ethers.provider.getBalance(deployer.address)
            const AMOUNT_TO_WITHDRAW = parseEther("1")

            //provide ether for contract
            await time.increase(DAY + DAY)
            await crowdsale.connect(users[0]).buyWithETH({ value: AMOUNT_TO_WITHDRAW })

            let tx = await crowdsale.withdraw(ETHER_ADDRESS, AMOUNT_TO_WITHDRAW)
            const receipt = await tx.wait()
            const GAS_PAID = receipt.cumulativeGasUsed.mul(receipt.effectiveGasPrice)

            const BALANCE_AFTER = await ethers.provider.getBalance(deployer.address)

            expect(BALANCE_AFTER.sub(BALANCE_BEFORE).add(GAS_PAID)).to.be.eq(AMOUNT_TO_WITHDRAW)
        })
        it("l2 admin can unpause contract", async () => {
            await crowdsale.pause()
            expect(await crowdsale.unpause()).to.emit(crowdsale, "Unpaused").withArgs(deployer.address)
        })
    })
    describe("", function () {
        it.skip("recive works as buyWithEth function", async () => {
            await time.increase(DAY + DAY)

            const ETH_SEND_TO_CONTRACT = parseEther("2")
            let tx = await users[0].sendTransaction(
                {
                    to: crowdsale.address,
                    value: ETH_SEND_TO_CONTRACT
                }
            )
            let recipt = await tx.wait()
            console.log(recipt)
            const USER_REQUEST_ID = [recipt.events[0].args.requestId]

            // await time.increase(2 * DAY)

            // await crowdsale.connect(users[0]).unlock(USER_REQUEST_ID)

            // expect(await erc20.balanceOf(users[0].address)).to.be.eq(ETH_SEND_TO_CONTRACT.div(ETHER_RATE).mul(DECIMALS))            
        })
        it("fallback", async () => {


        })
    })

});