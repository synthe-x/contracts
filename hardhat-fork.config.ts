import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://arbitrum.blockpi.network/v1/rpc/public",
            },
            // 0.1 gwei
            gasPrice: 10000000000, 
            chainId: 42161,
        },
    },
}