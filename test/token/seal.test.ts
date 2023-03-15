import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import main from "../../scripts/main";
import { AUTHORIZED_SENDER } from '../../scripts/utils/const';
import { ERRORS } from '../../scripts/utils/errors';

describe("Testing seal of esSYX", function () {

	let SYX: any, esSYX: any;
	let owner: any, user1: any, user2: any, user3: any, user4: any;

    const amount = ethers.utils.parseEther('1000');

	before(async () => {
		// Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3, user4] = await ethers.getSigners();
		const deployments = await loadFixture(main);
        esSYX = deployments.esSYX;
        SYX = deployments.SYX;

        await SYX.mint(user1.address, amount);
        expect(await SYX.balanceOf(user1.address)).to.equal(amount);
	});

    it("lock syx", async function () {
        await SYX.connect(user1).increaseAllowance(esSYX.address, amount);
        expect(await SYX.allowance(user1.address, esSYX.address)).to.equal(amount);
        await esSYX.connect(user1).lock(amount.div(2), user1.address);
        await esSYX.connect(user1).lock(amount.div(2), user3.address);

    })

    it("should not be able to transfer", async function () {
        await expect(esSYX.connect(user1).transfer(user2.address, amount.div(2))).to.be.revertedWith(ERRORS.TRANSFER_FAILED);
    })

    it("should be able to transfer & transferFrom after getting authorized", async function () {
        await esSYX.connect(owner).grantRole(AUTHORIZED_SENDER, user1.address);
        expect(await esSYX.hasRole(AUTHORIZED_SENDER, user1.address)).to.equal(true);

        await esSYX.connect(user1).transfer(user2.address, amount.div(2));
        await esSYX.connect(user3).increaseAllowance(user1.address, amount.div(2));
        await esSYX.connect(user1).transferFrom(user3.address, user2.address, amount.div(2));

        expect(await esSYX.balanceOf(user1.address)).to.equal(0);
        expect(await esSYX.balanceOf(user2.address)).to.equal(amount);
    })
});