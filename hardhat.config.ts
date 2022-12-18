import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter"
require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    arbitrumGoerli: {
      url: "https://arbitrum-goerli.infura.io/v3/bb621c9372d048979f8677ba78fe41d7",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    }
  },
  gasReporter: {
    enabled: false,
    currency: 'USD',
    gasPrice: 25,
    coinmarketcap: '54e57674-6e99-404b-8528-cbf6a9f1e471'
  },
  etherscan:{
    apiKey: {
      arbitrumGoerli: "S5IYYDM5KC14FZ7HR9NFCGDJVBUZ65UGMY"
    }
  }
};

export default config;