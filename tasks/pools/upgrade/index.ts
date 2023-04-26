import main from "./main";

// Mainnet
// CollateralLogic deployed at 0x3F6Ce88b9e04e13Ef66c08f4Ded92eF7e04bb321
// PoolLogic deployed at 0xC31273180Dc703878A9A78dA0331A91C405eB453
// SynthLogic deployed at 0xC2741D13De057d21968fC25B19FB063ecda919e2


// Testnet
main(
    '0x0546458d110Dff9D394C0F4621423Bc8f009A779',
    '0x3F6Ce88b9e04e13Ef66c08f4Ded92eF7e04bb321', // COllateral Logic
    '0xC31273180Dc703878A9A78dA0331A91C405eB453', // Pool Logic
    '0xC2741D13De057d21968fC25B19FB063ecda919e2', // Synth Logic
)