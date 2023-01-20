import { ethers } from 'hardhat';

export const ETH_ADDRESS = ethers.constants.AddressZero;

// contracts
export const VAULT = ethers.utils.id('VAULT');
export const SYNTHEX = ethers.utils.id('SYNTHEX');
export const PRICE_ORACLE = ethers.utils.id('PRICE_ORACLE');

// roles
export const DEFAULT_ADMIN_ROLE = ethers.utils.id('DEFAULT_ADMIN_ROLE');
export const L1_ADMIN_ROLE = ethers.utils.id('L1_ADMIN_ROLE');
export const L2_ADMIN_ROLE = ethers.utils.id('L2_ADMIN_ROLE');
export const GOVERNANCE_MODULE_ROLE = ethers.utils.id('GOVERNANCE_MODULE_ROLE');