import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://arb-mainnet.g.alchemy.com/v2/mJSnb6p3QRZdqQIHgJerJCI5M9kul8lo",
                blockNumber: 85185287
            },
            // 0.1 gwei
            gasPrice: 10000000000,

            chainId: 42161,
        },
        local: {
            url: 'http://localhost:8545',
            chainId: 31337,
            accounts: ['ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'],
            isLive: false
        }
    },
}