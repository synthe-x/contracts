# Access Control

This contract is used to access control of the protocol

## SyntheX Admins

There are 3 levels of admin roles, and 1 governance module role:

### Level-0 Admin (DEFAULT_ADMIN_ROLE)

Backup admin. Stored in cold storage across multiple custodians. Not needed during usual functioning of the protocol, Only to be used in unexpected situations

- Access: Can grant/revoke L0 admin, L1 admin, L2 admin roles
- Upgradeable: Can upgrade contracts

### Level-1 Admin (L1_ADMIN_ROLE)

Top admininistrator: Not needed during usual functioning of the protocol, Needed for making modifications

- Can set/reset addresses
- Can mint SYX tokens
- Can collect fees from vault

### Level-2 Admin (L2_ADMIN_ROLE)

Contract level admin

- Can manage contracts params in emergency situations
- Can Pause/Unpause contracts
- Can update amount, speed, reward period