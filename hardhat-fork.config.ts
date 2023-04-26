import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://rpc.ankr.com/arbitrum",
                blockNumber: 84110651
            },
            gasPrice: 500000000,
            chainId: 5,
        },
    },
}