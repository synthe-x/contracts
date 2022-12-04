import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter"

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  gasReporter: {
    enabled: false,
    currency: 'USD',
    gasPrice: 25,
    coinmarketcap: '54e57674-6e99-404b-8528-cbf6a9f1e471'
  },
};

export default config;
