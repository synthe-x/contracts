# SyntheX Contracts

## Compile Contracts

```bash
yarn compile
```

## Deployment 

```bash
yarn deploy --network [network]
```

## Tasks

1. Deploy SynthEx
```bash
npx hardhat run tasks/synthex
```

2. Deploy SYX and esSYX
```bash
npx hardhat run tasks/syx
```

3. Deploy Vault
```bash
npx hardhat run tasks/vault
```

4. Deploy Pool
```bash
npx hardhat run tasks/pools/new
```

5. Add collateral to pool
```bash
npx hardhat run tasks/pools/collateral
```

5. Deploy and add Synth to pool
```bash
npx hardhat run tasks/pools/synth
```