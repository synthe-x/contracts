
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { deploy } from '../../scripts/crowdsale';
import { keccak256 } from 'ethers/lib/utils';
import { MerkleTree } from "merkletreejs"


describe("Testing crowdsale", () => {

    let cs: Contract;
    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, user3: SignerWithAddress;
    let tree: MerkleTree;

    before(async () => {

        const whiteListed = [
            "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
            "0x186b4b5Da9E6817C21818DEb83BBA02c4c66627F"
        ]

        const leaves = whiteListed.map((add) => {
            return keccak256(add)
        });

        // tree = new MerkleTree(leaves);
        [owner, user1, user2, user3] = await ethers.getSigners();
        const dep = await deploy();
        cs = dep.cs;
        tree = dep.tree
        
        let wait = () => {
            return new Promise((resolve, reject) => {
                let timeOutId = setTimeout(() => {
                    console.log("wait over");
                    return resolve("Success");
                }, 10000)
            })
        }
        await cs.connect(owner).updateRate("0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", ethers.utils.parseEther("1800"))
        await wait()

    });

    it("It should allow whiteListed address", async () => {

        const hashAdd = ethers.utils.keccak256(owner.address);
        const proof = tree.getHexProof(hashAdd)
        console.log(proof)
        const buy = await cs.connect(owner).buyWithETH_w(proof, { value: ethers.utils.parseEther("1000") });
        console.log(buy)
    })
})