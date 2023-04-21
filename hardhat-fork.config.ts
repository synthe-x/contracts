import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://rpc.ankr.com/arbitrum",
            },
            gasPrice: 500000000,
            chainId: 42161,
        },
    },
}