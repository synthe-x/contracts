import { HardhatUserConfig, task } from "hardhat/config";
import '@openzeppelin/hardhat-upgrades';
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter"
import "@openzeppelin/hardhat-defender"
import "hardhat-openzeppelin-defender";
import 'solidity-docgen';
require('dotenv').config();
import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";

const PRIVATE_KEY = process.env.PRIVATE_KEY ?? 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

const config: any = {
  docgen: {},
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          }
        },
      },
      {
        version: "0.4.18"
      },
    ],
  },
  mocha: {
    timeout: 100000000
  },
  networks: {
    hardhat: {
      zksync: false,
      isLive: false,
    },
    zkSyncLocal:{
      url: "http://localhost:3050/",
      ethNetwork: "l1Local",  // or a Goerli RPC endpoint from Infura/Alchemy/Chainstack etc.
      chainId: 270,
      zksync: true,
      isLive: false,
    },
    l1Local: {
      url: "http://localhost:8545/",
      chainId: 9,
      zksync: false,
      isLive: false,
    },
  },
  defaultNetwork: "zkSyncLocal",
  zksolc: {
    version: "1.3.7",
    compilerSource: "binary",  // binary or docker (deprecated)
    settings: {
      experimental: {
        compilerSource: "binary", // Deprecated! use, compilerSource: "binary"
        tag: "latest"   // Deprecated: used for compilerSource: "docker"
      },
      optimizer: {
        enabled: true, // optional. True by default
      }
    }
  },
};

export default config;