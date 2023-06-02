import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://arb1.croswap.com/rpc"
            },
            chainId: 42161,
        },
    },
}