# SyntheX Contracts


slither --solc-remaps "@openzeppelin/=node_modules/@openzeppelin/" --print function-summary  --solc-args="optimize optimize-runs=200 --via-ir" ./contracts/SyntheX.sol 2>&1 |tee -a slither-function-summary