import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://rpc.ankr.com/arbitrum",
            },
<<<<<<< HEAD
            gasPrice: 500000000,
=======
            // 0.1 gwei
            gasPrice: 1000000000, 

>>>>>>> bad8169501b098c0eb24119f7e9d6bfcea16e4a9
            chainId: 42161,
        },
    },
}