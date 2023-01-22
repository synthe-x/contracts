// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import deploy from "../scripts/test";

describe("crowdsale", function () {

	let crowdsale: any, oracle: any, token: any, sealedtoken: any, system: any;
	let owner: any, user1: any, user2: any, user3: any;

	before(async () => {
		// Contracts are deployed using the first signer/account by default
		[owner, user1, user2, user3] = await ethers.getSigners();

		const deployments = await deploy(owner);
		crowdsale = deployments.crowdsale;
        token = deployments.syn;
        sealedtoken = deployments.sealedSYN;
        system = deployments.system;
	});

	it("check lock period logic", async function () {

	console.log(await crowdsale.connect(user1).getRequestId(user1.address, 1));

	})

	it("Buy tokens", async function () {
     let balBefore =  await crowdsale.connect(user1).getEtherBalance( crowdsale.address);
     let tx =   await crowdsale.connect(user1).buyTokens({gasLimit: 3e7, value: ethers.utils.parseEther("500") });
	 let balAfter = await crowdsale.connect(user1).getEtherBalance( crowdsale.address);
	 await expect(balAfter).to.be.equal(balBefore + ethers.utils.parseEther("500") );
	 await expect(tx).to.emit(crowdsale, 'TokenPurchase');

	});



	it("start unlock tokens", async function () {
        await token.connect(owner).mint( crowdsale.address, 10000);
	
		
		await  expect(crowdsale.connect(user1).unlock(2339999)).to.be.revertedWith('Not enough SYN to unlock');

		let tx =   await crowdsale.connect(user1).unlock(500);
	 
	   });


});