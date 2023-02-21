import { ethers } from 'hardhat';

export const POOL_ADDRESS_PROVIDER = '0x4C2F7092C2aE51D986bEFEe378e50BD4dB99C901';
export const ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

// contracts
export const VAULT = ethers.utils.id('VAULT');
export const SYNTHEX = ethers.utils.id('SYNTHEX');
export const PRICE_ORACLE = ethers.utils.id('PRICE_ORACLE');

// roles
export const DEFAULT_ADMIN_ROLE = ethers.utils.id('DEFAULT_ADMIN_ROLE');
export const L1_ADMIN_ROLE = ethers.utils.id('L1_ADMIN_ROLE');
export const L2_ADMIN_ROLE = ethers.utils.id('L2_ADMIN_ROLE');
export const GOVERNANCE_MODULE_ROLE = ethers.utils.id('GOVERNANCE_MODULE_ROLE');

export const MINTER_ROLE = ethers.utils.id('MINTER_ROLE');
export const BURNER_ROLE = ethers.utils.id('BURNER_ROLE');
export const PAUSER_ROLE = ethers.utils.id('PAUSER_ROLE');
export const AUTHORIZED_SENDER = ethers.utils.id('AUTHORIZED_SENDER');

export const BASIS_POINTS = ethers.utils.parseEther('10000');