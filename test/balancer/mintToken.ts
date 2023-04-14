import { ethers } from "hardhat";
import { promises as fs } from "fs";
import path from "path";
import { expect } from "chai";










describe("MInt token for providing liquidity to balancer", function () {

    let synthex: any, oracle: any, poolC: any, poolF: any, DAI: any, cusd: any, fusd: any, USDC: any;
    let owner: any, user1: any, user2: any, user3: any;

    before(async () => {
        // Contracts are deployed using the first signer/account by default
        [owner, user1, user2, user3] = await ethers.getSigners();
        const deployments = JSON.parse((await fs.readFile(path.join(__dirname + "/../../deployments/31337/deployments.json"))).toString())
        let provider = new ethers.providers.JsonRpcProvider("http://localhost:8545");
        synthex = new ethers.Contract("0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0", deployments["sources"]["SyntheX"], provider);
        poolC = new ethers.Contract("0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f", deployments["sources"]["Pool"], provider);
        poolF = new ethers.Contract("0x922D6956C99E12DFeB3224DEA977D0939758A1Fe", deployments["sources"]["Pool"], provider);
            // oracle =
        USDC =  new ethers.Contract("0xdbC43Ba45381e02825b14322cDdd15eC4B3164E6", deployments["sources"]["MockToken"], provider); 
        DAI =  new ethers.Contract("0x21dF544947ba3E8b3c32561399E88B52Dc8b2823", deployments["sources"]["MockToken"], provider); 
        cusd =  new ethers.Contract("0x809d550fca64d94Bd9F66E60752A544199cfAC3D", deployments["sources"]["ERC20X"], provider); 
        fusd =  new ethers.Contract("0x8198f5d8F8CfFE8f9C413d98a0A55aEB8ab9FbB7", deployments["sources"]["ERC20X"], provider); 
    });

    it("Mint token",async ()=>{
        const deposit = ethers.utils.parseEther("10");
        const sDeposit = ethers.utils.parseEther("15000");
		await DAI.connect(owner).mint(owner.address, sDeposit);
		await USDC.connect(owner).mint(owner.address, sDeposit);
        await DAI.connect(owner).approve("0x922D6956C99E12DFeB3224DEA977D0939758A1Fe", sDeposit)
		await poolC.connect(owner).depositETH({value: deposit});    // $ 20000
		
		await poolF.connect(owner).deposit("0x21dF544947ba3E8b3c32561399E88B52Dc8b2823", sDeposit);    // $ 10000
		// expect((await poolC.getAccountLiquidity(owner.address)).collateral).to.equal(ethers.utils.parseEther('1800000'));
		// expect((await poolF.getAccountLiquidity(owner.address)).collateral).to.equal(ethers.utils.parseEther('200000'));
    })

    it("issue synths", async function () {
		// user1 issues 10 seth

        await cusd.connect(owner).mint(ethers.utils.parseEther("1000"), owner.address, ethers.constants.AddressZero); // $ 90000
        await fusd.connect(owner).mint(ethers.utils.parseEther("1000"), owner.address, ethers.constants.AddressZero);
		// balance
		// expect(await cusd.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("300000"));
		

		const ownerLiquidity = await poolC.getAccountLiquidity(owner.address);
		const ownerLiquidityF = await poolF.getAccountLiquidity(owner.address);
		// const user3Liquidity = await pool.getAccountLiquidity(user3.address);
        console.log(ownerLiquidity[2], ownerLiquidityF[2])
        // expect(ownerLiquidity[2]).to.be.equal(ethers.utils.parseEther("10000.00"));
        // expect(user3Liquidity[2]).to.be.equal(ethers.utils.parseEther("90000.00"));
	});

    it("approve balancer pool", async ()=>{
        //approve pool
        await cusd.connect(owner).approve("0x08B4626D733A4b5e42ad3A84c324F98c43d37CdE", ethers.utils.parseEther("10000000000000000000000000"));
        //approve vault
        await cusd.connect(owner).approve("0xc96304e3c037f81dA488ed9dEa1D8F2a48278a75", ethers.utils.parseEther("10000000000000000000000000"))
        await fusd.connect(owner).approve("0x08B4626D733A4b5e42ad3A84c324F98c43d37CdE", ethers.utils.parseEther("10000000000000000000000000"));
        //approve vault
        await fusd.connect(owner).approve("0xc96304e3c037f81dA488ed9dEa1D8F2a48278a75", ethers.utils.parseEther("10000000000000000000000000"))
        await USDC.connect(owner).approve("0x08B4626D733A4b5e42ad3A84c324F98c43d37CdE", ethers.utils.parseEther("10000000000000000000000000"));
        //approve vault
        await USDC.connect(owner).approve("0xc96304e3c037f81dA488ed9dEa1D8F2a48278a75", ethers.utils.parseEther("10000000000000000000000000"))
    })

})


/**
 * 
 * 
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

Account #2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000 ETH)
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

Account #3: 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000 ETH)
Private Key: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6

Account #4: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (10000 ETH)
ee7af6b827f2a8bce2897751d06a843f644967b1

Account #13: 0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec (10000 ETH)
Private Key: 0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd     

Account #14: 0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097 (10000 ETH)
Private Key: 0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa     

Account #15: 0xcd3B766CCDd6AE721141F452C550Ca635964ce71 (10000 ETH)
Private Key: 0x8166f546bab6da521a8369cab06c5d2b9e46670292d85c875ee9ec20e84ffb61     

Account #16: 0x2546BcD3c84621e976D8185a91A922aE77ECEc30 (10000 ETH)
Private Key: 0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0     

Account #17: 0xbDA5747bFD65F08deb54cb465eB87D40e51B197E (10000 ETH)
Private Key: 0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd     

Account #18: 0xdD2FD4581271e230360230F9337D5c0430Bf44C0 (10000 ETH)
Private Key: 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0     

Account #19: 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 (10000 ETH)
Private Key: 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e  
 */