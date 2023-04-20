import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://rpc.ankr.com/arbitrum",
            },
            // 0.1 gwei
            gasPrice: 1000000000, 

            chainId: 42161,
        },
    },
}