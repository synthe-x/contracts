import hardhatConfig from "./hardhat.config"

export default {
    ...hardhatConfig,
    networks: {
        ...hardhatConfig.networks,
        hardhat: {
            forking: {
                url: "https://arbitrum-goerli.public.blastapi.io"
            },
            chainId: 421613,
        },
    },
}