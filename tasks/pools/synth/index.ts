import { SynthArgs } from "../../../deployments/types";
import main from "./main";

const cConfig: SynthArgs = {
    name: "US Dollar",
    symbol: "USD",
    price: "1",
    isFeeToken: true,
    mintFee: "4",
    burnFee: "2",
    address: null,
    feed: null,
    isFeedSecondary: false,
    secondarySource: null
};

main(cConfig, "0x62f9d6663E14A28aFdD2af49116602B8E6816751", "0");