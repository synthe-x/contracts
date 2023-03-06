# Access Control

This contract is used to access control of the protocol

## SyntheX Admins

There are 3 levels of admin roles, and 1 governance module role:

### Level-0 Admin (DEFAULT_ADMIN_ROLE)

Backup admin. Stored in cold storage across multiple custodians. Not needed during usual functioning of the protocol, Only to be used in unexpected situations

- AddressStorage: Can grant/revoke L0 admin, L1 admin, L2 admin and Governance modules roles

### Level-1 Admin (L1_ADMIN_ROLE)

Top admininistrator: Not needed during usual functioning of the protocol, Only to be used while initializing and for rare necessary actions

- Can set/reset addresses
- Can upgrade contracts
- Can mint SYX tokens
- Can collect fees from vault

### Level-2 Admin (L2_ADMIN_ROLE)

Contract level admin

- Can manage contracts params in emergency situations
- Can Pause/Unpause contracts
- Can update amount, speed, reward period
- Unlocker: Withdraw extra tokens, set lock period

## Pool admins

### Level-0 Admin (admin)

- Upgrade contract
- Add/Enable/Disable/Remove synths
- Update Price Oracle

### Level-1 Admin (owner)

- Update Params (fees, ltv, cap)
- Pause/Unpause
- Update Price Oracle