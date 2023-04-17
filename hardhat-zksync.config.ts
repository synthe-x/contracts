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
  defender: {
    apiKey: process.env.DEFENDER_TEAM_API_KEY!,
    apiSecret: process.env.DEFENDER_TEAM_API_SECRET_KEY!,
  },
  OpenzeppelinDefenderCredential: {
    apiKey: process.env.DEFENDER_TEAM_API_KEY!,
    apiSecret: process.env.DEFENDER_TEAM_API_SECRET_KEY!,
  },
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
    zkSyncTestnet:{
      url: "https://testnet.era.zksync.dev",
      ethNetwork: "goerli",  // or a Goerli RPC endpoint from Infura/Alchemy/Chainstack etc.
      chainId: 280,
      zksync: true,
      verifyURL: 'https://zksync2-testnet-explorer.zksync.dev/contract_verification'
    },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 5,
      zksync: false,
    },
    localhost: {
      url: "http://localhost:8545",
      chainId: 31337,
      isLive: false,
      zksync: false,
    },
  },
  defaultNetwork: "zkSyncTestnet",
  zksolc: {
    version: "1.3.8",
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