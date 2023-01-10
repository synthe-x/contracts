import { HardhatUserConfig } from "hardhat/config";
import '@openzeppelin/hardhat-upgrades';
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter"
require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    arbitrumGoerli: {
      url: "https://arb-goerli.g.alchemy.com/v2/HyNaane88yHFsK8Yrn4gf2OOzHkd6GAJ",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    }
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 13,
    coinmarketcap: '54e57674-6e99-404b-8528-cbf6a9f1e471'
  },
  etherscan:{
    apiKey: {
      arbitrumGoerli: "S5IYYDM5KC14FZ7HR9NFCGDJVBUZ65UGMY"
    }
  }
};

export default config;