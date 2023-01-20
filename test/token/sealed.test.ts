// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import initiate from "../../scripts/test";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("Testing sealed erc20", function () {

	let token: any, sealed: any, unlockerContract: any;
	let deployer: any, owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2] = await ethers.getSigners();
        const deployments = await initiate(owner);
        sealed = deployments.sealedSYN;
	});

    it("should not be able to mint without MINTER_ROLE", async function () {
        const role = await sealed.MINTER_ROLE();
        await expect(sealed.connect(owner).mint(user1.address, ethers.utils.parseEther('1000'))).to.be.revertedWith(
            `AccessControl: account ${owner.address.toLowerCase()} is missing role ${role}`
        );
    })

    it("admin should be able to grant role", async function () {
        await sealed.connect(owner).grantMinterRole(owner.address);
        expect(await sealed.hasRole(await sealed.MINTER_ROLE(), owner.address)).to.equal(true);
    })

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