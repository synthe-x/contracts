import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://rpc.ankr.com/eth",
            },
            chainId: 11,
        },
    },
}