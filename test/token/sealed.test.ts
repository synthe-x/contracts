// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import initiate from "../../scripts/test";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Testing unlocker", function () {

	let token: any, sealed: any, unlockerContract: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();

        const erc20Sealed = await ethers.getContractFactory("SealedSYN");
        sealed = await erc20Sealed.deploy();
	});

    it('owner should be able to mint', async function () {
        await sealed.mint(user1.address, ethers.utils.parseEther('1000'));
        expect(await sealed.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('1000'));
    })

    it("should not be able to transfer", async function () {
        await expect(sealed.connect(user1).transfer(user2.address, ethers.utils.parseEther('100'))).to.be.revertedWith("ERC20Sealed: Token is sealed");
    })

    it('should be able to burn', async function () {
        await sealed.connect(user1).burn(ethers.utils.parseEther('100'));
        expect(await sealed.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('900'));
    })
});