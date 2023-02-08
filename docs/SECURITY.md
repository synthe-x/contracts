Summary
 - [arbitrary-send-erc20](#arbitrary-send-erc20) (1 results) (High)
 - [arbitrary-send-eth](#arbitrary-send-eth) (1 results) (High)
 - [controlled-delegatecall](#controlled-delegatecall) (1 results) (High)
 - [name-reused](#name-reused) (2 results) (High)
 - [reentrancy-eth](#reentrancy-eth) (1 results) (High)
 - [unchecked-transfer](#unchecked-transfer) (6 results) (High)
 - [unprotected-upgrade](#unprotected-upgrade) (2 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (27 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (5 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (9 results) (Medium)
 - [tautology](#tautology) (1 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (3 results) (Medium)
 - [unused-return](#unused-return) (1 results) (Medium)
 - [shadowing-local](#shadowing-local) (9 results) (Low)
 - [events-maths](#events-maths) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (7 results) (Low)
 - [calls-loop](#calls-loop) (22 results) (Low)
 - [variable-scope](#variable-scope) (3 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (11 results) (Low)
 - [reentrancy-events](#reentrancy-events) (12 results) (Low)
 - [timestamp](#timestamp) (14 results) (Low)
 - [assembly](#assembly) (13 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [costly-loop](#costly-loop) (4 results) (Informational)
 - [solc-version](#solc-version) (100 results) (Informational)
 - [low-level-calls](#low-level-calls) (11 results) (Informational)
 - [naming-convention](#naming-convention) (176 results) (Informational)
 - [redundant-statements](#redundant-statements) (9 results) (Informational)
 - [reentrancy-unlimited-gas](#reentrancy-unlimited-gas) (3 results) (Informational)
 - [similar-names](#similar-names) (32 results) (Informational)
 - [unused-state](#unused-state) (1 results) (Informational)
 - [constable-states](#constable-states) (14 results) (Optimization)
 - [immutable-states](#immutable-states) (27 results) (Optimization)
## arbitrary-send-erc20
Impact: High
Confidence: High
 - [ ] ID-0
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L130-L150) uses arbitrary from in transferFrom: [token.transferFrom(wallet,msg.sender,calculatedUnlockAmt)](contracts/token/Crowdsale.sol#L144)

contracts/token/Crowdsale.sol#L130-L150


## arbitrary-send-eth
Impact: High
Confidence: Medium
 - [ ] ID-1
[SyntheX.transferOut(address,address,uint256)](contracts/SyntheX.sol#L226-L240) sends eth to arbitrary user
	Dangerous calls:
	- [address(recipient).transfer(_amount)](contracts/SyntheX.sol#L231)

contracts/SyntheX.sol#L226-L240


## controlled-delegatecall
Impact: High
Confidence: Medium
 - [ ] ID-2
[ERC1967UpgradeUpgradeable._functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204) uses delegatecall to a input-controlled function id
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L202)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204


## name-reused
Impact: High
Confidence: High
 - [ ] ID-3
IPriceOracle is re-used:
	- [IPriceOracle](node_modules/@aave/core-v3/contracts/interfaces/IPriceOracle.sol#L9-L23)
	- [IPriceOracle](contracts/interfaces/IPriceOracle.sol#L4-L37)
	- [IPriceOracle](contracts/interfaces/compound/IPriceOracle.sol#L6-L18)

node_modules/@aave/core-v3/contracts/interfaces/IPriceOracle.sol#L9-L23


 - [ ] ID-4
IERC20 is re-used:
	- [IERC20](node_modules/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol#L7-L80)
	- [IERC20](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L9-L82)

node_modules/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol#L7-L80


## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-5
Reentrancy in [SyntheX.withdraw(address,uint256)](contracts/SyntheX.sol#L204-L224):
	External calls:
	- [_amount = transferOut(_collateral,msg.sender,_amount)](contracts/SyntheX.sol#L212)
		- [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L110)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)
		- [ERC20Upgradeable(_collateral).safeTransfer(recipient,_amount)](contracts/SyntheX.sol#L236)
	External calls sending eth:
	- [_amount = transferOut(_collateral,msg.sender,_amount)](contracts/SyntheX.sol#L212)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)
		- [address(recipient).transfer(_amount)](contracts/SyntheX.sol#L231)
	State variables written after the call(s):
	- [accountCollateralBalance[msg.sender][_collateral] = depositBalance.sub(_amount)](contracts/SyntheX.sol#L215)
	[SyntheXStorage.accountCollateralBalance](contracts/storage/SyntheXStorage.sol#L36) can be used in cross function reentrancies:
	- [SyntheX._getAccountLiquidity(address)](contracts/SyntheX.sol#L751-L795)
	- [SyntheXStorage.accountCollateralBalance](contracts/storage/SyntheXStorage.sol#L36)
	- [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)](contracts/SyntheX.sol#L289-L331)
	- [SyntheX.getAccountLiquidity(address)](contracts/SyntheX.sol#L678-L706)
	- [SyntheX.getAdjustedAccountLiquidity(address)](contracts/SyntheX.sol#L713-L749)
	- [supply.totalDeposits = supply.totalDeposits.sub(_amount)](contracts/SyntheX.sol#L217)
	[SyntheXStorage.collateralSupplies](contracts/storage/SyntheXStorage.sol#L57) can be used in cross function reentrancies:
	- [SyntheXStorage.collateralSupplies](contracts/storage/SyntheXStorage.sol#L57)
	- [SyntheX.setCollateralCap(address,uint256)](contracts/SyntheX.sol#L418-L426)

contracts/SyntheX.sol#L204-L224


## unchecked-transfer
Impact: High
Confidence: Medium
 - [ ] ID-6
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L130-L150) ignores return value by [token.transferFrom(wallet,msg.sender,calculatedUnlockAmt)](contracts/token/Crowdsale.sol#L144)

contracts/token/Crowdsale.sol#L130-L150


 - [ ] ID-7
[ATokenWrapper.withdraw(uint256)](contracts/utils/ATokenWrapper.sol#L40-L44) ignores return value by [underlying.transfer(msg.sender,amount)](contracts/utils/ATokenWrapper.sol#L43)

contracts/utils/ATokenWrapper.sol#L40-L44


 - [ ] ID-8
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) ignores return value by [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-9
[TokenUnlocker.withdraw(uint256)](contracts/token/TokenUnlocker.sol#L108-L111) ignores return value by [TOKEN.transfer(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L110)

contracts/token/TokenUnlocker.sol#L108-L111


 - [ ] ID-10
[ATokenWrapper.deposit(uint256)](contracts/utils/ATokenWrapper.sol#L35-L38) ignores return value by [underlying.transferFrom(msg.sender,address(this),amount)](contracts/utils/ATokenWrapper.sol#L36)

contracts/utils/ATokenWrapper.sol#L35-L38


 - [ ] ID-11
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L571-L593) ignores return value by [_rewardToken.transfer(_user,_amount)](contracts/SyntheX.sol#L586)

contracts/SyntheX.sol#L571-L593


## unprotected-upgrade
Impact: High
Confidence: High
 - [ ] ID-12
[ERC20X](contracts/ERC20X.sol#L20-L129) is an upgradeable contract that does not protect its initialize functions: [ERC20X.initialize(string,string,address,address)](contracts/ERC20X.sol#L27-L33). Anyone can delete the contract with: [MulticallUpgradeable.multicall(bytes[])](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L23-L29)
contracts/ERC20X.sol#L20-L129


 - [ ] ID-13
[SyntheX](contracts/SyntheX.sol#L31-L797) is an upgradeable contract that does not protect its initialize functions: [SyntheX.initialize(address,uint256)](contracts/SyntheX.sol#L52-L60). Anyone can delete the contract with: [UUPSUpgradeable.upgradeTo(address)](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L72-L75)[UUPSUpgradeable.upgradeToAndCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L85-L88)
contracts/SyntheX.sol#L31-L797


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-14
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L124)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-15
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L121)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-16
[DebtPool.commitBurn(address,uint256)](contracts/DebtPool.sol#L298-L334) performs a multiplication on the result of a division:
	- [burnablePerc = debt.min(amountUSD).mul(1e18).div(amountUSD)](contracts/DebtPool.sol#L320-L321)
	- [amountUSD = amountUSD.mul(burnablePerc).div(1e18)](contracts/DebtPool.sol#L327)

contracts/DebtPool.sol#L298-L334


 - [ ] ID-17
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L126)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-18
[SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)](contracts/SyntheX.sol#L289-L331) performs a multiplication on the result of a division:
	- [siezePercent = accountCollateralBalance[_account][_outAsset].mul(1e18).div(_outAmount)](contracts/SyntheX.sol#L313)
	- [_outAmount = _outAmount.mul(siezePercent).div(1e18)](contracts/SyntheX.sol#L315)

contracts/SyntheX.sol#L289-L331


 - [ ] ID-19
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse = (3 * denominator) ^ 2](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L117)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-20
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L105)
	- [result = prod0 * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L132)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-21
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L124)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-22
[TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162) performs a multiplication on the result of a division:
	- [percentUnlock = timeSinceUnlock.mul(1e18).div(unlockPeriod)](contracts/token/TokenUnlocker.sol#L144)
	- [percentUnlock = percentUnlock.mul(BASIS_POINTS)](contracts/token/TokenUnlocker.sol#L151)

contracts/token/TokenUnlocker.sol#L134-L162


 - [ ] ID-23
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L122)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-24
[DebtPool.commitLiquidate(address,address,uint256,address)](contracts/DebtPool.sol#L384-L420) performs a multiplication on the result of a division:
	- [penalty = amountOut.mul(liquidationPenalty).div(BASIS_POINTS)](contracts/DebtPool.sol#L404)
	- [reserve = penalty.mul(liquidationFee).div(BASIS_POINTS)](contracts/DebtPool.sol#L406)

contracts/DebtPool.sol#L384-L420


 - [ ] ID-25
[SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)](contracts/SyntheX.sol#L289-L331) performs a multiplication on the result of a division:
	- [siezePercent = accountCollateralBalance[_account][_outAsset].mul(1e18).div(_outAmount)](contracts/SyntheX.sol#L313)
	- [_fee = _fee.mul(siezePercent).div(1e18)](contracts/SyntheX.sol#L317)

contracts/SyntheX.sol#L289-L331


 - [ ] ID-26
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L123)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-27
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L121)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-28
[TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162) performs a multiplication on the result of a division:
	- [percentUnlock = timeSinceUnlock.mul(1e18).div(unlockPeriod)](contracts/token/TokenUnlocker.sol#L144)
	- [amountToUnlock = unlockRequest.amount.mul(percentUnlock.add(percUnlockAtRelease).sub(percentUnlock.mul(percUnlockAtRelease).div(BASIS_POINTS).div(1e18))).div(1e18).div(BASIS_POINTS).sub(unlockRequest.claimed)](contracts/token/TokenUnlocker.sol#L155-L159)

contracts/token/TokenUnlocker.sol#L134-L162


 - [ ] ID-29
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse = (3 * denominator) ^ 2](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L117)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-30
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L130-L150) performs a multiplication on the result of a division:
	- [totalRewardsForIntervalPassed = uint256(timeDuration[msg.sender] - block.timestamp).div(lockInDuration)](contracts/token/Crowdsale.sol#L139)
	- [calculatedUnlockAmt = uint256(tokenMapping[_requestId]).mul(totalRewardsForIntervalPassed)](contracts/token/Crowdsale.sol#L140)

contracts/token/Crowdsale.sol#L130-L150


 - [ ] ID-31
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L123)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-32
[StakingRewards.notifyReward(uint256)](contracts/token/StakingRewards.sol#L174-L188) performs a multiplication on the result of a division:
	- [rewardRate = reward.div(rewardsDuration)](contracts/token/StakingRewards.sol#L177)
	- [leftover = remaining.mul(rewardRate)](contracts/token/StakingRewards.sol#L181)

contracts/token/StakingRewards.sol#L174-L188


 - [ ] ID-33
[DebtPool.commitBurn(address,uint256)](contracts/DebtPool.sol#L298-L334) performs a multiplication on the result of a division:
	- [burnablePerc = debt.min(amountUSD).mul(1e18).div(amountUSD)](contracts/DebtPool.sol#L320-L321)
	- [_amount = _amount.mul(burnablePerc).div(1e18)](contracts/DebtPool.sol#L326)

contracts/DebtPool.sol#L298-L334


 - [ ] ID-34
[SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)](contracts/SyntheX.sol#L289-L331) performs a multiplication on the result of a division:
	- [siezePercent = accountCollateralBalance[_account][_outAsset].mul(1e18).div(_outAmount)](contracts/SyntheX.sol#L313)
	- [_penalty = _penalty.mul(siezePercent).div(1e18)](contracts/SyntheX.sol#L316)

contracts/SyntheX.sol#L289-L331


 - [ ] ID-35
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L122)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-36
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L125)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-37
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L105)
	- [result = prod0 * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L132)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-38
[DebtPool.commitBurn(address,uint256)](contracts/DebtPool.sol#L298-L334) performs a multiplication on the result of a division:
	- [amountUSD = amountUSD.mul(burnablePerc).div(1e18)](contracts/DebtPool.sol#L327)
	- [burnAmount = totalSupply().mul(amountUSD).div(_totalDebt)](contracts/DebtPool.sol#L330)

contracts/DebtPool.sol#L298-L334


 - [ ] ID-39
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L126)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-40
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L125)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-41
[SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)](contracts/SyntheX.sol#L289-L331) uses a dangerous strict equality:
	- [require(bool,string)(transferredOutAmount == _fee,Fee transfer failed)](contracts/SyntheX.sol#L327)

contracts/SyntheX.sol#L289-L331


 - [ ] ID-42
[ERC20Votes._writeCheckpoint(ERC20Votes.Checkpoint[],function(uint256,uint256) returns(uint256),uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L239-L256) uses a dangerous strict equality:
	- [pos > 0 && oldCkpt.fromBlock == block.number](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L251)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L239-L256


 - [ ] ID-43
[SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L472-L487) uses a dangerous strict equality:
	- [deltaTimestamp == 0](contracts/SyntheX.sol#L477)

contracts/SyntheX.sol#L472-L487


 - [ ] ID-44
[ATokenWrapper.exchangeRate()](contracts/utils/ATokenWrapper.sol#L23-L25) uses a dangerous strict equality:
	- [totalSupply() == 0](contracts/utils/ATokenWrapper.sol#L24)

contracts/utils/ATokenWrapper.sol#L23-L25


 - [ ] ID-45
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) uses a dangerous strict equality:
	- [amountToUnlock == 0](contracts/token/TokenUnlocker.sol#L206)

contracts/token/TokenUnlocker.sol#L201-L223


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-46
Reentrancy in [SyntheX.claimReward(address,address[],address[])](contracts/SyntheX.sol#L547-L562):
	External calls:
	- [grantRewardInternal(_rewardToken,holders[j],rewardAccrued[_rewardToken][holders[j]])](contracts/SyntheX.sol#L559)
		- [SyntheXToken(_reward).mint(_user,_amount)](contracts/SyntheX.sol#L579)
		- [_rewardToken.transfer(_user,_amount)](contracts/SyntheX.sol#L586)
	State variables written after the call(s):
	- [rewardAccrued[_rewardToken][holders[j]] = 0](contracts/SyntheX.sol#L560)
	[SyntheXStorage.rewardAccrued](contracts/storage/SyntheXStorage.sol#L78) can be used in cross function reentrancies:
	- [SyntheX.claimReward(address,address[],address[])](contracts/SyntheX.sol#L547-L562)
	- [SyntheX.distributeAccountReward(address,address,address)](contracts/SyntheX.sol#L495-L526)
	- [SyntheX.getRewardsAccrued(address,address,address[])](contracts/SyntheX.sol#L599-L609)
	- [SyntheXStorage.rewardAccrued](contracts/storage/SyntheXStorage.sol#L78)

contracts/SyntheX.sol#L547-L562


 - [ ] ID-47
Reentrancy in [DebtPool.commitLiquidate(address,address,uint256,address)](contracts/DebtPool.sol#L384-L420):
	External calls:
	- [executedOut = SyntheX(system.synthex()).commitLiquidate(_account,_liquidator,_outAsset,amountOut,penalty,reserve)](contracts/DebtPool.sol#L409-L414)
	State variables written after the call(s):
	- [_burn(_account,totalSupply().mul(amountUSD).div(getTotalDebtUSD()))](contracts/DebtPool.sol#L417)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L298)
	[ERC20Upgradeable._balances](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L37) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable.balanceOf(address)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L106-L108)
	- [_burn(_account,totalSupply().mul(amountUSD).div(getTotalDebtUSD()))](contracts/DebtPool.sol#L417)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L300)
	[ERC20Upgradeable._totalSupply](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L41) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L99-L101)

contracts/DebtPool.sol#L384-L420


 - [ ] ID-48
Reentrancy in [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195):
	External calls:
	- [LOCKED_TOKEN.burnFrom(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L177)
	State variables written after the call(s):
	- [reservedForUnlock = reservedForUnlock.add(_amount)](contracts/token/TokenUnlocker.sol#L192)
	[TokenUnlocker.reservedForUnlock](contracts/token/TokenUnlocker.sol#L43) can be used in cross function reentrancies:
	- [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223)
	- [TokenUnlocker.remainingQuota()](contracts/token/TokenUnlocker.sol#L79-L81)
	- [TokenUnlocker.reservedForUnlock](contracts/token/TokenUnlocker.sol#L43)
	- [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195)

contracts/token/TokenUnlocker.sol#L171-L195


 - [ ] ID-49
Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
	State variables written after the call(s):
	- [_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L102)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L293)
	[ERC20._balances](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L36) can be used in cross function reentrancies:
	- [ERC20._burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301)
	- [ERC20._mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272)
	- [ERC20._transfer(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L226-L248)
	- [ERC20.balanceOf(address)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L101-L103)
	- [_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L104)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L293)
	[ERC20._balances](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L36) can be used in cross function reentrancies:
	- [ERC20._burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301)
	- [ERC20._mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272)
	- [ERC20._transfer(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L226-L248)
	- [ERC20.balanceOf(address)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L101-L103)
	- [_transfer(address(receiver),flashFeeReceiver,fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L105)
		- [_balances[from] = fromBalance - amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L239)
		- [_balances[to] += amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L242)
	[ERC20._balances](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L36) can be used in cross function reentrancies:
	- [ERC20._burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301)
	- [ERC20._mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272)
	- [ERC20._transfer(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L226-L248)
	- [ERC20.balanceOf(address)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L101-L103)
	- [_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L102)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L295)
	[ERC20._totalSupply](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L40) can be used in cross function reentrancies:
	- [ERC20._burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301)
	- [ERC20._mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272)
	- [ERC20.totalSupply()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L94-L96)
	- [_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L104)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L295)
	[ERC20._totalSupply](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L40) can be used in cross function reentrancies:
	- [ERC20._burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301)
	- [ERC20._mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272)
	- [ERC20.totalSupply()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L94-L96)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108


 - [ ] ID-50
Reentrancy in [SyntheX.deposit(address,uint256)](contracts/SyntheX.sol#L164-L195):
	External calls:
	- [ERC20Upgradeable(_collateral).safeTransferFrom(msg.sender,address(this),_amount)](contracts/SyntheX.sol#L184)
	State variables written after the call(s):
	- [supply.totalDeposits = supply.totalDeposits.add(_amount)](contracts/SyntheX.sol#L190)
	[SyntheXStorage.collateralSupplies](contracts/storage/SyntheXStorage.sol#L57) can be used in cross function reentrancies:
	- [SyntheXStorage.collateralSupplies](contracts/storage/SyntheXStorage.sol#L57)
	- [SyntheX.setCollateralCap(address,uint256)](contracts/SyntheX.sol#L418-L426)

contracts/SyntheX.sol#L164-L195


 - [ ] ID-51
Reentrancy in [Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L130-L150):
	External calls:
	- [token.transferFrom(wallet,msg.sender,calculatedUnlockAmt)](contracts/token/Crowdsale.sol#L144)
	State variables written after the call(s):
	- [timeDuration[msg.sender] = block.timestamp](contracts/token/Crowdsale.sol#L145)
	[Crowdsale.timeDuration](contracts/token/Crowdsale.sol#L56) can be used in cross function reentrancies:
	- [Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L82-L116)
	- [Crowdsale.timeDuration](contracts/token/Crowdsale.sol#L56)
	- [tokenBal[_requestId] = tokenBal[_requestId] - calculatedUnlockAmt](contracts/token/Crowdsale.sol#L146)
	[Crowdsale.tokenBal](contracts/token/Crowdsale.sol#L55) can be used in cross function reentrancies:
	- [Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L82-L116)
	- [Crowdsale.tokenBal](contracts/token/Crowdsale.sol#L55)

contracts/token/Crowdsale.sol#L130-L150


 - [ ] ID-52
Reentrancy in [StakingRewards.exit()](contracts/token/StakingRewards.sol#L163-L166):
	External calls:
	- [withdraw(balanceOf[msg.sender])](contracts/token/StakingRewards.sol#L164)
		- [ERC20Locked(stakingToken).mint(msg.sender,amount)](contracts/token/StakingRewards.sol#L142)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [ERC20Locked(rewardsToken).mint(msg.sender,reward)](contracts/token/StakingRewards.sol#L155)
	State variables written after the call(s):
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [_status = _NOT_ENTERED](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L67)
		- [_status = _ENTERED](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L61)
	[ReentrancyGuard._status](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L37) can be used in cross function reentrancies:
	- [ReentrancyGuard._nonReentrantAfter()](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L64-L68)
	- [ReentrancyGuard._nonReentrantBefore()](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L56-L62)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [lastUpdateTime = lastTimeRewardApplicable()](contracts/token/StakingRewards.sol#L72)
	[StakingRewards.lastUpdateTime](contracts/token/StakingRewards.sol#L34) can be used in cross function reentrancies:
	- [StakingRewards.lastUpdateTime](contracts/token/StakingRewards.sol#L34)
	- [StakingRewards.notifyReward(uint256)](contracts/token/StakingRewards.sol#L174-L188)
	- [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L95-L103)
	- [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L70-L78)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [rewardPerTokenStored = rewardPerToken()](contracts/token/StakingRewards.sol#L71)
	[StakingRewards.rewardPerTokenStored](contracts/token/StakingRewards.sol#L36) can be used in cross function reentrancies:
	- [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L95-L103)
	- [StakingRewards.rewardPerTokenStored](contracts/token/StakingRewards.sol#L36)
	- [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L70-L78)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [rewards[msg.sender] = 0](contracts/token/StakingRewards.sol#L154)
		- [rewards[account] = earned(account)](contracts/token/StakingRewards.sol#L74)
	[StakingRewards.rewards](contracts/token/StakingRewards.sol#L40) can be used in cross function reentrancies:
	- [StakingRewards.earned(address)](contracts/token/StakingRewards.sol#L108-L110)
	- [StakingRewards.getReward()](contracts/token/StakingRewards.sol#L150-L158)
	- [StakingRewards.rewards](contracts/token/StakingRewards.sol#L40)
	- [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L70-L78)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [userRewardPerTokenPaid[account] = rewardPerTokenStored](contracts/token/StakingRewards.sol#L75)
	[StakingRewards.userRewardPerTokenPaid](contracts/token/StakingRewards.sol#L38) can be used in cross function reentrancies:
	- [StakingRewards.earned(address)](contracts/token/StakingRewards.sol#L108-L110)
	- [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L70-L78)
	- [StakingRewards.userRewardPerTokenPaid](contracts/token/StakingRewards.sol#L38)

contracts/token/StakingRewards.sol#L163-L166


 - [ ] ID-53
Reentrancy in [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223):
	External calls:
	- [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)
	State variables written after the call(s):
	- [unlockRequests[_requestId].claimed = unlockRequests[_requestId].claimed.add(amountToUnlock)](contracts/token/TokenUnlocker.sol#L217)
	[TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L53) can be used in cross function reentrancies:
	- [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223)
	- [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195)
	- [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L53)
	- [TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-54
Reentrancy in [ERC20FlashMintUpgradeable.flashLoan(IERC3156FlashBorrowerUpgradeable,address,uint256,bytes)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L92-L114):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L101-L104)
	State variables written after the call(s):
	- [_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L108)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L298)
	[ERC20Upgradeable._balances](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L37) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable._transfer(address,address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L231-L253)
	- [ERC20Upgradeable.balanceOf(address)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L106-L108)
	- [_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L110)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L298)
	[ERC20Upgradeable._balances](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L37) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable._transfer(address,address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L231-L253)
	- [ERC20Upgradeable.balanceOf(address)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L106-L108)
	- [_transfer(address(receiver),flashFeeReceiver,fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L111)
		- [_balances[from] = fromBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L244)
		- [_balances[to] += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L247)
	[ERC20Upgradeable._balances](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L37) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable._transfer(address,address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L231-L253)
	- [ERC20Upgradeable.balanceOf(address)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L106-L108)
	- [_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L108)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L300)
	[ERC20Upgradeable._totalSupply](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L41) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L99-L101)
	- [_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L110)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L300)
	[ERC20Upgradeable._totalSupply](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L41) can be used in cross function reentrancies:
	- [ERC20Upgradeable._burn(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L290-L306)
	- [ERC20Upgradeable._mint(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L264-L277)
	- [ERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L99-L101)

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L92-L114


## tautology
Impact: Medium
Confidence: High
 - [ ] ID-55
[PriceOracle.setFeed(address,address)](contracts/oracle/PriceOracle.sol#L28-L45) contains a tautology or contradiction:
	- [require(bool,string)(feeds[_token].decimals() >= 0,PriceOracle: Decimals is <= 0)](contracts/oracle/PriceOracle.sol#L41)

contracts/oracle/PriceOracle.sol#L28-L45


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-56
[ERC20Votes._moveVotingPower(address,address,uint256).oldWeight_scope_0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233) is a local variable never initialized

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233


 - [ ] ID-57
[ERC20Votes._moveVotingPower(address,address,uint256).newWeight_scope_1](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233) is a local variable never initialized

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233


 - [ ] ID-58
[ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98) is a local variable never initialized

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-59
[ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105) ignores return value by [IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98-L102)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-60
[MockToken.constructor(string,string,uint256).name](contracts/mock/MockToken.sol#L10) shadows:
	- [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function)
	- [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

contracts/mock/MockToken.sol#L10


 - [ ] ID-61
[ERC20Permit.constructor(string).name](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L44) shadows:
	- [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function)
	- [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L44


 - [ ] ID-62
[MockToken.constructor(string,string,uint256).symbol](contracts/mock/MockToken.sol#L10) shadows:
	- [ERC20.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L70-L72) (function)
	- [IERC20Metadata.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L22) (function)

contracts/mock/MockToken.sol#L10


 - [ ] ID-63
[ATokenWrapper.constructor(string,string,IERC20)._name](contracts/utils/ATokenWrapper.sol#L19) shadows:
	- [ERC20._name](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L42) (state variable)

contracts/utils/ATokenWrapper.sol#L19


 - [ ] ID-64
[ATokenWrapper.constructor(string,string,IERC20)._symbol](contracts/utils/ATokenWrapper.sol#L19) shadows:
	- [ERC20._symbol](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L43) (state variable)

contracts/utils/ATokenWrapper.sol#L19


 - [ ] ID-65
[DebtPool.initialize(string,string,address).symbol](contracts/DebtPool.sol#L37) shadows:
	- [ERC20Upgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L75-L77) (function)
	- [IERC20MetadataUpgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L22) (function)

contracts/DebtPool.sol#L37


 - [ ] ID-66
[ERC20X.initialize(string,string,address,address).name](contracts/ERC20X.sol#L27) shadows:
	- [ERC20Upgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L67-L69) (function)
	- [IERC20MetadataUpgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L17) (function)

contracts/ERC20X.sol#L27


 - [ ] ID-67
[ERC20X.initialize(string,string,address,address).symbol](contracts/ERC20X.sol#L27) shadows:
	- [ERC20Upgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L75-L77) (function)
	- [IERC20MetadataUpgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L22) (function)

contracts/ERC20X.sol#L27


 - [ ] ID-68
[DebtPool.initialize(string,string,address).name](contracts/DebtPool.sol#L37) shadows:
	- [ERC20Upgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L67-L69) (function)
	- [IERC20MetadataUpgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L17) (function)

contracts/DebtPool.sol#L37


## events-maths
Impact: Low
Confidence: Medium
 - [ ] ID-69
[Crowdsale.updateRate(uint256)](contracts/token/Crowdsale.sol#L119-L121) should emit an event for: 
	- [rate = _rate](contracts/token/Crowdsale.sol#L120) 

contracts/token/Crowdsale.sol#L119-L121


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-70
[SecondaryOracle.constructor(address,address)._primaryOracle](contracts/oracle/SecondaryOracle.sol#L17) lacks a zero-check on :
		- [PRIMARY_ORACLE = _primaryOracle](contracts/oracle/SecondaryOracle.sol#L18)

contracts/oracle/SecondaryOracle.sol#L17


 - [ ] ID-71
[Crowdsale.constructor(address,address,uint256,uint256,uint256,uint256,uint256)._adminWallet](contracts/token/Crowdsale.sol#L70) lacks a zero-check on :
		- [wallet = _adminWallet](contracts/token/Crowdsale.sol#L72)

contracts/token/Crowdsale.sol#L70


 - [ ] ID-72
[StakingRewards.constructor(address,address,address,uint256)._rewardsToken](contracts/token/StakingRewards.sol#L52) lacks a zero-check on :
		- [rewardsToken = _rewardsToken](contracts/token/StakingRewards.sol#L57)

contracts/token/StakingRewards.sol#L52


 - [ ] ID-73
[AAVEOracle.constructor(address,address,uint256)._underlying](contracts/oracle/AAVEOracle.sol#L18) lacks a zero-check on :
		- [underlying = _underlying](contracts/oracle/AAVEOracle.sol#L19)

contracts/oracle/AAVEOracle.sol#L18


 - [ ] ID-74
[StakingRewards.constructor(address,address,address,uint256)._stakingToken](contracts/token/StakingRewards.sol#L53) lacks a zero-check on :
		- [stakingToken = _stakingToken](contracts/token/StakingRewards.sol#L58)

contracts/token/StakingRewards.sol#L53


 - [ ] ID-75
[SecondaryOracle.constructor(address,address)._secondaryOracle](contracts/oracle/SecondaryOracle.sol#L17) lacks a zero-check on :
		- [SECONDARY_ORACLE = _secondaryOracle](contracts/oracle/SecondaryOracle.sol#L19)

contracts/oracle/SecondaryOracle.sol#L17


 - [ ] ID-76
[DebtPool.updateFeeToken(address)._feeToken](contracts/DebtPool.sol#L146) lacks a zero-check on :
		- [feeToken = _feeToken](contracts/DebtPool.sol#L147)

contracts/DebtPool.sol#L146


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-77
[PriceOracle.getAssetPrice(address)](contracts/oracle/PriceOracle.sol#L60-L71) has external calls inside a loop: [decimals = _feed.decimals()](contracts/oracle/PriceOracle.sol#L63)

contracts/oracle/PriceOracle.sol#L60-L71


 - [ ] ID-78
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has external calls inside a loop: [TOKEN.balanceOf(address(this)) < amountToUnlock](contracts/token/TokenUnlocker.sol#L211)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-79
[SyntheX.getAccountLiquidity(address)](contracts/SyntheX.sol#L678-L706) has external calls inside a loop: [totalDebt = totalDebt.add(DebtPool(_accountPools[i_scope_0]).getUserDebtUSD(_account))](contracts/SyntheX.sol#L703)

contracts/SyntheX.sol#L678-L706


 - [ ] ID-80
[SyntheX.getAccountLiquidity(address)](contracts/SyntheX.sol#L678-L706) has external calls inside a loop: [price = _oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L688)

contracts/SyntheX.sol#L678-L706


 - [ ] ID-81
[SyntheX.getAdjustedAccountLiquidity(address)](contracts/SyntheX.sol#L713-L749) has external calls inside a loop: [totalDebt = totalDebt.add(DebtPool(_accountPools[i_scope_0]).getUserDebtUSD(_account).mul(1e18).div(tradingPools[_accountPools[i_scope_0]].volatilityRatio))](contracts/SyntheX.sol#L742-L746)

contracts/SyntheX.sol#L713-L749


 - [ ] ID-82
[DebtPool.getTotalDebtUSD()](contracts/DebtPool.sol#L197-L212) has external calls inside a loop: [price = _oracle.getAssetPrice(synth)](contracts/DebtPool.sol#L207)

contracts/DebtPool.sol#L197-L212


 - [ ] ID-83
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L571-L593) has external calls inside a loop: [rewardRemaining = _rewardToken.balanceOf(address(this))](contracts/SyntheX.sol#L583)

contracts/SyntheX.sol#L571-L593


 - [ ] ID-84
[Multicall2.tryAggregate(bool,Multicall2.Call[])](contracts/utils/Multicall2.sol#L56-L67) has external calls inside a loop: [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L59)

contracts/utils/Multicall2.sol#L56-L67


 - [ ] ID-85
[SyntheX._getAccountLiquidity(address)](contracts/SyntheX.sol#L751-L795) has external calls inside a loop: [price = _oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L765)

contracts/SyntheX.sol#L751-L795


 - [ ] ID-86
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L571-L593) has external calls inside a loop: [_rewardToken.transfer(_user,_amount)](contracts/SyntheX.sol#L586)

contracts/SyntheX.sol#L571-L593


 - [ ] ID-87
[DebtPool.getTotalDebtUSD()](contracts/DebtPool.sol#L197-L212) has external calls inside a loop: [totalDebt = totalDebt.add(ERC20X(synth).totalSupply().mul(price.price).div(10 ** price.decimals))](contracts/DebtPool.sol#L209)

contracts/DebtPool.sol#L197-L212


 - [ ] ID-88
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L571-L593) has external calls inside a loop: [SyntheXToken(_reward).mint(_user,_amount)](contracts/SyntheX.sol#L579)

contracts/SyntheX.sol#L571-L593


 - [ ] ID-89
[SyntheX.distributeAccountReward(address,address,address)](contracts/SyntheX.sol#L495-L526) has external calls inside a loop: [accountDebtTokens = DebtPool(_debtPool).balanceOf(_account)](contracts/SyntheX.sol#L517)

contracts/SyntheX.sol#L495-L526


 - [ ] ID-90
[MulticallUpgradeable._functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L37-L43) has external calls inside a loop: [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L41)

node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L37-L43


 - [ ] ID-91
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has external calls inside a loop: [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-92
[SyntheX._getAccountLiquidity(address)](contracts/SyntheX.sol#L751-L795) has external calls inside a loop: [totalAdjustedDebt = totalAdjustedDebt.add(DebtPool(_accountPools[i_scope_0]).getUserDebtUSD(_account).mul(1e18).div(tradingPools[_accountPools[i_scope_0]].volatilityRatio))](contracts/SyntheX.sol#L786-L790)

contracts/SyntheX.sol#L751-L795


 - [ ] ID-93
[SyntheX.getAdjustedAccountLiquidity(address)](contracts/SyntheX.sol#L713-L749) has external calls inside a loop: [price = _oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L723)

contracts/SyntheX.sol#L713-L749


 - [ ] ID-94
[SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L472-L487) has external calls inside a loop: [borrowAmount = DebtPool(_tradingPool).totalSupply()](contracts/SyntheX.sol#L479)

contracts/SyntheX.sol#L472-L487


 - [ ] ID-95
[Multicall2.aggregate(Multicall2.Call[])](contracts/utils/Multicall2.sol#L20-L28) has external calls inside a loop: [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L24)

contracts/utils/Multicall2.sol#L20-L28


 - [ ] ID-96
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has external calls inside a loop: [amountToUnlock = TOKEN.balanceOf(address(this))](contracts/token/TokenUnlocker.sol#L212)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-97
[SyntheX._getAccountLiquidity(address)](contracts/SyntheX.sol#L751-L795) has external calls inside a loop: [totalDebt = totalDebt.add(DebtPool(_accountPools[i_scope_0]).getUserDebtUSD(_account))](contracts/SyntheX.sol#L792)

contracts/SyntheX.sol#L751-L795


 - [ ] ID-98
[PriceOracle.getAssetPrice(address)](contracts/oracle/PriceOracle.sol#L60-L71) has external calls inside a loop: [price = _feed.latestAnswer()](contracts/oracle/PriceOracle.sol#L62)

contracts/oracle/PriceOracle.sol#L60-L71


## variable-scope
Impact: Low
Confidence: High
 - [ ] ID-99
Variable '[ERC20Votes._moveVotingPower(address,address,uint256).oldWeight](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228)' in [ERC20Votes._moveVotingPower(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L221-L237) potentially used before declaration: [(oldWeight,newWeight) = _writeCheckpoint(_checkpoints[dst],_add,amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228


 - [ ] ID-100
Variable '[ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98)' in [ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105) potentially used before declaration: [require(bool,string)(slot == _IMPLEMENTATION_SLOT,ERC1967Upgrade: unsupported proxiableUUID)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L99)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98


 - [ ] ID-101
Variable '[ERC20Votes._moveVotingPower(address,address,uint256).newWeight](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228)' in [ERC20Votes._moveVotingPower(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L221-L237) potentially used before declaration: [(oldWeight,newWeight) = _writeCheckpoint(_checkpoints[dst],_add,amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-102
Reentrancy in [ERC20X.swap(uint256,address)](contracts/ERC20X.sol#L69-L73):
	External calls:
	- [amount = pool.commitSwap(msg.sender,amount,synthTo)](contracts/ERC20X.sol#L71)
	State variables written after the call(s):
	- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L72)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L298)
	- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L72)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L300)

contracts/ERC20X.sol#L69-L73


 - [ ] ID-103
Reentrancy in [ERC20FlashMintUpgradeable.flashLoan(IERC3156FlashBorrowerUpgradeable,address,uint256,bytes)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L92-L114):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L101-L104)
	State variables written after the call(s):
	- [_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L106)
		- [_allowances[owner][spender] = amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L329)

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L92-L114


 - [ ] ID-104
Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
	State variables written after the call(s):
	- [_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L100)
		- [_allowances[owner][spender] = amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L324)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108


 - [ ] ID-105
Reentrancy in [DebtPool.commitMint(address,uint256)](contracts/DebtPool.sol#L237-L288):
	External calls:
	- [borrowCapacity = ISyntheX(system.synthex()).commitMint(_account,msg.sender,_amount)](contracts/DebtPool.sol#L247)
	State variables written after the call(s):
	- [_mint(_account,amountUSD)](contracts/DebtPool.sol#L257)
		- [_balances[account] += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L272)
	- [_mint(_account,mintAmount)](contracts/DebtPool.sol#L266)
		- [_balances[account] += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L272)
	- [_mint(_account,amountUSD)](contracts/DebtPool.sol#L257)
		- [_totalSupply += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L269)
	- [_mint(_account,mintAmount)](contracts/DebtPool.sol#L266)
		- [_totalSupply += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L269)

contracts/DebtPool.sol#L237-L288


 - [ ] ID-106
Reentrancy in [SyntheX.deposit(address,uint256)](contracts/SyntheX.sol#L164-L195):
	External calls:
	- [ERC20Upgradeable(_collateral).safeTransferFrom(msg.sender,address(this),_amount)](contracts/SyntheX.sol#L184)
	State variables written after the call(s):
	- [accountCollateralBalance[msg.sender][_collateral] = accountCollateralBalance[msg.sender][_collateral].add(_amount)](contracts/SyntheX.sol#L187)

contracts/SyntheX.sol#L164-L195


 - [ ] ID-107
Reentrancy in [ERC20X.burn(uint256)](contracts/ERC20X.sol#L58-L62):
	External calls:
	- [amount = pool.commitBurn(msg.sender,amount)](contracts/ERC20X.sol#L60)
	State variables written after the call(s):
	- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L61)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L298)
	- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L61)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L300)

contracts/ERC20X.sol#L58-L62


 - [ ] ID-108
Reentrancy in [ERC20X.liquidate(address,uint256,address)](contracts/ERC20X.sol#L78-L82):
	External calls:
	- [amount = pool.commitLiquidate(msg.sender,account,amount,outAsset)](contracts/ERC20X.sol#L80)
	State variables written after the call(s):
	- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L81)
		- [_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L298)
	- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L81)
		- [_totalSupply -= amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L300)

contracts/ERC20X.sol#L78-L82


 - [ ] ID-109
Reentrancy in [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223):
	External calls:
	- [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)
	State variables written after the call(s):
	- [reservedForUnlock = reservedForUnlock.sub(amountToUnlock)](contracts/token/TokenUnlocker.sol#L220)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-110
Reentrancy in [ERC20X.mint(uint256)](contracts/ERC20X.sol#L47-L52):
	External calls:
	- [amount = pool.commitMint(msg.sender,amount)](contracts/ERC20X.sol#L50)
	State variables written after the call(s):
	- [_mint(msg.sender,amount)](contracts/ERC20X.sol#L51)
		- [_balances[account] += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L272)
	- [_mint(msg.sender,amount)](contracts/ERC20X.sol#L51)
		- [_totalSupply += amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L269)

contracts/ERC20X.sol#L47-L52


 - [ ] ID-111
Reentrancy in [ATokenWrapper.deposit(uint256)](contracts/utils/ATokenWrapper.sol#L35-L38):
	External calls:
	- [underlying.transferFrom(msg.sender,address(this),amount)](contracts/utils/ATokenWrapper.sol#L36)
	State variables written after the call(s):
	- [_mint(msg.sender,amountToShares(amount))](contracts/utils/ATokenWrapper.sol#L37)
		- [_balances[account] += amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L267)
	- [_mint(msg.sender,amountToShares(amount))](contracts/utils/ATokenWrapper.sol#L37)
		- [_totalSupply += amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L264)

contracts/utils/ATokenWrapper.sol#L35-L38


 - [ ] ID-112
Reentrancy in [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195):
	External calls:
	- [LOCKED_TOKEN.burnFrom(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L177)
	State variables written after the call(s):
	- [unlockRequestCount[msg.sender] ++](contracts/token/TokenUnlocker.sol#L189)
	- [_unlockRequest.amount = _amount](contracts/token/TokenUnlocker.sol#L184)
	- [_unlockRequest.requestTime = block.timestamp](contracts/token/TokenUnlocker.sol#L185)
	- [_unlockRequest.claimed = 0](contracts/token/TokenUnlocker.sol#L186)

contracts/token/TokenUnlocker.sol#L171-L195


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-113
Reentrancy in [ERC20X.mint(uint256)](contracts/ERC20X.sol#L47-L52):
	External calls:
	- [amount = pool.commitMint(msg.sender,amount)](contracts/ERC20X.sol#L50)
	Event emitted after the call(s):
	- [Transfer(address(0),account,amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L274)
		- [_mint(msg.sender,amount)](contracts/ERC20X.sol#L51)

contracts/ERC20X.sol#L47-L52


 - [ ] ID-114
Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
	Event emitted after the call(s):
	- [Approval(owner,spender,amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L325)
		- [_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L100)
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L298)
		- [_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L104)
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L298)
		- [_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L102)
	- [Transfer(from,to,amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L245)
		- [_transfer(address(receiver),flashFeeReceiver,fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L105)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108


 - [ ] ID-115
Reentrancy in [ERC20X.liquidate(address,uint256,address)](contracts/ERC20X.sol#L78-L82):
	External calls:
	- [amount = pool.commitLiquidate(msg.sender,account,amount,outAsset)](contracts/ERC20X.sol#L80)
	Event emitted after the call(s):
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L303)
		- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L81)

contracts/ERC20X.sol#L78-L82


 - [ ] ID-116
Reentrancy in [DebtPool.commitLiquidate(address,address,uint256,address)](contracts/DebtPool.sol#L384-L420):
	External calls:
	- [executedOut = SyntheX(system.synthex()).commitLiquidate(_account,_liquidator,_outAsset,amountOut,penalty,reserve)](contracts/DebtPool.sol#L409-L414)
	Event emitted after the call(s):
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L303)
		- [_burn(_account,totalSupply().mul(amountUSD).div(getTotalDebtUSD()))](contracts/DebtPool.sol#L417)

contracts/DebtPool.sol#L384-L420


 - [ ] ID-117
Reentrancy in [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195):
	External calls:
	- [LOCKED_TOKEN.burnFrom(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L177)
	Event emitted after the call(s):
	- [UnlockRequested(msg.sender,requestId,_amount)](contracts/token/TokenUnlocker.sol#L194)

contracts/token/TokenUnlocker.sol#L171-L195


 - [ ] ID-118
Reentrancy in [ERC20X.burn(uint256)](contracts/ERC20X.sol#L58-L62):
	External calls:
	- [amount = pool.commitBurn(msg.sender,amount)](contracts/ERC20X.sol#L60)
	Event emitted after the call(s):
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L303)
		- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L61)

contracts/ERC20X.sol#L58-L62


 - [ ] ID-119
Reentrancy in [StakingRewards.exit()](contracts/token/StakingRewards.sol#L163-L166):
	External calls:
	- [withdraw(balanceOf[msg.sender])](contracts/token/StakingRewards.sol#L164)
		- [ERC20Locked(stakingToken).mint(msg.sender,amount)](contracts/token/StakingRewards.sol#L142)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [ERC20Locked(rewardsToken).mint(msg.sender,reward)](contracts/token/StakingRewards.sol#L155)
	Event emitted after the call(s):
	- [RewardPaid(msg.sender,reward)](contracts/token/StakingRewards.sol#L156)
		- [getReward()](contracts/token/StakingRewards.sol#L165)

contracts/token/StakingRewards.sol#L163-L166


 - [ ] ID-120
Reentrancy in [ERC20X.swap(uint256,address)](contracts/ERC20X.sol#L69-L73):
	External calls:
	- [amount = pool.commitSwap(msg.sender,amount,synthTo)](contracts/ERC20X.sol#L71)
	Event emitted after the call(s):
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L303)
		- [_burn(msg.sender,amount)](contracts/ERC20X.sol#L72)

contracts/ERC20X.sol#L69-L73


 - [ ] ID-121
Reentrancy in [ERC20FlashMintUpgradeable.flashLoan(IERC3156FlashBorrowerUpgradeable,address,uint256,bytes)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L92-L114):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L101-L104)
	Event emitted after the call(s):
	- [Approval(owner,spender,amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L330)
		- [_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L106)
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L303)
		- [_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L110)
	- [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L303)
		- [_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L108)
	- [Transfer(from,to,amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L250)
		- [_transfer(address(receiver),flashFeeReceiver,fee)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L111)

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L92-L114


 - [ ] ID-122
Reentrancy in [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223):
	External calls:
	- [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)
	Event emitted after the call(s):
	- [Unlocked(msg.sender,_requestId,amountToUnlock)](contracts/token/TokenUnlocker.sol#L222)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-123
Reentrancy in [DebtPool.commitMint(address,uint256)](contracts/DebtPool.sol#L237-L288):
	External calls:
	- [borrowCapacity = ISyntheX(system.synthex()).commitMint(_account,msg.sender,_amount)](contracts/DebtPool.sol#L247)
	Event emitted after the call(s):
	- [Transfer(address(0),account,amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L274)
		- [_mint(_account,mintAmount)](contracts/DebtPool.sol#L266)
	- [Transfer(address(0),account,amount)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L274)
		- [_mint(_account,amountUSD)](contracts/DebtPool.sol#L257)

contracts/DebtPool.sol#L237-L288


 - [ ] ID-124
Reentrancy in [ATokenWrapper.deposit(uint256)](contracts/utils/ATokenWrapper.sol#L35-L38):
	External calls:
	- [underlying.transferFrom(msg.sender,address(this),amount)](contracts/utils/ATokenWrapper.sol#L36)
	Event emitted after the call(s):
	- [Transfer(address(0),account,amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L269)
		- [_mint(msg.sender,amountToShares(amount))](contracts/utils/ATokenWrapper.sol#L37)

contracts/utils/ATokenWrapper.sol#L35-L38


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-125
[ERC20Permit.permit(address,address,uint256,uint256,uint8,bytes32,bytes32)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L49-L68) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp <= deadline,ERC20Permit: expired deadline)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L58)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L49-L68


 - [ ] ID-126
[ERC20Votes.delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L146-L163) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp <= expiry,ERC20Votes: signature expired)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L154)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L146-L163


 - [ ] ID-127
[TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(remainingQuota() >= _amount,Not enough SYN to unlock)](contracts/token/TokenUnlocker.sol#L173)
	- [require(bool,string)(_unlockRequest.amount == 0,Unlock request already exists)](contracts/token/TokenUnlocker.sol#L183)

contracts/token/TokenUnlocker.sol#L171-L195


 - [ ] ID-128
[Crowdsale.closeSale()](contracts/token/Crowdsale.sol#L123-L126) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool)(block.timestamp < endTime)](contracts/token/Crowdsale.sol#L124)

contracts/token/Crowdsale.sol#L123-L126


 - [ ] ID-129
[SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L472-L487) uses timestamp for comparisons
	Dangerous comparisons:
	- [deltaTimestamp == 0](contracts/SyntheX.sol#L477)

contracts/SyntheX.sol#L472-L487


 - [ ] ID-130
[StakingRewards.getReward()](contracts/token/StakingRewards.sol#L150-L158) uses timestamp for comparisons
	Dangerous comparisons:
	- [reward > 0](contracts/token/StakingRewards.sol#L153)

contracts/token/StakingRewards.sol#L150-L158


 - [ ] ID-131
[StakingRewards.setRewardsDuration(uint256)](contracts/token/StakingRewards.sol#L193-L201) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp > periodFinish,Previous rewards period must be complete before changing the duration for the new period)](contracts/token/StakingRewards.sol#L195-L198)

contracts/token/StakingRewards.sol#L193-L201


 - [ ] ID-132
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L130-L150) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)((timeDuration[msg.sender] - block.timestamp) > (lockInDuration / unlockIntervals),cannot unlock before lockInPeriod)](contracts/token/Crowdsale.sol#L132)
	- [require(bool)(calculatedUnlockAmt > 0 && tokenBal[_requestId] != 0)](contracts/token/Crowdsale.sol#L142)

contracts/token/Crowdsale.sol#L130-L150


 - [ ] ID-133
[TokenUnlocker.withdraw(uint256)](contracts/token/TokenUnlocker.sol#L108-L111) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(_amount <= remainingQuota(),Not enough SYN to withdraw)](contracts/token/TokenUnlocker.sol#L109)

contracts/token/TokenUnlocker.sol#L108-L111


 - [ ] ID-134
[StakingRewards.lastTimeRewardApplicable()](contracts/token/StakingRewards.sol#L88-L90) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp < periodFinish](contracts/token/StakingRewards.sol#L89)

contracts/token/StakingRewards.sol#L88-L90


 - [ ] ID-135
[Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L82-L116) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp < startTime && block.timestamp > endTime](contracts/token/Crowdsale.sol#L87)

contracts/token/Crowdsale.sol#L82-L116


 - [ ] ID-136
[TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(unlockRequest.amount > 0,Unlock request does not exist)](contracts/token/TokenUnlocker.sol#L137)
	- [require(bool,string)(block.timestamp >= unlockRequest.requestTime.add(lockPeriod),Unlock period has not passed)](contracts/token/TokenUnlocker.sol#L139)
	- [percentUnlock > 1e18](contracts/token/TokenUnlocker.sol#L147)

contracts/token/TokenUnlocker.sol#L134-L162


 - [ ] ID-137
[StakingRewards.notifyReward(uint256)](contracts/token/StakingRewards.sol#L174-L188) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp >= periodFinish](contracts/token/StakingRewards.sol#L176)

contracts/token/StakingRewards.sol#L174-L188


 - [ ] ID-138
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) uses timestamp for comparisons
	Dangerous comparisons:
	- [amountToUnlock == 0](contracts/token/TokenUnlocker.sol#L206)
	- [TOKEN.balanceOf(address(this)) < amountToUnlock](contracts/token/TokenUnlocker.sol#L211)

contracts/token/TokenUnlocker.sol#L201-L223


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-139
[AddressUpgradeable._revert(bytes,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L206-L218) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L211-L214)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L206-L218


 - [ ] ID-140
[StorageSlotUpgradeable.getAddressSlot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L52-L57) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L54-L56)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L52-L57


 - [ ] ID-141
[ECDSA.tryRecover(bytes32,bytes)](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L55-L72) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L63-L67)

node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L55-L72


 - [ ] ID-142
[StorageSlotUpgradeable.getBytes32Slot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L72-L77) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L74-L76)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L72-L77


 - [ ] ID-143
[console._sendLogPayload(bytes)](node_modules/hardhat/console.sol#L7-L14) uses assembly
	- [INLINE ASM](node_modules/hardhat/console.sol#L10-L13)

node_modules/hardhat/console.sol#L7-L14


 - [ ] ID-144
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L66-L70)
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L86-L93)
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L100-L109)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-145
[StorageSlotUpgradeable.getBooleanSlot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L62-L67) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L64-L66)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L62-L67


 - [ ] ID-146
[Strings.toString(uint256)](node_modules/@openzeppelin/contracts/utils/Strings.sol#L18-L38) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Strings.sol#L24-L26)
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Strings.sol#L30-L32)

node_modules/@openzeppelin/contracts/utils/Strings.sol#L18-L38


 - [ ] ID-147
[StringsUpgradeable.toString(uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L18-L38) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L24-L26)
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L30-L32)

node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L18-L38


 - [ ] ID-148
[Address._revert(bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L231-L243) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Address.sol#L236-L239)

node_modules/@openzeppelin/contracts/utils/Address.sol#L231-L243


 - [ ] ID-149
[StorageSlotUpgradeable.getUint256Slot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L82-L87) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L84-L86)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L82-L87


 - [ ] ID-150
[ERC20Votes._unsafeAccess(ERC20Votes.Checkpoint[],uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L269-L274) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L270-L273)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L269-L274


 - [ ] ID-151
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L66-L70)
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L86-L93)
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L100-L109)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-152
Different versions of Solidity are used:
	- Version used: ['>=0.4.22<0.9.0', '^0.8.0', '^0.8.1', '^0.8.10', '^0.8.2']
	- [>=0.4.22<0.9.0](node_modules/hardhat/console.sol#L2)
	- [ABIEncoderV2](contracts/utils/Multicall2.sol#L3)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IAaveIncentivesController.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IInitializableAToken.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IPriceOracle.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IScaledBalanceToken.sol#L2)
	- [^0.8.0](node_modules/@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol#L2)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashBorrowerUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3)
	- [^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/security/Pausable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5)
	- [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4)
	- [^0.8.0](contracts/DebtPool.sol#L2)
	- [^0.8.0](contracts/ERC20X.sol#L2)
	- [^0.8.0](contracts/SyntheX.sol#L2)
	- [^0.8.0](contracts/System.sol#L2)
	- [^0.8.0](contracts/interfaces/IChainlinkAggregator.sol#L2)
	- [^0.8.0](contracts/interfaces/IDebtPool.sol#L2)
	- [^0.8.0](contracts/interfaces/IPriceOracle.sol#L2)
	- [^0.8.0](contracts/interfaces/IStaking.sol#L2)
	- [^0.8.0](contracts/interfaces/ISyntheX.sol#L2)
	- [^0.8.0](contracts/mock/MockPriceFeed.sol#L2)
	- [^0.8.0](contracts/mock/MockToken.sol#L2)
	- [^0.8.0](contracts/oracle/AAVEOracle.sol#L2)
	- [^0.8.0](contracts/oracle/CompOracle.sol#L2)
	- [^0.8.0](contracts/oracle/PriceOracle.sol#L2)
	- [^0.8.0](contracts/oracle/SecondaryOracle.sol#L2)
	- [^0.8.0](contracts/storage/DebtPoolStorage.sol#L2)
	- [^0.8.0](contracts/storage/ERC20XStorage.sol#L2)
	- [^0.8.0](contracts/storage/SyntheXStorage.sol#L2)
	- [^0.8.0](contracts/token/Crowdsale.sol#L2)
	- [^0.8.0](contracts/token/ERC20Locked.sol#L2)
	- [^0.8.0](contracts/token/LockedSYN.sol#L2)
	- [^0.8.0](contracts/token/StakingRewards.sol#L2)
	- [^0.8.0](contracts/token/SyntheXToken.sol#L2)
	- [^0.8.0](contracts/token/TokenUnlocker.sol#L2)
	- [^0.8.0](contracts/utils/ATokenWrapper.sol#L2)
	- [^0.8.0](contracts/utils/AddressStorage.sol#L2)
	- [^0.8.0](contracts/utils/FeeVault.sol#L2)
	- [^0.8.0](contracts/utils/Multicall2.sol#L2)
	- [^0.8.0](contracts/utils/PriceConvertor.sol#L2)
	- [^0.8.1](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4)
	- [^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4)
	- [^0.8.10](contracts/interfaces/compound/CTokenInterface.sol#L2)
	- [^0.8.10](contracts/interfaces/compound/ComptrollerInterface.sol#L2)
	- [^0.8.10](contracts/interfaces/compound/IPriceOracle.sol#L2)
	- [^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4)
	- [^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4)

node_modules/hardhat/console.sol#L2


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-153
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has costly operations inside a loop:
	- [reservedForUnlock = reservedForUnlock.sub(amountToUnlock)](contracts/token/TokenUnlocker.sol#L220)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-154
[ReentrancyGuardUpgradeable._nonReentrantAfter()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73) has costly operations inside a loop:
	- [_status = _NOT_ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L72)

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73


 - [ ] ID-155
[DebtPool.removeSynth(address)](contracts/DebtPool.sol#L171-L181) has costly operations inside a loop:
	- [synthsList.pop()](contracts/DebtPool.sol#L176)

contracts/DebtPool.sol#L171-L181


 - [ ] ID-156
[ReentrancyGuardUpgradeable._nonReentrantBefore()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67) has costly operations inside a loop:
	- [_status = _ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L66)

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-157
solc-0.4.18 is not recommended for deployment

 - [ ] ID-158
Pragma version[^0.4.18](contracts/utils/WETH9.sol#L20) allows old versions

contracts/utils/WETH9.sol#L20


 - [ ] ID-159
Pragma version[^0.8.0](contracts/mock/MockToken.sol#L2) allows old versions

contracts/mock/MockToken.sol#L2


 - [ ] ID-160
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4


 - [ ] ID-161
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4


 - [ ] ID-162
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4


 - [ ] ID-163
Pragma version[^0.8.0](contracts/System.sol#L2) allows old versions

contracts/System.sol#L2


 - [ ] ID-164
Pragma version[^0.8.0](contracts/utils/FeeVault.sol#L2) allows old versions

contracts/utils/FeeVault.sol#L2


 - [ ] ID-165
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4


 - [ ] ID-166
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4


 - [ ] ID-167
Pragma version[^0.8.0](contracts/SyntheX.sol#L2) allows old versions

contracts/SyntheX.sol#L2


 - [ ] ID-168
Pragma version[^0.8.0](contracts/token/TokenUnlocker.sol#L2) allows old versions

contracts/token/TokenUnlocker.sol#L2


 - [ ] ID-169
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol#L4


 - [ ] ID-170
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4


 - [ ] ID-171
Pragma version[^0.8.0](contracts/interfaces/IDebtPool.sol#L2) allows old versions

contracts/interfaces/IDebtPool.sol#L2


 - [ ] ID-172
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4


 - [ ] ID-173
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Context.sol#L4


 - [ ] ID-174
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4


 - [ ] ID-175
Pragma version[^0.8.0](contracts/utils/Multicall2.sol#L2) allows old versions

contracts/utils/Multicall2.sol#L2


 - [ ] ID-176
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L4


 - [ ] ID-177
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4


 - [ ] ID-178
Pragma version[^0.8.0](contracts/mock/MockPriceFeed.sol#L2) allows old versions

contracts/mock/MockPriceFeed.sol#L2


 - [ ] ID-179
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Strings.sol#L4


 - [ ] ID-180
Pragma version[^0.8.0](contracts/token/LockedSYN.sol#L2) allows old versions

contracts/token/LockedSYN.sol#L2


 - [ ] ID-181
Pragma version[^0.8.0](contracts/utils/PriceConvertor.sol#L2) allows old versions

contracts/utils/PriceConvertor.sol#L2


 - [ ] ID-182
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4


 - [ ] ID-183
Pragma version[^0.8.0](contracts/oracle/AAVEOracle.sol#L2) allows old versions

contracts/oracle/AAVEOracle.sol#L2


 - [ ] ID-184
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4


 - [ ] ID-185
Pragma version[^0.8.0](contracts/storage/DebtPoolStorage.sol#L2) allows old versions

contracts/storage/DebtPoolStorage.sol#L2


 - [ ] ID-186
solc-0.8.10 is not recommended for deployment

 - [ ] ID-187
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4


 - [ ] ID-188
Pragma version[^0.8.0](contracts/oracle/PriceOracle.sol#L2) allows old versions

contracts/oracle/PriceOracle.sol#L2


 - [ ] ID-189
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4


 - [ ] ID-190
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L4


 - [ ] ID-191
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4


 - [ ] ID-192
Pragma version[^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Address.sol#L4


 - [ ] ID-193
Pragma version[^0.8.0](contracts/interfaces/IStaking.sol#L2) allows old versions

contracts/interfaces/IStaking.sol#L2


 - [ ] ID-194
Pragma version[^0.8.0](contracts/token/Crowdsale.sol#L2) allows old versions

contracts/token/Crowdsale.sol#L2


 - [ ] ID-195
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4


 - [ ] ID-196
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L4


 - [ ] ID-197
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4


 - [ ] ID-198
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4


 - [ ] ID-199
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4


 - [ ] ID-200
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4


 - [ ] ID-201
Pragma version[^0.8.0](contracts/utils/ATokenWrapper.sol#L2) allows old versions

contracts/utils/ATokenWrapper.sol#L2


 - [ ] ID-202
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IPriceOracle.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IPriceOracle.sol#L2


 - [ ] ID-203
Pragma version[^0.8.0](contracts/utils/AddressStorage.sol#L2) allows old versions

contracts/utils/AddressStorage.sol#L2


 - [ ] ID-204
Pragma version[^0.8.0](contracts/oracle/CompOracle.sol#L2) allows old versions

contracts/oracle/CompOracle.sol#L2


 - [ ] ID-205
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4


 - [ ] ID-206
Pragma version[^0.8.0](contracts/token/SyntheXToken.sol#L2) allows old versions

contracts/token/SyntheXToken.sol#L2


 - [ ] ID-207
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol#L2


 - [ ] ID-208
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IInitializableAToken.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IInitializableAToken.sol#L2


 - [ ] ID-209
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol#L2


 - [ ] ID-210
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Counters.sol#L4


 - [ ] ID-211
Pragma version[^0.8.0](contracts/interfaces/IChainlinkAggregator.sol#L2) allows old versions

contracts/interfaces/IChainlinkAggregator.sol#L2


 - [ ] ID-212
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4


 - [ ] ID-213
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L2


 - [ ] ID-214
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4


 - [ ] ID-215
Pragma version[^0.8.0](contracts/storage/ERC20XStorage.sol#L2) allows old versions

contracts/storage/ERC20XStorage.sol#L2


 - [ ] ID-216
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4


 - [ ] ID-217
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3) allows old versions

node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3


 - [ ] ID-218
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4


 - [ ] ID-219
Pragma version[^0.8.0](contracts/storage/SyntheXStorage.sol#L2) allows old versions

contracts/storage/SyntheXStorage.sol#L2


 - [ ] ID-220
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IScaledBalanceToken.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IScaledBalanceToken.sol#L2


 - [ ] ID-221
Pragma version[^0.8.0](contracts/token/StakingRewards.sol#L2) allows old versions

contracts/token/StakingRewards.sol#L2


 - [ ] ID-222
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4


 - [ ] ID-223
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4


 - [ ] ID-224
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4


 - [ ] ID-225
Pragma version[^0.8.0](contracts/ERC20X.sol#L2) allows old versions

contracts/ERC20X.sol#L2


 - [ ] ID-226
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4


 - [ ] ID-227
Pragma version[^0.8.10](contracts/interfaces/compound/ComptrollerInterface.sol#L2) allows old versions

contracts/interfaces/compound/ComptrollerInterface.sol#L2


 - [ ] ID-228
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4


 - [ ] ID-229
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4


 - [ ] ID-230
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IAaveIncentivesController.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IAaveIncentivesController.sol#L2


 - [ ] ID-231
Pragma version[^0.8.0](contracts/DebtPool.sol#L2) allows old versions

contracts/DebtPool.sol#L2


 - [ ] ID-232
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4


 - [ ] ID-233
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/security/Pausable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/security/Pausable.sol#L4


 - [ ] ID-234
Pragma version[^0.8.0](contracts/token/ERC20Locked.sol#L2) allows old versions

contracts/token/ERC20Locked.sol#L2


 - [ ] ID-235
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4


 - [ ] ID-236
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4


 - [ ] ID-237
Pragma version[^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4


 - [ ] ID-238
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4


 - [ ] ID-239
Pragma version[^0.8.0](contracts/interfaces/ISyntheX.sol#L2) allows old versions

contracts/interfaces/ISyntheX.sol#L2


 - [ ] ID-240
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5) allows old versions

node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5


 - [ ] ID-241
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashBorrowerUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashBorrowerUpgradeable.sol#L4


 - [ ] ID-242
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol#L2


 - [ ] ID-243
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4


 - [ ] ID-244
Pragma version[^0.8.10](contracts/interfaces/compound/IPriceOracle.sol#L2) allows old versions

contracts/interfaces/compound/IPriceOracle.sol#L2


 - [ ] ID-245
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/Ownable.sol#L4


 - [ ] ID-246
Pragma version[^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4


 - [ ] ID-247
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4


 - [ ] ID-248
Pragma version[^0.8.1](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4


 - [ ] ID-249
Pragma version[^0.8.10](contracts/interfaces/compound/CTokenInterface.sol#L2) allows old versions

contracts/interfaces/compound/CTokenInterface.sol#L2


 - [ ] ID-250
Pragma version[^0.8.0](contracts/interfaces/IPriceOracle.sol#L2) allows old versions

contracts/interfaces/IPriceOracle.sol#L2


 - [ ] ID-251
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4


 - [ ] ID-252
Pragma version[^0.8.0](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L2) allows old versions

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L2


 - [ ] ID-253
Pragma version[>=0.4.22<0.9.0](node_modules/hardhat/console.sol#L2) is too complex

node_modules/hardhat/console.sol#L2


 - [ ] ID-254
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4


 - [ ] ID-255
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/interfaces/IERC3156FlashLenderUpgradeable.sol#L4


 - [ ] ID-256
Pragma version[^0.8.0](contracts/oracle/SecondaryOracle.sol#L2) allows old versions

contracts/oracle/SecondaryOracle.sol#L2


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-257
Low level call in [Multicall2.aggregate(Multicall2.Call[])](contracts/utils/Multicall2.sol#L20-L28):
	- [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L24)

contracts/utils/Multicall2.sol#L20-L28


 - [ ] ID-258
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137):
	- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L135)

node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137


 - [ ] ID-259
Low level call in [Multicall2.tryAggregate(bool,Multicall2.Call[])](contracts/utils/Multicall2.sol#L56-L67):
	- [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L59)

contracts/utils/Multicall2.sol#L56-L67


 - [ ] ID-260
Low level call in [AddressUpgradeable.sendValue(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L60-L65):
	- [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L63)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L60-L65


 - [ ] ID-261
Low level call in [Address.sendValue(address,uint256)](node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65):
	- [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts/utils/Address.sol#L63)

node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65


 - [ ] ID-262
Low level call in [AddressUpgradeable.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137):
	- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137


 - [ ] ID-263
Low level call in [AddressUpgradeable.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L155-L162):
	- [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L160)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L155-L162


 - [ ] ID-264
Low level call in [MulticallUpgradeable._functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L37-L43):
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L41)

node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L37-L43


 - [ ] ID-265
Low level call in [ERC1967UpgradeUpgradeable._functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204):
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L202)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204


 - [ ] ID-266
Low level call in [Address.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162):
	- [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L160)

node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162


 - [ ] ID-267
Low level call in [Address.functionDelegateCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187):
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L185)

node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-268
Function [IPool.MAX_NUMBER_RESERVES()](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L717) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L717


 - [ ] ID-269
Parameter [ERC20X.initialize(string,string,address,address)._system](contracts/ERC20X.sol#L27) is not in mixedCase

contracts/ERC20X.sol#L27


 - [ ] ID-270
Variable [MockToken._decimals](contracts/mock/MockToken.sol#L8) is not in mixedCase

contracts/mock/MockToken.sol#L8


 - [ ] ID-271
Parameter [DebtPool.commitSwap(address,uint256,address)._amount](contracts/DebtPool.sol#L342) is not in mixedCase

contracts/DebtPool.sol#L342


 - [ ] ID-272
Variable [ComptrollerInterface._mintGuardianPaused](contracts/interfaces/compound/ComptrollerInterface.sol#L61) is not in mixedCase

contracts/interfaces/compound/ComptrollerInterface.sol#L61


 - [ ] ID-273
Parameter [SyntheX.enterPool(address)._tradingPool](contracts/SyntheX.sol#L93) is not in mixedCase

contracts/SyntheX.sol#L93


 - [ ] ID-274
Parameter [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)._outAsset](contracts/SyntheX.sol#L289) is not in mixedCase

contracts/SyntheX.sol#L289


 - [ ] ID-275
Parameter [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)._fee](contracts/SyntheX.sol#L289) is not in mixedCase

contracts/SyntheX.sol#L289


 - [ ] ID-276
Parameter [Vault.withdraw(address,uint256)._tokenAddress](contracts/utils/FeeVault.sol#L33) is not in mixedCase

contracts/utils/FeeVault.sol#L33


 - [ ] ID-277
Function [IERC20PermitUpgradeable.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L59) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L59


 - [ ] ID-278
Parameter [SyntheX.withdraw(address,uint256)._collateral](contracts/SyntheX.sol#L204) is not in mixedCase

contracts/SyntheX.sol#L204


 - [ ] ID-279
Function [CTokenInterface._acceptAdmin()](contracts/interfaces/compound/CTokenInterface.sol#L31) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L31


 - [ ] ID-280
Parameter [DebtPool.removeSynth(address)._synth](contracts/DebtPool.sol#L171) is not in mixedCase

contracts/DebtPool.sol#L171


 - [ ] ID-281
Parameter [SyntheX.withdraw(address,uint256)._amount](contracts/SyntheX.sol#L204) is not in mixedCase

contracts/SyntheX.sol#L204


 - [ ] ID-282
Parameter [DebtPool.commitLiquidate(address,address,uint256,address)._amount](contracts/DebtPool.sol#L384) is not in mixedCase

contracts/DebtPool.sol#L384


 - [ ] ID-283
Parameter [DebtPool.commitSwap(address,uint256,address)._account](contracts/DebtPool.sol#L342) is not in mixedCase

contracts/DebtPool.sol#L342


 - [ ] ID-284
Parameter [SyntheX.updatePoolRewardIndex(address,address)._tradingPool](contracts/SyntheX.sol#L472) is not in mixedCase

contracts/SyntheX.sol#L472


 - [ ] ID-285
Parameter [DebtPool.getUserDebtUSD(address)._account](contracts/DebtPool.sol#L219) is not in mixedCase

contracts/DebtPool.sol#L219


 - [ ] ID-286
Parameter [StakingRewards.setRewardsDuration(uint256)._rewardsDuration](contracts/token/StakingRewards.sol#L193) is not in mixedCase

contracts/token/StakingRewards.sol#L193


 - [ ] ID-287
Parameter [SyntheX.getAccountLiquidity(address)._account](contracts/SyntheX.sol#L678) is not in mixedCase

contracts/SyntheX.sol#L678


 - [ ] ID-288
Function [AccessControlUpgradeable.__AccessControl_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L54-L55) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L54-L55


 - [ ] ID-289
Variable [MulticallUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L50) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L50


 - [ ] ID-290
Parameter [DebtPool.updateFee(uint256,uint256,uint256,uint256,uint256,uint256)._mintFee](contracts/DebtPool.sol#L132) is not in mixedCase

contracts/DebtPool.sol#L132


 - [ ] ID-291
Parameter [DebtPool.commitBurn(address,uint256)._amount](contracts/DebtPool.sol#L298) is not in mixedCase

contracts/DebtPool.sol#L298


 - [ ] ID-292
Parameter [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)._account](contracts/SyntheX.sol#L289) is not in mixedCase

contracts/SyntheX.sol#L289


 - [ ] ID-293
Function [ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L24-L25


 - [ ] ID-294
Parameter [DebtPool.updateFee(uint256,uint256,uint256,uint256,uint256,uint256)._liquidationFee](contracts/DebtPool.sol#L132) is not in mixedCase

contracts/DebtPool.sol#L132


 - [ ] ID-295
Parameter [SyntheX.enableTradingPool(address,uint256)._volatilityRatio](contracts/SyntheX.sol#L358) is not in mixedCase

contracts/SyntheX.sol#L358


 - [ ] ID-296
Function [CTokenInterface._addReserves(uint256)](contracts/interfaces/compound/CTokenInterface.sol#L59) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L59


 - [ ] ID-297
Parameter [DebtPool.updateFee(uint256,uint256,uint256,uint256,uint256,uint256)._swapFee](contracts/DebtPool.sol#L132) is not in mixedCase

contracts/DebtPool.sol#L132


 - [ ] ID-298
Parameter [SyntheX.updatePoolRewardIndex(address,address)._rewardToken](contracts/SyntheX.sol#L472) is not in mixedCase

contracts/SyntheX.sol#L472


 - [ ] ID-299
Parameter [System.isL1Admin(address)._account](contracts/System.sol#L56) is not in mixedCase

contracts/System.sol#L56


 - [ ] ID-300
Parameter [DebtPool.commitSwap(address,uint256,address)._synthTo](contracts/DebtPool.sol#L342) is not in mixedCase

contracts/DebtPool.sol#L342


 - [ ] ID-301
Function [SyntheX._getAccountLiquidity(address)](contracts/SyntheX.sol#L751-L795) is not in mixedCase

contracts/SyntheX.sol#L751-L795


 - [ ] ID-302
Variable [ContextUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L36) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L36


 - [ ] ID-303
Parameter [SyntheX.grantRewardInternal(address,address,uint256)._reward](contracts/SyntheX.sol#L571) is not in mixedCase

contracts/SyntheX.sol#L571


 - [ ] ID-304
Variable [ComptrollerInterface._borrowGuardianPaused](contracts/interfaces/compound/ComptrollerInterface.sol#L62) is not in mixedCase

contracts/interfaces/compound/ComptrollerInterface.sol#L62


 - [ ] ID-305
Parameter [DebtPool.commitLiquidate(address,address,uint256,address)._account](contracts/DebtPool.sol#L384) is not in mixedCase

contracts/DebtPool.sol#L384


 - [ ] ID-306
Function [ReentrancyGuardUpgradeable.__ReentrancyGuard_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46


 - [ ] ID-307
Variable [AccessControlUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259


 - [ ] ID-308
Parameter [TokenUnlocker.getRequestId(address,uint256)._user](contracts/token/TokenUnlocker.sol#L238) is not in mixedCase

contracts/token/TokenUnlocker.sol#L238


 - [ ] ID-309
Parameter [AddressStorage.getAddress(bytes32)._key](contracts/utils/AddressStorage.sol#L28) is not in mixedCase

contracts/utils/AddressStorage.sol#L28


 - [ ] ID-310
Variable [DebtPoolStorage.__gap](contracts/storage/DebtPoolStorage.sol#L31) is not in mixedCase

contracts/storage/DebtPoolStorage.sol#L31


 - [ ] ID-311
Parameter [SyntheX.setCollateralCap(address,uint256)._collateral](contracts/SyntheX.sol#L418) is not in mixedCase

contracts/SyntheX.sol#L418


 - [ ] ID-312
Parameter [SyntheX.ltvOf(address)._account](contracts/SyntheX.sol#L653) is not in mixedCase

contracts/SyntheX.sol#L653


 - [ ] ID-313
Parameter [SyntheX.setPoolSpeed(address,address,uint256)._rewardToken](contracts/SyntheX.sol#L454) is not in mixedCase

contracts/SyntheX.sol#L454


 - [ ] ID-314
Parameter [System.isGovernanceModule(address)._account](contracts/System.sol#L64) is not in mixedCase

contracts/System.sol#L64


 - [ ] ID-315
Parameter [DebtPool.disableSynth(address)._synth](contracts/DebtPool.sol#L158) is not in mixedCase

contracts/DebtPool.sol#L158


 - [ ] ID-316
Function [IAToken.RESERVE_TREASURY_ADDRESS()](node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L128) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L128


 - [ ] ID-317
Contract [console](node_modules/hardhat/console.sol#L4-L1532) is not in CapWords

node_modules/hardhat/console.sol#L4-L1532


 - [ ] ID-318
Parameter [DebtPool.commitMint(address,uint256)._amount](contracts/DebtPool.sol#L237) is not in mixedCase

contracts/DebtPool.sol#L237


 - [ ] ID-319
Parameter [SyntheX.transferOut(address,address,uint256)._collateral](contracts/SyntheX.sol#L226) is not in mixedCase

contracts/SyntheX.sol#L226


 - [ ] ID-320
Variable [SecondaryOracle.PRIMARY_ORACLE](contracts/oracle/SecondaryOracle.sol#L13) is not in mixedCase

contracts/oracle/SecondaryOracle.sol#L13


 - [ ] ID-321
Variable [TokenUnlocker.TOKEN](contracts/token/TokenUnlocker.sol#L41) is not in mixedCase

contracts/token/TokenUnlocker.sol#L41


 - [ ] ID-322
Parameter [SyntheX.grantRewardInternal(address,address,uint256)._user](contracts/SyntheX.sol#L571) is not in mixedCase

contracts/SyntheX.sol#L571


 - [ ] ID-323
Parameter [ERC20X.initialize(string,string,address,address)._pool](contracts/ERC20X.sol#L27) is not in mixedCase

contracts/ERC20X.sol#L27


 - [ ] ID-324
Function [CTokenInterface._setComptroller(address)](contracts/interfaces/compound/CTokenInterface.sol#L32) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L32


 - [ ] ID-325
Function [CTokenInterface._setPendingAdmin(address)](contracts/interfaces/compound/CTokenInterface.sol#L30) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L30


 - [ ] ID-326
Variable [UUPSUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L107) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L107


 - [ ] ID-327
Function [IPool.MAX_STABLE_RATE_BORROW_SIZE_PERCENT()](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L693) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L693


 - [ ] ID-328
Parameter [SyntheX.claimReward(address,address[],address[])._tradingPools](contracts/SyntheX.sol#L547) is not in mixedCase

contracts/SyntheX.sol#L547


 - [ ] ID-329
Parameter [DebtPool.updateFee(uint256,uint256,uint256,uint256,uint256,uint256)._liquidationPenalty](contracts/DebtPool.sol#L132) is not in mixedCase

contracts/DebtPool.sol#L132


 - [ ] ID-330
Parameter [DebtPool.updateFee(uint256,uint256,uint256,uint256,uint256,uint256)._burnFee](contracts/DebtPool.sol#L132) is not in mixedCase

contracts/DebtPool.sol#L132


 - [ ] ID-331
Variable [EIP712._TYPE_HASH](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L37) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L37


 - [ ] ID-332
Parameter [SyntheX.disableCollateral(address)._collateral](contracts/SyntheX.sol#L407) is not in mixedCase

contracts/SyntheX.sol#L407


 - [ ] ID-333
Variable [PausableUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L116) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L116


 - [ ] ID-334
Function [ERC20FlashMintUpgradeable.__ERC20FlashMint_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L24-L25


 - [ ] ID-335
Parameter [DebtPool.commitBurn(address,uint256)._account](contracts/DebtPool.sol#L298) is not in mixedCase

contracts/DebtPool.sol#L298


 - [ ] ID-336
Parameter [DebtPool.commitLiquidate(address,address,uint256,address)._outAsset](contracts/DebtPool.sol#L384) is not in mixedCase

contracts/DebtPool.sol#L384


 - [ ] ID-337
Parameter [SyntheX.getRewardsAccrued(address,address,address[])._rewardToken](contracts/SyntheX.sol#L599) is not in mixedCase

contracts/SyntheX.sol#L599


 - [ ] ID-338
Parameter [SyntheX.disableTradingPool(address)._tradingPool](contracts/SyntheX.sol#L377) is not in mixedCase

contracts/SyntheX.sol#L377


 - [ ] ID-339
Function [ERC20Upgradeable.__ERC20_init_unchained(string,string)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L59-L62) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L59-L62


 - [ ] ID-340
Variable [TokenUnlocker.LOCKED_TOKEN](contracts/token/TokenUnlocker.sol#L39) is not in mixedCase

contracts/token/TokenUnlocker.sol#L39


 - [ ] ID-341
Parameter [DebtPool.commitMint(address,uint256)._account](contracts/DebtPool.sol#L237) is not in mixedCase

contracts/DebtPool.sol#L237


 - [ ] ID-342
Parameter [DebtPool.updateFeeToken(address)._feeToken](contracts/DebtPool.sol#L146) is not in mixedCase

contracts/DebtPool.sol#L146


 - [ ] ID-343
Constant [ComptrollerInterface.isComptroller](contracts/interfaces/compound/ComptrollerInterface.sol#L101) is not in UPPER_CASE_WITH_UNDERSCORES

contracts/interfaces/compound/ComptrollerInterface.sol#L101


 - [ ] ID-344
Parameter [SyntheX.initialize(address,uint256)._system](contracts/SyntheX.sol#L52) is not in mixedCase

contracts/SyntheX.sol#L52


 - [ ] ID-345
Parameter [SyntheX.grantRewardInternal(address,address,uint256)._amount](contracts/SyntheX.sol#L571) is not in mixedCase

contracts/SyntheX.sol#L571


 - [ ] ID-346
Variable [ERC1967UpgradeUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L211) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L211


 - [ ] ID-347
Parameter [ERC20X.updateFlashFee(uint256)._flashLoanFee](contracts/ERC20X.sol#L112) is not in mixedCase

contracts/ERC20X.sol#L112


 - [ ] ID-348
Parameter [SyntheX.getBorrowCapacity(address)._account](contracts/SyntheX.sol#L666) is not in mixedCase

contracts/SyntheX.sol#L666


 - [ ] ID-349
Function [CTokenInterface._reduceReserves(uint256)](contracts/interfaces/compound/CTokenInterface.sol#L34) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L34


 - [ ] ID-350
Parameter [Crowdsale.updateRate(uint256)._rate](contracts/token/Crowdsale.sol#L119) is not in mixedCase

contracts/token/Crowdsale.sol#L119


 - [ ] ID-351
Function [IAToken.UNDERLYING_ASSET_ADDRESS()](node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L122) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L122


 - [ ] ID-352
Function [ERC20Upgradeable.__ERC20_init(string,string)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L55-L57) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L55-L57


 - [ ] ID-353
Function [IAToken.DOMAIN_SEPARATOR()](node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L135) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IAToken.sol#L135


 - [ ] ID-354
Parameter [TokenUnlocker.unlock(bytes32[])._requestIds](contracts/token/TokenUnlocker.sol#L229) is not in mixedCase

contracts/token/TokenUnlocker.sol#L229


 - [ ] ID-355
Parameter [SyntheX.commitBurn(address,address,uint256)._account](contracts/SyntheX.sol#L276) is not in mixedCase

contracts/SyntheX.sol#L276


 - [ ] ID-356
Function [ReentrancyGuardUpgradeable.__ReentrancyGuard_init()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L40-L42) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L40-L42


 - [ ] ID-357
Parameter [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)._outAmount](contracts/SyntheX.sol#L289) is not in mixedCase

contracts/SyntheX.sol#L289


 - [ ] ID-358
Parameter [TokenUnlocker.startUnlock(uint256)._amount](contracts/token/TokenUnlocker.sol#L171) is not in mixedCase

contracts/token/TokenUnlocker.sol#L171


 - [ ] ID-359
Function [ERC165Upgradeable.__ERC165_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L27-L28) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L27-L28


 - [ ] ID-360
Function [ContextUpgradeable.__Context_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L21-L22


 - [ ] ID-361
Parameter [SyntheX.exitPool(address)._tradingPool](contracts/SyntheX.sol#L112) is not in mixedCase

contracts/SyntheX.sol#L112


 - [ ] ID-362
Parameter [SyntheX.getAdjustedAccountLiquidity(address)._account](contracts/SyntheX.sol#L713) is not in mixedCase

contracts/SyntheX.sol#L713


 - [ ] ID-363
Variable [EIP712._CACHED_THIS](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L33) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L33


 - [ ] ID-364
Function [IPool.FLASHLOAN_PREMIUM_TO_PROTOCOL()](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L711) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L711


 - [ ] ID-365
Function [ERC20FlashMintUpgradeable.__ERC20FlashMint_init()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L21-L22


 - [ ] ID-366
Parameter [SyntheX.healthFactorOf(address)._account](contracts/SyntheX.sol#L638) is not in mixedCase

contracts/SyntheX.sol#L638


 - [ ] ID-367
Function [UUPSUpgradeable.__UUPSUpgradeable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L26-L27) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L26-L27


 - [ ] ID-368
Parameter [SyntheX.transferOut(address,address,uint256)._amount](contracts/SyntheX.sol#L226) is not in mixedCase

contracts/SyntheX.sol#L226


 - [ ] ID-369
Parameter [MockPriceFeed.setPrice(int256,uint8).__decimals](contracts/mock/MockPriceFeed.sol#L14) is not in mixedCase

contracts/mock/MockPriceFeed.sol#L14


 - [ ] ID-370
Variable [ERC20Upgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L400) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L400


 - [ ] ID-371
Parameter [PriceOracle.setFeed(address,address)._feed](contracts/oracle/PriceOracle.sol#L28) is not in mixedCase

contracts/oracle/PriceOracle.sol#L28


 - [ ] ID-372
Variable [ReentrancyGuardUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L80) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L80


 - [ ] ID-373
Variable [ERC20Permit._PERMIT_TYPEHASH_DEPRECATED_SLOT](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L37) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L37


 - [ ] ID-374
Parameter [TokenUnlocker.setLockPeriod(uint256)._lockPeriod](contracts/token/TokenUnlocker.sol#L97) is not in mixedCase

contracts/token/TokenUnlocker.sol#L97


 - [ ] ID-375
Function [IERC20Permit.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L59) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L59


 - [ ] ID-376
Parameter [SyntheX.setPoolSpeed(address,address,uint256)._speed](contracts/SyntheX.sol#L454) is not in mixedCase

contracts/SyntheX.sol#L454


 - [ ] ID-377
Parameter [SyntheX.initialize(address,uint256)._safeCRatio](contracts/SyntheX.sol#L52) is not in mixedCase

contracts/SyntheX.sol#L52


 - [ ] ID-378
Function [MulticallUpgradeable.__Multicall_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L18-L19) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L18-L19


 - [ ] ID-379
Parameter [System.setAddress(bytes32,address)._value](contracts/System.sol#L45) is not in mixedCase

contracts/System.sol#L45


 - [ ] ID-380
Function [AccessControlUpgradeable.__AccessControl_init()](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L51-L52) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L51-L52


 - [ ] ID-381
Variable [EIP712._CACHED_CHAIN_ID](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L32) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L32


 - [ ] ID-382
Parameter [DebtPool.initialize(string,string,address)._system](contracts/DebtPool.sol#L37) is not in mixedCase

contracts/DebtPool.sol#L37


 - [ ] ID-383
Parameter [DebtPool.commitLiquidate(address,address,uint256,address)._liquidator](contracts/DebtPool.sol#L384) is not in mixedCase

contracts/DebtPool.sol#L384


 - [ ] ID-384
Function [ERC20Permit.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L81-L83) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L81-L83


 - [ ] ID-385
Parameter [SyntheX.claimReward(address,address,address[])._rewardToken](contracts/SyntheX.sol#L535) is not in mixedCase

contracts/SyntheX.sol#L535


 - [ ] ID-386
Parameter [SyntheX.distributeAccountReward(address,address,address)._debtPool](contracts/SyntheX.sol#L495) is not in mixedCase

contracts/SyntheX.sol#L495


 - [ ] ID-387
Parameter [DebtPool.updateFee(uint256,uint256,uint256,uint256,uint256,uint256)._issuerAlloc](contracts/DebtPool.sol#L132) is not in mixedCase

contracts/DebtPool.sol#L132


 - [ ] ID-388
Parameter [MockPriceFeed.setPrice(int256,uint8)._price](contracts/mock/MockPriceFeed.sol#L14) is not in mixedCase

contracts/mock/MockPriceFeed.sol#L14


 - [ ] ID-389
Parameter [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)._liquidator](contracts/SyntheX.sol#L289) is not in mixedCase

contracts/SyntheX.sol#L289


 - [ ] ID-390
Parameter [DebtPool.enableSynth(address)._synth](contracts/DebtPool.sol#L108) is not in mixedCase

contracts/DebtPool.sol#L108


 - [ ] ID-391
Parameter [SyntheX.setSafeCRatio(uint256)._safeCRatio](contracts/SyntheX.sol#L432) is not in mixedCase

contracts/SyntheX.sol#L432


 - [ ] ID-392
Variable [ERC165Upgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L41) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L41


 - [ ] ID-393
Parameter [TokenUnlocker.unlocked(bytes32)._requestId](contracts/token/TokenUnlocker.sol#L134) is not in mixedCase

contracts/token/TokenUnlocker.sol#L134


 - [ ] ID-394
Parameter [SyntheX.commitMint(address,address,uint256)._account](contracts/SyntheX.sol#L248) is not in mixedCase

contracts/SyntheX.sol#L248


 - [ ] ID-395
Variable [UUPSUpgradeable.__self](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L29) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L29


 - [ ] ID-396
Function [ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L21-L22


 - [ ] ID-397
Function [IPool.ADDRESSES_PROVIDER()](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L630) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L630


 - [ ] ID-398
Parameter [SyntheX.setCollateralCap(address,uint256)._maxDeposit](contracts/SyntheX.sol#L418) is not in mixedCase

contracts/SyntheX.sol#L418


 - [ ] ID-399
Variable [ERC20FlashMintUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L121) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L121


 - [ ] ID-400
Variable [SecondaryOracle.SECONDARY_ORACLE](contracts/oracle/SecondaryOracle.sol#L15) is not in mixedCase

contracts/oracle/SecondaryOracle.sol#L15


 - [ ] ID-401
Parameter [SyntheX.enterCollateral(address)._collateral](contracts/SyntheX.sol#L132) is not in mixedCase

contracts/SyntheX.sol#L132


 - [ ] ID-402
Function [UUPSUpgradeable.__UUPSUpgradeable_init()](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L23-L24) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L23-L24


 - [ ] ID-403
Parameter [PriceOracle.getAssetPrices(address[])._assets](contracts/oracle/PriceOracle.sol#L78) is not in mixedCase

contracts/oracle/PriceOracle.sol#L78


 - [ ] ID-404
Parameter [SyntheX.updateRewardToken(address,bool)._rewardToken](contracts/SyntheX.sol#L439) is not in mixedCase

contracts/SyntheX.sol#L439


 - [ ] ID-405
Parameter [Crowdsale.unlockTokens(bytes32)._requestId](contracts/token/Crowdsale.sol#L130) is not in mixedCase

contracts/token/Crowdsale.sol#L130


 - [ ] ID-406
Parameter [SyntheX.getRewardsAccrued(address,address,address[])._tradingPoolsList](contracts/SyntheX.sol#L599) is not in mixedCase

contracts/SyntheX.sol#L599


 - [ ] ID-407
Parameter [PriceOracle.getAssetPrice(address)._asset](contracts/oracle/PriceOracle.sol#L60) is not in mixedCase

contracts/oracle/PriceOracle.sol#L60


 - [ ] ID-408
Function [IPool.BRIDGE_PROTOCOL_FEE()](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L705) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L705


 - [ ] ID-409
Parameter [System.isL0Admin(address)._account](contracts/System.sol#L52) is not in mixedCase

contracts/System.sol#L52


 - [ ] ID-410
Parameter [SyntheX.commitLiquidate(address,address,address,uint256,uint256,uint256)._penalty](contracts/SyntheX.sol#L289) is not in mixedCase

contracts/SyntheX.sol#L289


 - [ ] ID-411
Variable [EIP712._HASHED_NAME](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L35) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L35


 - [ ] ID-412
Variable [AddressStorage.__gap](contracts/utils/AddressStorage.sol#L43) is not in mixedCase

contracts/utils/AddressStorage.sol#L43


 - [ ] ID-413
Variable [SyntheXStorage.__gap](contracts/storage/SyntheXStorage.sol#L80) is not in mixedCase

contracts/storage/SyntheXStorage.sol#L80


 - [ ] ID-414
Parameter [System.setAddress(bytes32,address)._key](contracts/System.sol#L45) is not in mixedCase

contracts/System.sol#L45


 - [ ] ID-415
Parameter [SyntheX.distributeAccountReward(address,address,address)._account](contracts/SyntheX.sol#L495) is not in mixedCase

contracts/SyntheX.sol#L495


 - [ ] ID-416
Parameter [TokenUnlocker.getRequestId(address,uint256)._unlockIndex](contracts/token/TokenUnlocker.sol#L238) is not in mixedCase

contracts/token/TokenUnlocker.sol#L238


 - [ ] ID-417
Parameter [SyntheX.setPoolSpeed(address,address,uint256)._tradingPool](contracts/SyntheX.sol#L454) is not in mixedCase

contracts/SyntheX.sol#L454


 - [ ] ID-418
Constant [SyntheXStorage.rewardInitialIndex](contracts/storage/SyntheXStorage.sol#L24) is not in UPPER_CASE_WITH_UNDERSCORES

contracts/storage/SyntheXStorage.sol#L24


 - [ ] ID-419
Parameter [SyntheX.claimReward(address,address[],address[])._rewardToken](contracts/SyntheX.sol#L547) is not in mixedCase

contracts/SyntheX.sol#L547


 - [ ] ID-420
Function [MulticallUpgradeable.__Multicall_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L15-L16) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol#L15-L16


 - [ ] ID-421
Parameter [PriceOracle.getFeed(address)._token](contracts/oracle/PriceOracle.sol#L51) is not in mixedCase

contracts/oracle/PriceOracle.sol#L51


 - [ ] ID-422
Function [PausableUpgradeable.__Pausable_init()](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L34-L36) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L34-L36


 - [ ] ID-423
Parameter [PriceOracle.setFeed(address,address)._token](contracts/oracle/PriceOracle.sol#L28) is not in mixedCase

contracts/oracle/PriceOracle.sol#L28


 - [ ] ID-424
Parameter [SyntheX.enableTradingPool(address,uint256)._tradingPool](contracts/SyntheX.sol#L358) is not in mixedCase

contracts/SyntheX.sol#L358


 - [ ] ID-425
Function [ContextUpgradeable.__Context_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L18-L19) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L18-L19


 - [ ] ID-426
Parameter [SyntheX.deposit(address,uint256)._collateral](contracts/SyntheX.sol#L164) is not in mixedCase

contracts/SyntheX.sol#L164


 - [ ] ID-427
Constant [IPriceOracle.isPriceOracle](contracts/interfaces/compound/IPriceOracle.sol#L8) is not in UPPER_CASE_WITH_UNDERSCORES

contracts/interfaces/compound/IPriceOracle.sol#L8


 - [ ] ID-428
Parameter [SyntheX.enableCollateral(address,uint256)._volatilityRatio](contracts/SyntheX.sol#L390) is not in mixedCase

contracts/SyntheX.sol#L390


 - [ ] ID-429
Parameter [SyntheX.deposit(address,uint256)._amount](contracts/SyntheX.sol#L164) is not in mixedCase

contracts/SyntheX.sol#L164


 - [ ] ID-430
Function [ERC165Upgradeable.__ERC165_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L24-L25


 - [ ] ID-431
Function [CTokenInterface._setReserveFactor(uint256)](contracts/interfaces/compound/CTokenInterface.sol#L33) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L33


 - [ ] ID-432
Variable [EIP712._CACHED_DOMAIN_SEPARATOR](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L31) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L31


 - [ ] ID-433
Function [CTokenInterface._setInterestRateModel(address)](contracts/interfaces/compound/CTokenInterface.sol#L35) is not in mixedCase

contracts/interfaces/compound/CTokenInterface.sol#L35


 - [ ] ID-434
Parameter [TokenUnlocker.withdraw(uint256)._amount](contracts/token/TokenUnlocker.sol#L108) is not in mixedCase

contracts/token/TokenUnlocker.sol#L108


 - [ ] ID-435
Function [IPool.FLASHLOAN_PREMIUM_TOTAL()](node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L699) is not in mixedCase

node_modules/@aave/core-v3/contracts/interfaces/IPool.sol#L699


 - [ ] ID-436
Parameter [SyntheX.getRewardsAccrued(address,address,address[])._account](contracts/SyntheX.sol#L599) is not in mixedCase

contracts/SyntheX.sol#L599


 - [ ] ID-437
Parameter [System.isL2Admin(address)._account](contracts/System.sol#L60) is not in mixedCase

contracts/System.sol#L60


 - [ ] ID-438
Variable [EIP712._HASHED_VERSION](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L36) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L36


 - [ ] ID-439
Parameter [SyntheX.enableCollateral(address,uint256)._collateral](contracts/SyntheX.sol#L390) is not in mixedCase

contracts/SyntheX.sol#L390


 - [ ] ID-440
Parameter [SyntheX.exitCollateral(address)._collateral](contracts/SyntheX.sol#L147) is not in mixedCase

contracts/SyntheX.sol#L147


 - [ ] ID-441
Parameter [SyntheX._getAccountLiquidity(address)._account](contracts/SyntheX.sol#L751) is not in mixedCase

contracts/SyntheX.sol#L751


 - [ ] ID-442
Function [PausableUpgradeable.__Pausable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L38-L40) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L38-L40


 - [ ] ID-443
Parameter [SyntheX.distributeAccountReward(address,address,address)._rewardToken](contracts/SyntheX.sol#L495) is not in mixedCase

contracts/SyntheX.sol#L495


## redundant-statements
Impact: Informational
Confidence: High
 - [ ] ID-444
Redundant expression "[amount](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L61)" in[ERC20FlashMintUpgradeable](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L20-L122)

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L61


 - [ ] ID-445
Redundant expression "[_amount](contracts/SyntheX.sol#L278)" in[SyntheX](contracts/SyntheX.sol#L31-L797)

contracts/SyntheX.sol#L278


 - [ ] ID-446
Redundant expression "[_synth](contracts/SyntheX.sol#L249)" in[SyntheX](contracts/SyntheX.sol#L31-L797)

contracts/SyntheX.sol#L249


 - [ ] ID-447
Redundant expression "[amount](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L55)" in[ERC20FlashMint](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L19-L109)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L55


 - [ ] ID-448
Redundant expression "[_amount](contracts/SyntheX.sol#L250)" in[SyntheX](contracts/SyntheX.sol#L31-L797)

contracts/SyntheX.sol#L250


 - [ ] ID-449
Redundant expression "[_synth](contracts/SyntheX.sol#L277)" in[SyntheX](contracts/SyntheX.sol#L31-L797)

contracts/SyntheX.sol#L277


 - [ ] ID-450
Redundant expression "[token](contracts/ERC20X.sol#L125)" in[ERC20X](contracts/ERC20X.sol#L20-L129)

contracts/ERC20X.sol#L125


 - [ ] ID-451
Redundant expression "[token](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L54)" in[ERC20FlashMint](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L19-L109)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L54


 - [ ] ID-452
Redundant expression "[token](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L60)" in[ERC20FlashMintUpgradeable](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L20-L122)

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol#L60


## reentrancy-unlimited-gas
Impact: Informational
Confidence: Medium
 - [ ] ID-453
Reentrancy in [WETH9.withdraw(uint256)](contracts/utils/WETH9.sol#L42-L47):
	External calls:
	- [msg.sender.transfer(wad)](contracts/utils/WETH9.sol#L45)
	Event emitted after the call(s):
	- [Withdrawal(msg.sender,wad)](contracts/utils/WETH9.sol#L46)

contracts/utils/WETH9.sol#L42-L47


 - [ ] ID-454
Reentrancy in [Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L82-L116):
	External calls:
	- [wallet.transfer(msg.value)](contracts/token/Crowdsale.sol#L114)
	Event emitted after the call(s):
	- [TokenPurchase(msg.sender,msg.value,tokens)](contracts/token/Crowdsale.sol#L115)

contracts/token/Crowdsale.sol#L82-L116


 - [ ] ID-455
Reentrancy in [SyntheX.withdraw(address,uint256)](contracts/SyntheX.sol#L204-L224):
	External calls:
	- [_amount = transferOut(_collateral,msg.sender,_amount)](contracts/SyntheX.sol#L212)
		- [address(recipient).transfer(_amount)](contracts/SyntheX.sol#L231)
	External calls sending eth:
	- [_amount = transferOut(_collateral,msg.sender,_amount)](contracts/SyntheX.sol#L212)
		- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)
		- [address(recipient).transfer(_amount)](contracts/SyntheX.sol#L231)
	State variables written after the call(s):
	- [accountCollateralBalance[msg.sender][_collateral] = depositBalance.sub(_amount)](contracts/SyntheX.sol#L215)
	- [supply.totalDeposits = supply.totalDeposits.sub(_amount)](contracts/SyntheX.sol#L217)
	Event emitted after the call(s):
	- [Withdraw(msg.sender,_collateral,_amount)](contracts/SyntheX.sol#L223)

contracts/SyntheX.sol#L204-L224


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-456
Variable [SyntheX.enableTradingPool(address,uint256)._tradingPool](contracts/SyntheX.sol#L358) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L358


 - [ ] ID-457
Variable [ISyntheX.enterPool(address)._tradingPool](contracts/interfaces/ISyntheX.sol#L10) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L10


 - [ ] ID-458
Variable [SyntheX.exitCollateral(address)._collateral](contracts/SyntheX.sol#L147) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L147


 - [ ] ID-459
Variable [TokenUnlocker.startUnlock(uint256)._unlockRequest](contracts/token/TokenUnlocker.sol#L182) is too similar to [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L53)

contracts/token/TokenUnlocker.sol#L182


 - [ ] ID-460
Variable [ISyntheX.deposit(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L14) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L14


 - [ ] ID-461
Variable [SyntheX.setPoolSpeed(address,address,uint256)._tradingPool](contracts/SyntheX.sol#L454) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L454


 - [ ] ID-462
Variable [SyntheX.setCollateralCap(address,uint256)._collateral](contracts/SyntheX.sol#L418) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L418


 - [ ] ID-463
Variable [SyntheX.disableCollateral(address)._collateral](contracts/SyntheX.sol#L407) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L407


 - [ ] ID-464
Variable [ISyntheX.withdraw(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L15) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L15


 - [ ] ID-465
Variable [ISyntheX.setPoolSpeed(address,address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L19) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L19


 - [ ] ID-466
Variable [SyntheX.enableCollateral(address,uint256)._collateral](contracts/SyntheX.sol#L390) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L390


 - [ ] ID-467
Variable [SyntheX.enterCollateral(address)._collateral](contracts/SyntheX.sol#L132) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L132


 - [ ] ID-468
Variable [System.L1_ADMIN_ROLE](contracts/System.sol#L24) is too similar to [System.L2_ADMIN_ROLE](contracts/System.sol#L25)

contracts/System.sol#L24


 - [ ] ID-469
Variable [ISyntheX.exitPool(address)._tradingPool](contracts/interfaces/ISyntheX.sol#L11) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L11


 - [ ] ID-470
Variable [ISyntheX.exitCollateral(address)._collateral](contracts/interfaces/ISyntheX.sol#L13) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L13


 - [ ] ID-471
Variable [SyntheX.exitPool(address)._tradingPool](contracts/SyntheX.sol#L112) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L112


 - [ ] ID-472
Variable [ISyntheX.enterCollateral(address)._collateral](contracts/interfaces/ISyntheX.sol#L12) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L12


 - [ ] ID-473
Variable [ISyntheX.setCollateralCap(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L30) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L30


 - [ ] ID-474
Variable [SyntheX.updatePoolRewardIndex(address,address)._tradingPool](contracts/SyntheX.sol#L472) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L472


 - [ ] ID-475
Variable [ISyntheX.enableCollateral(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L27) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L27


 - [ ] ID-476
Variable [SecondaryOracle.PRIMARY_ORACLE](contracts/oracle/SecondaryOracle.sol#L13) is too similar to [SecondaryOracle.constructor(address,address)._primaryOracle](contracts/oracle/SecondaryOracle.sol#L17)

contracts/oracle/SecondaryOracle.sol#L13


 - [ ] ID-477
Variable [SyntheX.enterPool(address)._tradingPool](contracts/SyntheX.sol#L93) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L93


 - [ ] ID-478
Variable [SecondaryOracle.SECONDARY_ORACLE](contracts/oracle/SecondaryOracle.sol#L15) is too similar to [SecondaryOracle.constructor(address,address)._secondaryOracle](contracts/oracle/SecondaryOracle.sol#L17)

contracts/oracle/SecondaryOracle.sol#L15


 - [ ] ID-479
Variable [ISyntheX.disableCollateral(address)._collateral](contracts/interfaces/ISyntheX.sol#L28) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/interfaces/ISyntheX.sol#L28


 - [ ] ID-480
Variable [SyntheX.disableTradingPool(address)._tradingPool](contracts/SyntheX.sol#L377) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L377


 - [ ] ID-481
Variable [SyntheXToken.L1_ADMIN_ROLE](contracts/token/SyntheXToken.sol#L17) is too similar to [SyntheXToken.L2_ADMIN_ROLE](contracts/token/SyntheXToken.sol#L18)

contracts/token/SyntheXToken.sol#L17


 - [ ] ID-482
Variable [ISyntheX.disableTradingPool(address)._tradingPool](contracts/interfaces/ISyntheX.sol#L26) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L26


 - [ ] ID-483
Variable [SyntheX.deposit(address,uint256)._collateral](contracts/SyntheX.sol#L164) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L164


 - [ ] ID-484
Variable [ISyntheX.enableTradingPool(address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L25) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L25


 - [ ] ID-485
Variable [SyntheX.transferOut(address,address,uint256)._collateral](contracts/SyntheX.sol#L226) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L226


 - [ ] ID-486
Variable [SyntheX.withdraw(address,uint256)._collateral](contracts/SyntheX.sol#L204) is too similar to [SyntheXStorage.collaterals](contracts/storage/SyntheXStorage.sol#L54)

contracts/SyntheX.sol#L204


 - [ ] ID-487
Variable [SyntheX._enterPool(address,address)._tradingPool](contracts/SyntheX.sol#L97) is too similar to [SyntheXStorage.tradingPools](contracts/storage/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L97


## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-488
[Crowdsale.sealedToken](contracts/token/Crowdsale.sol#L52) is never used in [Crowdsale](contracts/token/Crowdsale.sol#L13-L160)

contracts/token/Crowdsale.sol#L52


## constable-states
Impact: Optimization
Confidence: High
 - [ ] ID-489
[WETH9.decimals](contracts/utils/WETH9.sol#L25) should be constant 

contracts/utils/WETH9.sol#L25


 - [ ] ID-490
[WETH9.symbol](contracts/utils/WETH9.sol#L24) should be constant 

contracts/utils/WETH9.sol#L24


 - [ ] ID-491
[WETH9.name](contracts/utils/WETH9.sol#L23) should be constant 

contracts/utils/WETH9.sol#L23


 - [ ] ID-492
[ComptrollerInterface.seizeGuardianPaused](contracts/interfaces/compound/ComptrollerInterface.sol#L64) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L64


 - [ ] ID-493
[ComptrollerInterface._borrowGuardianPaused](contracts/interfaces/compound/ComptrollerInterface.sol#L62) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L62


 - [ ] ID-494
[ComptrollerInterface.maxAssets](contracts/interfaces/compound/ComptrollerInterface.sol#L26) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L26


 - [ ] ID-495
[Crowdsale.sealedToken](contracts/token/Crowdsale.sol#L52) should be constant 

contracts/token/Crowdsale.sol#L52


 - [ ] ID-496
[ComptrollerInterface.compRate](contracts/interfaces/compound/ComptrollerInterface.sol#L80) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L80


 - [ ] ID-497
[ComptrollerInterface.closeFactorMantissa](contracts/interfaces/compound/ComptrollerInterface.sol#L16) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L16


 - [ ] ID-498
[ComptrollerInterface._mintGuardianPaused](contracts/interfaces/compound/ComptrollerInterface.sol#L61) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L61


 - [ ] ID-499
[ComptrollerInterface.transferGuardianPaused](contracts/interfaces/compound/ComptrollerInterface.sol#L63) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L63


 - [ ] ID-500
[ComptrollerInterface.pauseGuardian](contracts/interfaces/compound/ComptrollerInterface.sol#L60) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L60


 - [ ] ID-501
[ComptrollerInterface.liquidationIncentiveMantissa](contracts/interfaces/compound/ComptrollerInterface.sol#L21) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L21


 - [ ] ID-502
[ComptrollerInterface.oracle](contracts/interfaces/compound/ComptrollerInterface.sol#L11) should be constant 

contracts/interfaces/compound/ComptrollerInterface.sol#L11


## immutable-states
Impact: Optimization
Confidence: High
 - [ ] ID-503
[SyntheXToken.system](contracts/token/SyntheXToken.sol#L15) should be immutable 

contracts/token/SyntheXToken.sol#L15


 - [ ] ID-504
[Crowdsale.startTime](contracts/token/Crowdsale.sol#L17) should be immutable 

contracts/token/Crowdsale.sol#L17


 - [ ] ID-505
[LockedSYN.system](contracts/token/LockedSYN.sol#L16) should be immutable 

contracts/token/LockedSYN.sol#L16


 - [ ] ID-506
[AAVEOracle.underlyingDecimals](contracts/oracle/AAVEOracle.sol#L13) should be immutable 

contracts/oracle/AAVEOracle.sol#L13


 - [ ] ID-507
[TokenUnlocker.system](contracts/token/TokenUnlocker.sol#L57) should be immutable 

contracts/token/TokenUnlocker.sol#L57


 - [ ] ID-508
[StakingRewards.system](contracts/token/StakingRewards.sol#L22) should be immutable 

contracts/token/StakingRewards.sol#L22


 - [ ] ID-509
[Vault.system](contracts/utils/FeeVault.sol#L17) should be immutable 

contracts/utils/FeeVault.sol#L17


 - [ ] ID-510
[Crowdsale.wallet](contracts/token/Crowdsale.sol#L22) should be immutable 

contracts/token/Crowdsale.sol#L22


 - [ ] ID-511
[StakingRewards.stakingToken](contracts/token/StakingRewards.sol#L26) should be immutable 

contracts/token/StakingRewards.sol#L26


 - [ ] ID-512
[PriceOracle.system](contracts/oracle/PriceOracle.sol#L17) should be immutable 

contracts/oracle/PriceOracle.sol#L17


 - [ ] ID-513
[CompoundOracle.cToken](contracts/oracle/CompOracle.sol#L11) should be immutable 

contracts/oracle/CompOracle.sol#L11


 - [ ] ID-514
[TokenUnlocker.percUnlockAtRelease](contracts/token/TokenUnlocker.sol#L49) should be immutable 

contracts/token/TokenUnlocker.sol#L49


 - [ ] ID-515
[TokenUnlocker.unlockPeriod](contracts/token/TokenUnlocker.sol#L47) should be immutable 

contracts/token/TokenUnlocker.sol#L47


 - [ ] ID-516
[SecondaryOracle.PRIMARY_ORACLE](contracts/oracle/SecondaryOracle.sol#L13) should be immutable 

contracts/oracle/SecondaryOracle.sol#L13


 - [ ] ID-517
[MockToken._decimals](contracts/mock/MockToken.sol#L8) should be immutable 

contracts/mock/MockToken.sol#L8


 - [ ] ID-518
[Crowdsale.unlockIntervals](contracts/token/Crowdsale.sol#L37) should be immutable 

contracts/token/Crowdsale.sol#L37


 - [ ] ID-519
[SecondaryOracle.SECONDARY_ORACLE](contracts/oracle/SecondaryOracle.sol#L15) should be immutable 

contracts/oracle/SecondaryOracle.sol#L15


 - [ ] ID-520
[AAVEOracle.lendingPoolAddressesProvider](contracts/oracle/AAVEOracle.sol#L16) should be immutable 

contracts/oracle/AAVEOracle.sol#L16


 - [ ] ID-521
[AAVEOracle.underlying](contracts/oracle/AAVEOracle.sol#L11) should be immutable 

contracts/oracle/AAVEOracle.sol#L11


 - [ ] ID-522
[Crowdsale.lockInDuration](contracts/token/Crowdsale.sol#L34) should be immutable 

contracts/token/Crowdsale.sol#L34


 - [ ] ID-523
[ATokenWrapper.underlying](contracts/utils/ATokenWrapper.sol#L17) should be immutable 

contracts/utils/ATokenWrapper.sol#L17


 - [ ] ID-524
[CompoundOracle.comptroller](contracts/oracle/CompOracle.sol#L10) should be immutable 

contracts/oracle/CompOracle.sol#L10


 - [ ] ID-525
[TokenUnlocker.TOKEN](contracts/token/TokenUnlocker.sol#L41) should be immutable 

contracts/token/TokenUnlocker.sol#L41


 - [ ] ID-526
[CompoundOracle.underlyingDecimals](contracts/oracle/CompOracle.sol#L13) should be immutable 

contracts/oracle/CompOracle.sol#L13


 - [ ] ID-527
[StakingRewards.rewardsToken](contracts/token/StakingRewards.sol#L24) should be immutable 

contracts/token/StakingRewards.sol#L24


 - [ ] ID-528
[TokenUnlocker.LOCKED_TOKEN](contracts/token/TokenUnlocker.sol#L39) should be immutable 

contracts/token/TokenUnlocker.sol#L39


 - [ ] ID-529
[Crowdsale.token](contracts/token/Crowdsale.sol#L51) should be immutable 

contracts/token/Crowdsale.sol#L51


