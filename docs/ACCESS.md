# Access Control

This contract is used to access control of the protocol

## Roles

There are 3 levels of admin roles, and 1 governance module role:

### Level-0 Admin (DEFAULT_ADMIN_ROLE)

Backup admin. Stored in cold storage across multiple custodians. Not needed during usual functioning of the protocol, Only to be used in unexpected situations

- AddressStorage: Can grant/revoke L0 admin, L1 admin, L2 admin and Governance modules roles

### Level-1 Admin (L1_ADMIN_ROLE)

Top admininistrator: Not needed during usual functioning of the protocol, Only to be used for rare necessary actions

- AddressStorage: Can set/reset addresses
- AddressStorage: Can grant/revoke L2_ADMIN_ROLE, GOVERNANCE_MODULE_ROLE
- SyntheX, SyntheXPool: Can upgrade contracts
- SYN: Can mint tokens
- PriceOracle: Update price feed
- Fee Vault: Can collect fees

### Level-2 Admin (L2_ADMIN_ROLE)

Contract level admin

- Can manage contracts params in emergency situations
- All: Can Pause/Unpause contracts
- Staking rewards: Can update amount, speed, reward period
- Unlocker: Withdraw extra tokens, set lock period
- Debt Pool: Update fee token, Disable synth

### Governance (GOVERNANCE_MODULE_ROLE)

Can handle proposals passed thru protocol governance

- Updating contract level params
- SyntheX: Adding a trading pool
- Debt Pool: Add/Enable synths, Update fee, Disable synth, Remove Synth
