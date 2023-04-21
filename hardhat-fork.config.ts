import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://arbitrum.blockpi.network/v1/rpc/public",
            },
            gasPrice: 500000000,
            chainId: 42161,
        },
    },
}