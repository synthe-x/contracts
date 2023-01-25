Summary
 - [arbitrary-send-erc20](#arbitrary-send-erc20) (1 results) (High)
 - [controlled-delegatecall](#controlled-delegatecall) (1 results) (High)
 - [reentrancy-eth](#reentrancy-eth) (1 results) (High)
 - [unchecked-transfer](#unchecked-transfer) (4 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (27 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (3 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (8 results) (Medium)
 - [tautology](#tautology) (1 results) (Medium)
 - [uninitialized-local](#uninitialized-local) (3 results) (Medium)
 - [unused-return](#unused-return) (3 results) (Medium)
 - [shadowing-local](#shadowing-local) (8 results) (Low)
 - [events-maths](#events-maths) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (5 results) (Low)
 - [calls-loop](#calls-loop) (18 results) (Low)
 - [variable-scope](#variable-scope) (3 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (4 results) (Low)
 - [reentrancy-events](#reentrancy-events) (6 results) (Low)
 - [timestamp](#timestamp) (14 results) (Low)
 - [assembly](#assembly) (12 results) (Informational)
 - [pragma](#pragma) (1 results) (Informational)
 - [costly-loop](#costly-loop) (4 results) (Informational)
 - [solc-version](#solc-version) (73 results) (Informational)
 - [low-level-calls](#low-level-calls) (10 results) (Informational)
 - [naming-convention](#naming-convention) (145 results) (Informational)
 - [redundant-statements](#redundant-statements) (3 results) (Informational)
 - [reentrancy-unlimited-gas](#reentrancy-unlimited-gas) (2 results) (Informational)
 - [similar-names](#similar-names) (32 results) (Informational)
 - [unused-state](#unused-state) (1 results) (Informational)
 - [constable-states](#constable-states) (1 results) (Optimization)
 - [immutable-states](#immutable-states) (19 results) (Optimization)
## arbitrary-send-erc20
Impact: High
Confidence: High
 - [ ] ID-0
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L131-L151) uses arbitrary from in transferFrom: [token.transferFrom(wallet,msg.sender,calculatedUnlockAmt)](contracts/token/Crowdsale.sol#L145)

contracts/token/Crowdsale.sol#L131-L151


## controlled-delegatecall
Impact: High
Confidence: Medium
 - [ ] ID-1
[ERC1967UpgradeUpgradeable._functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204) uses delegatecall to a input-controlled function id
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L202)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204


## reentrancy-eth
Impact: High
Confidence: Medium
 - [ ] ID-2
Reentrancy in [SyntheX.withdraw(address,uint256)](contracts/SyntheX.sol#L204-L230):
	External calls:
	- [ERC20Upgradeable(_collateral).safeTransfer(msg.sender,_amount)](contracts/SyntheX.sol#L219)
	External calls sending eth:
	- [address(msg.sender).transfer(_amount)](contracts/SyntheX.sol#L216)
	State variables written after the call(s):
	- [supply.totalDeposits = supply.totalDeposits.sub(_amount)](contracts/SyntheX.sol#L226)
	[SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L58) can be used in cross function reentrancies:
	- [SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L58)
	- [SyntheX.setCollateralCap(address,uint256)](contracts/SyntheX.sol#L498-L506)

contracts/SyntheX.sol#L204-L230


## unchecked-transfer
Impact: High
Confidence: Medium
 - [ ] ID-3
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L649-L668) ignores return value by [_rewardToken.transfer(_user,_amount)](contracts/SyntheX.sol#L661)

contracts/SyntheX.sol#L649-L668


 - [ ] ID-4
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) ignores return value by [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-5
[TokenUnlocker.withdraw(uint256)](contracts/token/TokenUnlocker.sol#L108-L111) ignores return value by [TOKEN.transfer(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L110)

contracts/token/TokenUnlocker.sol#L108-L111


 - [ ] ID-6
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L131-L151) ignores return value by [token.transferFrom(wallet,msg.sender,calculatedUnlockAmt)](contracts/token/Crowdsale.sol#L145)

contracts/token/Crowdsale.sol#L131-L151


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-7
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L124)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-8
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L121)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-9
[DebtPool.burn(address,address,address,uint256,uint256)](contracts/DebtPool.sol#L303-L319) performs a multiplication on the result of a division:
	- [burnablePerc = getUserDebtUSD(_borrower).min(amountUSD).mul(1e18).div(amountUSD)](contracts/DebtPool.sol#L305)
	- [amountUSD = amountUSD.mul(burnablePerc).div(1e18)](contracts/DebtPool.sol#L311)

contracts/DebtPool.sol#L303-L319


 - [ ] ID-10
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L126)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-11
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse = (3 * denominator) ^ 2](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L117)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-12
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L105)
	- [result = prod0 * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L132)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-13
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L124)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-14
[DebtPool.burn(address,address,address,uint256,uint256)](contracts/DebtPool.sol#L303-L319) performs a multiplication on the result of a division:
	- [amountUSD = amountUSD.mul(burnablePerc).div(1e18)](contracts/DebtPool.sol#L311)
	- [burnAmount = totalSupply * amountUSD / _totalDebt](contracts/DebtPool.sol#L315)

contracts/DebtPool.sol#L303-L319


 - [ ] ID-15
[DebtPool.mintSynth(address,address,uint256,uint256)](contracts/DebtPool.sol#L260-L290) performs a multiplication on the result of a division:
	- [feeAmount = amountUSD.mul(_fee).mul(uint256(1e18).mul(BASIS_POINTS).sub(issuerAlloc)).div(BASIS_POINTS).div(1e18).div(BASIS_POINTS).div(1e18).mul(10 ** feeTokenPrice.decimals).div(feeTokenPrice.price)](contracts/DebtPool.sol#L275-L281)

contracts/DebtPool.sol#L260-L290


 - [ ] ID-16
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L131-L151) performs a multiplication on the result of a division:
	- [totalRewardsForIntervalPassed = uint256(timeDuration[msg.sender] - block.timestamp).div(lockInDuration)](contracts/token/Crowdsale.sol#L140)
	- [calculatedUnlockAmt = uint256(tokenMapping[_requestId]).mul(totalRewardsForIntervalPassed)](contracts/token/Crowdsale.sol#L141)

contracts/token/Crowdsale.sol#L131-L151


 - [ ] ID-17
[TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162) performs a multiplication on the result of a division:
	- [percentUnlock = timeSinceUnlock.mul(1e18).div(unlockPeriod)](contracts/token/TokenUnlocker.sol#L144)
	- [percentUnlock = percentUnlock.mul(BASIS_POINTS)](contracts/token/TokenUnlocker.sol#L151)

contracts/token/TokenUnlocker.sol#L134-L162


 - [ ] ID-18
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L122)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-19
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L123)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-20
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L121)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-21
[TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162) performs a multiplication on the result of a division:
	- [percentUnlock = timeSinceUnlock.mul(1e18).div(unlockPeriod)](contracts/token/TokenUnlocker.sol#L144)
	- [amountToUnlock = unlockRequest.amount.mul(percentUnlock.add(percUnlockAtRelease).sub(percentUnlock.mul(percUnlockAtRelease).div(BASIS_POINTS).div(1e18))).div(1e18).div(BASIS_POINTS).sub(unlockRequest.claimed)](contracts/token/TokenUnlocker.sol#L155-L159)

contracts/token/TokenUnlocker.sol#L134-L162


 - [ ] ID-22
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse = (3 * denominator) ^ 2](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L117)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-23
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L123)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-24
[StakingRewards.notifyReward(uint256)](contracts/token/StakingRewards.sol#L174-L188) performs a multiplication on the result of a division:
	- [rewardRate = reward.div(rewardsDuration)](contracts/token/StakingRewards.sol#L177)
	- [leftover = remaining.mul(rewardRate)](contracts/token/StakingRewards.sol#L181)

contracts/token/StakingRewards.sol#L174-L188


 - [ ] ID-25
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L122)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-26
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L125)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-27
[SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L339-L411) performs a multiplication on the result of a division:
	- [collateralToSieze = _inAmount.mul(prices[0].price).mul(10 ** prices[1].decimals).mul(incentive).div(1e18).div(prices[1].price).div(10 ** prices[0].decimals)](contracts/SyntheX.sol#L372-L378)
	- [collateralToSieze = collateralToSieze.mul(synthBurned).div(synthToBurn)](contracts/SyntheX.sol#L404)

contracts/SyntheX.sol#L339-L411


 - [ ] ID-28
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [prod0 = prod0 / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L105)
	- [result = prod0 * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L132)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-29
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L126)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


 - [ ] ID-30
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division:
	- [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102)
	- [inverse *= 2 - denominator * inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L125)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-31
[SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L339-L411) performs a multiplication on the result of a division:
	- [amountUSD = collateralToSieze.mul(prices[1].price).mul(1e18).div(incentive).div(10 ** prices[1].decimals)](contracts/SyntheX.sol#L385-L389)
	- [synthToBurn = amountUSD.mul(10 ** prices[0].decimals).div(prices[0].price)](contracts/SyntheX.sol#L392-L394)

contracts/SyntheX.sol#L339-L411


 - [ ] ID-32
[SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L339-L411) performs a multiplication on the result of a division:
	- [collateralToSieze = _inAmount.mul(prices[0].price).mul(10 ** prices[1].decimals).mul(incentive).div(1e18).div(prices[1].price).div(10 ** prices[0].decimals)](contracts/SyntheX.sol#L372-L378)
	- [amountUSD = collateralToSieze.mul(prices[1].price).mul(1e18).div(incentive).div(10 ** prices[1].decimals)](contracts/SyntheX.sol#L385-L389)

contracts/SyntheX.sol#L339-L411


 - [ ] ID-33
[DebtPool.burn(address,address,address,uint256,uint256)](contracts/DebtPool.sol#L303-L319) performs a multiplication on the result of a division:
	- [burnablePerc = getUserDebtUSD(_borrower).min(amountUSD).mul(1e18).div(amountUSD)](contracts/DebtPool.sol#L305)
	- [_amount = _amount.mul(burnablePerc).div(1e18)](contracts/DebtPool.sol#L310)

contracts/DebtPool.sol#L303-L319


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-34
[ERC20Votes._writeCheckpoint(ERC20Votes.Checkpoint[],function(uint256,uint256) returns(uint256),uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L239-L256) uses a dangerous strict equality:
	- [pos > 0 && oldCkpt.fromBlock == block.number](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L251)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L239-L256


 - [ ] ID-35
[SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L552-L566) uses a dangerous strict equality:
	- [deltaTimestamp == 0](contracts/SyntheX.sol#L556)

contracts/SyntheX.sol#L552-L566


 - [ ] ID-36
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) uses a dangerous strict equality:
	- [amountToUnlock == 0](contracts/token/TokenUnlocker.sol#L206)

contracts/token/TokenUnlocker.sol#L201-L223


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-37
Reentrancy in [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195):
	External calls:
	- [SEALED_TOKEN.burnFrom(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L177)
	State variables written after the call(s):
	- [reservedForUnlock = reservedForUnlock.add(_amount)](contracts/token/TokenUnlocker.sol#L192)
	[TokenUnlocker.reservedForUnlock](contracts/token/TokenUnlocker.sol#L43) can be used in cross function reentrancies:
	- [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223)
	- [TokenUnlocker.remainingQuota()](contracts/token/TokenUnlocker.sol#L79-L81)
	- [TokenUnlocker.reservedForUnlock](contracts/token/TokenUnlocker.sol#L43)
	- [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195)

contracts/token/TokenUnlocker.sol#L171-L195


 - [ ] ID-38
Reentrancy in [Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L131-L151):
	External calls:
	- [token.transferFrom(wallet,msg.sender,calculatedUnlockAmt)](contracts/token/Crowdsale.sol#L145)
	State variables written after the call(s):
	- [timeDuration[msg.sender] = block.timestamp](contracts/token/Crowdsale.sol#L146)
	[Crowdsale.timeDuration](contracts/token/Crowdsale.sol#L57) can be used in cross function reentrancies:
	- [Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L83-L117)
	- [Crowdsale.timeDuration](contracts/token/Crowdsale.sol#L57)
	- [tokenBal[_requestId] = tokenBal[_requestId] - calculatedUnlockAmt](contracts/token/Crowdsale.sol#L147)
	[Crowdsale.tokenBal](contracts/token/Crowdsale.sol#L56) can be used in cross function reentrancies:
	- [Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L83-L117)
	- [Crowdsale.tokenBal](contracts/token/Crowdsale.sol#L56)

contracts/token/Crowdsale.sol#L131-L151


 - [ ] ID-39
Reentrancy in [SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L339-L411):
	External calls:
	- [synthBurned = DebtPool(_debtPool).burn(_inAsset,msg.sender,_account,synthToBurn,amountUSD)](contracts/SyntheX.sol#L396-L402)
	State variables written after the call(s):
	- [accountCollateralBalance[_account][_outAsset] = collateralBalance.sub(collateralToSieze)](contracts/SyntheX.sol#L407)
	[SyntheXStorage.accountCollateralBalance](contracts/SyntheXStorage.sol#L37) can be used in cross function reentrancies:
	- [SyntheXStorage.accountCollateralBalance](contracts/SyntheXStorage.sol#L37)
	- [SyntheX.getAdjustedUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L771-L793)
	- [SyntheX.getUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L746-L764)
	- [accountCollateralBalance[msg.sender][_outAsset] = accountCollateralBalance[msg.sender][_outAsset].add(collateralToSieze)](contracts/SyntheX.sol#L410)
	[SyntheXStorage.accountCollateralBalance](contracts/SyntheXStorage.sol#L37) can be used in cross function reentrancies:
	- [SyntheXStorage.accountCollateralBalance](contracts/SyntheXStorage.sol#L37)
	- [SyntheX.getAdjustedUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L771-L793)
	- [SyntheX.getUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L746-L764)

contracts/SyntheX.sol#L339-L411


 - [ ] ID-40
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


 - [ ] ID-41
Reentrancy in [SyntheX.deposit(address,uint256)](contracts/SyntheX.sol#L164-L195):
	External calls:
	- [ERC20Upgradeable(_collateral).safeTransferFrom(msg.sender,address(this),_amount)](contracts/SyntheX.sol#L184)
	State variables written after the call(s):
	- [supply.totalDeposits = supply.totalDeposits.add(_amount)](contracts/SyntheX.sol#L190)
	[SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L58) can be used in cross function reentrancies:
	- [SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L58)
	- [SyntheX.setCollateralCap(address,uint256)](contracts/SyntheX.sol#L498-L506)

contracts/SyntheX.sol#L164-L195


 - [ ] ID-42
Reentrancy in [StakingRewards.exit()](contracts/token/StakingRewards.sol#L163-L166):
	External calls:
	- [withdraw(balanceOf[msg.sender])](contracts/token/StakingRewards.sol#L164)
		- [ERC20Sealed(stakingToken).mint(msg.sender,amount)](contracts/token/StakingRewards.sol#L142)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [ERC20Sealed(rewardsToken).mint(msg.sender,reward)](contracts/token/StakingRewards.sol#L155)
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


 - [ ] ID-43
Reentrancy in [SyntheX.claimReward(address,address[],address[])](contracts/SyntheX.sol#L625-L640):
	External calls:
	- [grantRewardInternal(_rewardToken,holders[j],rewardAccrued[_rewardToken][holders[j]])](contracts/SyntheX.sol#L637)
		- [SyntheXToken(_reward).mint(_user,_amount)](contracts/SyntheX.sol#L654)
		- [_rewardToken.transfer(_user,_amount)](contracts/SyntheX.sol#L661)
	State variables written after the call(s):
	- [rewardAccrued[_rewardToken][holders[j]] = 0](contracts/SyntheX.sol#L638)
	[SyntheXStorage.rewardAccrued](contracts/SyntheXStorage.sol#L79) can be used in cross function reentrancies:
	- [SyntheX.claimReward(address,address[],address[])](contracts/SyntheX.sol#L625-L640)
	- [SyntheX.distributeAccountReward(address,address,address)](contracts/SyntheX.sol#L574-L604)
	- [SyntheX.getRewardsAccrued(address,address,address[])](contracts/SyntheX.sol#L674-L684)
	- [SyntheXStorage.rewardAccrued](contracts/SyntheXStorage.sol#L79)

contracts/SyntheX.sol#L625-L640


 - [ ] ID-44
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


## tautology
Impact: Medium
Confidence: High
 - [ ] ID-45
[PriceOracle.setFeed(address,address)](contracts/PriceOracle.sol#L29-L46) contains a tautology or contradiction:
	- [require(bool,string)(feeds[_token].decimals() >= 0,PriceOracle: Decimals is <= 0)](contracts/PriceOracle.sol#L42)

contracts/PriceOracle.sol#L29-L46


## uninitialized-local
Impact: Medium
Confidence: Medium
 - [ ] ID-46
[ERC20Votes._moveVotingPower(address,address,uint256).oldWeight_scope_0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233) is a local variable never initialized

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233


 - [ ] ID-47
[ERC20Votes._moveVotingPower(address,address,uint256).newWeight_scope_1](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233) is a local variable never initialized

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233


 - [ ] ID-48
[ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98) is a local variable never initialized

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-49
[SyntheX.exchange(address,address,address,uint256)](contracts/SyntheX.sol#L306-L329) ignores return value by [DebtPool(_debtPool).burnSynth(_synthFrom,msg.sender,_amount)](contracts/SyntheX.sol#L323)

contracts/SyntheX.sol#L306-L329


 - [ ] ID-50
[SyntheX.exchange(address,address,address,uint256)](contracts/SyntheX.sol#L306-L329) ignores return value by [DebtPool(_debtPool).mintSynth(_synthTo,msg.sender,amountDst,amountUSD)](contracts/SyntheX.sol#L325)

contracts/SyntheX.sol#L306-L329


 - [ ] ID-51
[ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105) ignores return value by [IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98-L102)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105


## shadowing-local
Impact: Low
Confidence: High
 - [ ] ID-52
[ERC20Permit.constructor(string).name](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L44) shadows:
	- [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function)
	- [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L44


 - [ ] ID-53
[DebtPool.burn(address,address,address,uint256,uint256).totalSupply](contracts/DebtPool.sol#L314) shadows:
	- [ERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L99-L101) (function)
	- [IERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L27) (function)

contracts/DebtPool.sol#L314


 - [ ] ID-54
[DebtPool.initialize(string,string,address).symbol](contracts/DebtPool.sol#L52) shadows:
	- [ERC20Upgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L75-L77) (function)
	- [IERC20MetadataUpgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L22) (function)

contracts/DebtPool.sol#L52


 - [ ] ID-55
[ERC20X.constructor(string,string,address,address).name](contracts/ERC20X.sol#L31) shadows:
	- [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function)
	- [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

contracts/ERC20X.sol#L31


 - [ ] ID-56
[MockToken.constructor(string,string).symbol](contracts/mock/MockToken.sol#L7) shadows:
	- [ERC20.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L70-L72) (function)
	- [IERC20Metadata.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L22) (function)

contracts/mock/MockToken.sol#L7


 - [ ] ID-57
[ERC20X.constructor(string,string,address,address).symbol](contracts/ERC20X.sol#L31) shadows:
	- [ERC20.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L70-L72) (function)
	- [IERC20Metadata.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L22) (function)

contracts/ERC20X.sol#L31


 - [ ] ID-58
[MockToken.constructor(string,string).name](contracts/mock/MockToken.sol#L7) shadows:
	- [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function)
	- [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

contracts/mock/MockToken.sol#L7


 - [ ] ID-59
[DebtPool.initialize(string,string,address).name](contracts/DebtPool.sol#L52) shadows:
	- [ERC20Upgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L67-L69) (function)
	- [IERC20MetadataUpgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L17) (function)

contracts/DebtPool.sol#L52


## events-maths
Impact: Low
Confidence: Medium
 - [ ] ID-60
[Crowdsale.updateRate(uint256)](contracts/token/Crowdsale.sol#L120-L122) should emit an event for: 
	- [rate = _rate](contracts/token/Crowdsale.sol#L121) 

contracts/token/Crowdsale.sol#L120-L122


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-61
[Crowdsale.constructor(address,address,uint256,uint256,uint256,uint256,uint256)._adminWallet](contracts/token/Crowdsale.sol#L71) lacks a zero-check on :
		- [wallet = _adminWallet](contracts/token/Crowdsale.sol#L73)

contracts/token/Crowdsale.sol#L71


 - [ ] ID-62
[DebtPool.updateFeeToken(address)._feeToken](contracts/DebtPool.sol#L98) lacks a zero-check on :
		- [feeToken = _feeToken](contracts/DebtPool.sol#L99)

contracts/DebtPool.sol#L98


 - [ ] ID-63
[ERC20X.constructor(string,string,address,address)._pool](contracts/ERC20X.sol#L31) lacks a zero-check on :
		- [pool = _pool](contracts/ERC20X.sol#L32)

contracts/ERC20X.sol#L31


 - [ ] ID-64
[StakingRewards.constructor(address,address,address,uint256)._rewardsToken](contracts/token/StakingRewards.sol#L52) lacks a zero-check on :
		- [rewardsToken = _rewardsToken](contracts/token/StakingRewards.sol#L57)

contracts/token/StakingRewards.sol#L52


 - [ ] ID-65
[StakingRewards.constructor(address,address,address,uint256)._stakingToken](contracts/token/StakingRewards.sol#L53) lacks a zero-check on :
		- [stakingToken = _stakingToken](contracts/token/StakingRewards.sol#L58)

contracts/token/StakingRewards.sol#L53


## calls-loop
Impact: Low
Confidence: Medium
 - [ ] ID-66
[SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L552-L566) has external calls inside a loop: [borrowAmount = DebtPool(_tradingPool).totalSupply()](contracts/SyntheX.sol#L558)

contracts/SyntheX.sol#L552-L566


 - [ ] ID-67
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has external calls inside a loop: [TOKEN.balanceOf(address(this)) < amountToUnlock](contracts/token/TokenUnlocker.sol#L211)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-68
[DebtPool.getTotalDebtUSD()](contracts/DebtPool.sol#L148-L163) has external calls inside a loop: [totalDebt = totalDebt.add(ERC20X(synth).totalSupply().mul(price.price).div(10 ** price.decimals))](contracts/DebtPool.sol#L160)

contracts/DebtPool.sol#L148-L163


 - [ ] ID-69
[SyntheX.getAdjustedUserTotalDebtUSD(address)](contracts/SyntheX.sol#L818-L833) has external calls inside a loop: [adjustedTotalDebt = adjustedTotalDebt.add(DebtPool(_accountPools[i]).getUserDebtUSD(_account).mul(1e18).div(tradingPools[_accountPools[i]].volatilityRatio))](contracts/SyntheX.sol#L826-L830)

contracts/SyntheX.sol#L818-L833


 - [ ] ID-70
[DebtPool.getTotalDebtUSD()](contracts/DebtPool.sol#L148-L163) has external calls inside a loop: [price = _oracle.getAssetPrice(synth)](contracts/DebtPool.sol#L158)

contracts/DebtPool.sol#L148-L163


 - [ ] ID-71
[SyntheX.distributeAccountReward(address,address,address)](contracts/SyntheX.sol#L574-L604) has external calls inside a loop: [accountDebtTokens = DebtPool(_debtPool).balanceOf(_account)](contracts/SyntheX.sol#L595)

contracts/SyntheX.sol#L574-L604


 - [ ] ID-72
[PriceOracle.getAssetPrice(address)](contracts/PriceOracle.sol#L61-L72) has external calls inside a loop: [decimals = _feed.decimals()](contracts/PriceOracle.sol#L64)

contracts/PriceOracle.sol#L61-L72


 - [ ] ID-73
[SyntheX.getAdjustedUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L771-L793) has external calls inside a loop: [price = _oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L781)

contracts/SyntheX.sol#L771-L793


 - [ ] ID-74
[Multicall2.tryAggregate(bool,Multicall2.Call[])](contracts/utils/Multicall2.sol#L56-L67) has external calls inside a loop: [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L59)

contracts/utils/Multicall2.sol#L56-L67


 - [ ] ID-75
[SyntheX.getUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L746-L764) has external calls inside a loop: [price = _oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L756)

contracts/SyntheX.sol#L746-L764


 - [ ] ID-76
[PriceOracle.getAssetPrice(address)](contracts/PriceOracle.sol#L61-L72) has external calls inside a loop: [price = _feed.latestAnswer()](contracts/PriceOracle.sol#L63)

contracts/PriceOracle.sol#L61-L72


 - [ ] ID-77
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L649-L668) has external calls inside a loop: [SyntheXToken(_reward).mint(_user,_amount)](contracts/SyntheX.sol#L654)

contracts/SyntheX.sol#L649-L668


 - [ ] ID-78
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L649-L668) has external calls inside a loop: [rewardRemaining = _rewardToken.balanceOf(address(this))](contracts/SyntheX.sol#L658)

contracts/SyntheX.sol#L649-L668


 - [ ] ID-79
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has external calls inside a loop: [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-80
[SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L649-L668) has external calls inside a loop: [_rewardToken.transfer(_user,_amount)](contracts/SyntheX.sol#L661)

contracts/SyntheX.sol#L649-L668


 - [ ] ID-81
[Multicall2.aggregate(Multicall2.Call[])](contracts/utils/Multicall2.sol#L20-L28) has external calls inside a loop: [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L24)

contracts/utils/Multicall2.sol#L20-L28


 - [ ] ID-82
[SyntheX.getUserTotalDebtUSD(address)](contracts/SyntheX.sol#L800-L811) has external calls inside a loop: [totalDebt = totalDebt.add(DebtPool(_accountPools[i]).getUserDebtUSD(_account))](contracts/SyntheX.sol#L808)

contracts/SyntheX.sol#L800-L811


 - [ ] ID-83
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has external calls inside a loop: [amountToUnlock = TOKEN.balanceOf(address(this))](contracts/token/TokenUnlocker.sol#L212)

contracts/token/TokenUnlocker.sol#L201-L223


## variable-scope
Impact: Low
Confidence: High
 - [ ] ID-84
Variable '[ERC20Votes._moveVotingPower(address,address,uint256).oldWeight](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228)' in [ERC20Votes._moveVotingPower(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L221-L237) potentially used before declaration: [(oldWeight,newWeight) = _writeCheckpoint(_checkpoints[dst],_add,amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228


 - [ ] ID-85
Variable '[ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98)' in [ERC1967UpgradeUpgradeable._upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105) potentially used before declaration: [require(bool,string)(slot == _IMPLEMENTATION_SLOT,ERC1967Upgrade: unsupported proxiableUUID)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L99)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98


 - [ ] ID-86
Variable '[ERC20Votes._moveVotingPower(address,address,uint256).newWeight](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228)' in [ERC20Votes._moveVotingPower(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L221-L237) potentially used before declaration: [(oldWeight,newWeight) = _writeCheckpoint(_checkpoints[dst],_add,amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-87
Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
	External calls:
	- [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == _RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
	State variables written after the call(s):
	- [_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L100)
		- [_allowances[owner][spender] = amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L324)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108


 - [ ] ID-88
Reentrancy in [SyntheX.deposit(address,uint256)](contracts/SyntheX.sol#L164-L195):
	External calls:
	- [ERC20Upgradeable(_collateral).safeTransferFrom(msg.sender,address(this),_amount)](contracts/SyntheX.sol#L184)
	State variables written after the call(s):
	- [accountCollateralBalance[msg.sender][_collateral] = accountCollateralBalance[msg.sender][_collateral].add(_amount)](contracts/SyntheX.sol#L187)

contracts/SyntheX.sol#L164-L195


 - [ ] ID-89
Reentrancy in [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223):
	External calls:
	- [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)
	State variables written after the call(s):
	- [reservedForUnlock = reservedForUnlock.sub(amountToUnlock)](contracts/token/TokenUnlocker.sol#L220)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-90
Reentrancy in [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195):
	External calls:
	- [SEALED_TOKEN.burnFrom(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L177)
	State variables written after the call(s):
	- [unlockRequestCount[msg.sender] ++](contracts/token/TokenUnlocker.sol#L189)
	- [_unlockRequest.amount = _amount](contracts/token/TokenUnlocker.sol#L184)
	- [_unlockRequest.requestTime = block.timestamp](contracts/token/TokenUnlocker.sol#L185)
	- [_unlockRequest.claimed = 0](contracts/token/TokenUnlocker.sol#L186)

contracts/token/TokenUnlocker.sol#L171-L195


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-91
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


 - [ ] ID-92
Reentrancy in [TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195):
	External calls:
	- [SEALED_TOKEN.burnFrom(msg.sender,_amount)](contracts/token/TokenUnlocker.sol#L177)
	Event emitted after the call(s):
	- [UnlockRequested(msg.sender,requestId,_amount)](contracts/token/TokenUnlocker.sol#L194)

contracts/token/TokenUnlocker.sol#L171-L195


 - [ ] ID-93
Reentrancy in [SyntheX.issue(address,address,uint256)](contracts/SyntheX.sol#L238-L270):
	External calls:
	- [_amount = DebtPool(_debtPool).mint(_synth,msg.sender,msg.sender,_amount,amountUSD)](contracts/SyntheX.sol#L263)
	Event emitted after the call(s):
	- [Issue(msg.sender,_debtPool,_synth,_amount)](contracts/SyntheX.sol#L269)

contracts/SyntheX.sol#L238-L270


 - [ ] ID-94
Reentrancy in [SyntheX.burn(address,address,uint256)](contracts/SyntheX.sol#L278-L297):
	External calls:
	- [_amount = DebtPool(_debtPool).burn(_synth,msg.sender,msg.sender,_amount,amountUSD)](contracts/SyntheX.sol#L294)
	Event emitted after the call(s):
	- [Burn(msg.sender,_debtPool,_synth,_amount)](contracts/SyntheX.sol#L296)

contracts/SyntheX.sol#L278-L297


 - [ ] ID-95
Reentrancy in [StakingRewards.exit()](contracts/token/StakingRewards.sol#L163-L166):
	External calls:
	- [withdraw(balanceOf[msg.sender])](contracts/token/StakingRewards.sol#L164)
		- [ERC20Sealed(stakingToken).mint(msg.sender,amount)](contracts/token/StakingRewards.sol#L142)
	- [getReward()](contracts/token/StakingRewards.sol#L165)
		- [ERC20Sealed(rewardsToken).mint(msg.sender,reward)](contracts/token/StakingRewards.sol#L155)
	Event emitted after the call(s):
	- [RewardPaid(msg.sender,reward)](contracts/token/StakingRewards.sol#L156)
		- [getReward()](contracts/token/StakingRewards.sol#L165)

contracts/token/StakingRewards.sol#L163-L166


 - [ ] ID-96
Reentrancy in [TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223):
	External calls:
	- [TOKEN.transfer(msg.sender,amountToUnlock)](contracts/token/TokenUnlocker.sol#L214)
	Event emitted after the call(s):
	- [Unlocked(msg.sender,_requestId,amountToUnlock)](contracts/token/TokenUnlocker.sol#L222)

contracts/token/TokenUnlocker.sol#L201-L223


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-97
[ERC20Permit.permit(address,address,uint256,uint256,uint8,bytes32,bytes32)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L49-L68) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp <= deadline,ERC20Permit: expired deadline)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L58)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L49-L68


 - [ ] ID-98
[ERC20Votes.delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L146-L163) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp <= expiry,ERC20Votes: signature expired)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L154)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L146-L163


 - [ ] ID-99
[TokenUnlocker.startUnlock(uint256)](contracts/token/TokenUnlocker.sol#L171-L195) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(remainingQuota() >= _amount,Not enough SYN to unlock)](contracts/token/TokenUnlocker.sol#L173)
	- [require(bool,string)(_unlockRequest.amount == 0,Unlock request already exists)](contracts/token/TokenUnlocker.sol#L183)

contracts/token/TokenUnlocker.sol#L171-L195


 - [ ] ID-100
[Crowdsale.unlockTokens(bytes32)](contracts/token/Crowdsale.sol#L131-L151) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)((timeDuration[msg.sender] - block.timestamp) > (lockInDuration / unlockIntervals),cannot unlock before lockInPeriod)](contracts/token/Crowdsale.sol#L133)
	- [require(bool)(calculatedUnlockAmt > 0 && tokenBal[_requestId] != 0)](contracts/token/Crowdsale.sol#L143)

contracts/token/Crowdsale.sol#L131-L151


 - [ ] ID-101
[Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L83-L117) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp < startTime && block.timestamp > endTime](contracts/token/Crowdsale.sol#L88)

contracts/token/Crowdsale.sol#L83-L117


 - [ ] ID-102
[SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L552-L566) uses timestamp for comparisons
	Dangerous comparisons:
	- [deltaTimestamp == 0](contracts/SyntheX.sol#L556)

contracts/SyntheX.sol#L552-L566


 - [ ] ID-103
[StakingRewards.getReward()](contracts/token/StakingRewards.sol#L150-L158) uses timestamp for comparisons
	Dangerous comparisons:
	- [reward > 0](contracts/token/StakingRewards.sol#L153)

contracts/token/StakingRewards.sol#L150-L158


 - [ ] ID-104
[StakingRewards.setRewardsDuration(uint256)](contracts/token/StakingRewards.sol#L193-L201) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(block.timestamp > periodFinish,Previous rewards period must be complete before changing the duration for the new period)](contracts/token/StakingRewards.sol#L195-L198)

contracts/token/StakingRewards.sol#L193-L201


 - [ ] ID-105
[TokenUnlocker.withdraw(uint256)](contracts/token/TokenUnlocker.sol#L108-L111) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(_amount <= remainingQuota(),Not enough SYN to withdraw)](contracts/token/TokenUnlocker.sol#L109)

contracts/token/TokenUnlocker.sol#L108-L111


 - [ ] ID-106
[Crowdsale.closeSale()](contracts/token/Crowdsale.sol#L124-L127) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool)(block.timestamp < endTime)](contracts/token/Crowdsale.sol#L125)

contracts/token/Crowdsale.sol#L124-L127


 - [ ] ID-107
[StakingRewards.lastTimeRewardApplicable()](contracts/token/StakingRewards.sol#L88-L90) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp < periodFinish](contracts/token/StakingRewards.sol#L89)

contracts/token/StakingRewards.sol#L88-L90


 - [ ] ID-108
[TokenUnlocker.unlocked(bytes32)](contracts/token/TokenUnlocker.sol#L134-L162) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(unlockRequest.amount > 0,Unlock request does not exist)](contracts/token/TokenUnlocker.sol#L137)
	- [require(bool,string)(block.timestamp >= unlockRequest.requestTime.add(lockPeriod),Unlock period has not passed)](contracts/token/TokenUnlocker.sol#L139)
	- [percentUnlock > 1e18](contracts/token/TokenUnlocker.sol#L147)

contracts/token/TokenUnlocker.sol#L134-L162


 - [ ] ID-109
[StakingRewards.notifyReward(uint256)](contracts/token/StakingRewards.sol#L174-L188) uses timestamp for comparisons
	Dangerous comparisons:
	- [block.timestamp >= periodFinish](contracts/token/StakingRewards.sol#L176)

contracts/token/StakingRewards.sol#L174-L188


 - [ ] ID-110
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) uses timestamp for comparisons
	Dangerous comparisons:
	- [amountToUnlock == 0](contracts/token/TokenUnlocker.sol#L206)
	- [TOKEN.balanceOf(address(this)) < amountToUnlock](contracts/token/TokenUnlocker.sol#L211)

contracts/token/TokenUnlocker.sol#L201-L223


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-111
[AddressUpgradeable._revert(bytes,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L206-L218) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L211-L214)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L206-L218


 - [ ] ID-112
[StorageSlotUpgradeable.getAddressSlot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L52-L57) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L54-L56)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L52-L57


 - [ ] ID-113
[ECDSA.tryRecover(bytes32,bytes)](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L55-L72) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L63-L67)

node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L55-L72


 - [ ] ID-114
[StorageSlotUpgradeable.getBytes32Slot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L72-L77) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L74-L76)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L72-L77


 - [ ] ID-115
[Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L66-L70)
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L86-L93)
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L100-L109)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135


 - [ ] ID-116
[StorageSlotUpgradeable.getBooleanSlot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L62-L67) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L64-L66)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L62-L67


 - [ ] ID-117
[Strings.toString(uint256)](node_modules/@openzeppelin/contracts/utils/Strings.sol#L18-L38) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Strings.sol#L24-L26)
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Strings.sol#L30-L32)

node_modules/@openzeppelin/contracts/utils/Strings.sol#L18-L38


 - [ ] ID-118
[ERC20Votes._unsafeAccess(ERC20Votes.Checkpoint[],uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L266-L271) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L267-L270)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L266-L271


 - [ ] ID-119
[StringsUpgradeable.toString(uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L18-L38) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L24-L26)
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L30-L32)

node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L18-L38


 - [ ] ID-120
[Address._revert(bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L231-L243) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Address.sol#L236-L239)

node_modules/@openzeppelin/contracts/utils/Address.sol#L231-L243


 - [ ] ID-121
[StorageSlotUpgradeable.getUint256Slot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L82-L87) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L84-L86)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L82-L87


 - [ ] ID-122
[MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) uses assembly
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L66-L70)
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L86-L93)
	- [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L100-L109)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135


## pragma
Impact: Informational
Confidence: High
 - [ ] ID-123
Different versions of Solidity are used:
	- Version used: ['^0.8.0', '^0.8.1', '^0.8.2']
	- [ABIEncoderV2](contracts/utils/Multicall2.sol#L3)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4)
	- [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4)
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
	- [^0.8.0](contracts/PriceOracle.sol#L2)
	- [^0.8.0](contracts/SyntheX.sol#L2)
	- [^0.8.0](contracts/SyntheXStorage.sol#L2)
	- [^0.8.0](contracts/System.sol#L2)
	- [^0.8.0](contracts/interfaces/IChainlinkAggregator.sol#L2)
	- [^0.8.0](contracts/interfaces/IDebtPool.sol#L2)
	- [^0.8.0](contracts/interfaces/IPriceOracle.sol#L2)
	- [^0.8.0](contracts/interfaces/IStaking.sol#L2)
	- [^0.8.0](contracts/interfaces/ISyntheX.sol#L2)
	- [^0.8.0](contracts/mock/MockPriceFeed.sol#L2)
	- [^0.8.0](contracts/mock/MockToken.sol#L2)
	- [^0.8.0](contracts/token/Crowdsale.sol#L2)
	- [^0.8.0](contracts/token/ERC20Sealed.sol#L2)
	- [^0.8.0](contracts/token/SealedSYN.sol#L2)
	- [^0.8.0](contracts/token/StakingRewards.sol#L2)
	- [^0.8.0](contracts/token/SyntheXToken.sol#L2)
	- [^0.8.0](contracts/token/TokenUnlocker.sol#L2)
	- [^0.8.0](contracts/utils/AddressStorage.sol#L2)
	- [^0.8.0](contracts/utils/FeeVault.sol#L2)
	- [^0.8.0](contracts/utils/Multicall2.sol#L2)
	- [^0.8.1](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4)
	- [^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4)
	- [^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4)
	- [^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4)

contracts/utils/Multicall2.sol#L3


## costly-loop
Impact: Informational
Confidence: Medium
 - [ ] ID-124
[DebtPool.removeSynth(address)](contracts/DebtPool.sol#L122-L132) has costly operations inside a loop:
	- [_synthsList.pop()](contracts/DebtPool.sol#L127)

contracts/DebtPool.sol#L122-L132


 - [ ] ID-125
[TokenUnlocker._unlockInternal(bytes32)](contracts/token/TokenUnlocker.sol#L201-L223) has costly operations inside a loop:
	- [reservedForUnlock = reservedForUnlock.sub(amountToUnlock)](contracts/token/TokenUnlocker.sol#L220)

contracts/token/TokenUnlocker.sol#L201-L223


 - [ ] ID-126
[ReentrancyGuardUpgradeable._nonReentrantAfter()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73) has costly operations inside a loop:
	- [_status = _NOT_ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L72)

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73


 - [ ] ID-127
[ReentrancyGuardUpgradeable._nonReentrantBefore()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67) has costly operations inside a loop:
	- [_status = _ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L66)

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67


## solc-version
Impact: Informational
Confidence: High
 - [ ] ID-128
Pragma version[^0.8.0](contracts/mock/MockToken.sol#L2) allows old versions

contracts/mock/MockToken.sol#L2


 - [ ] ID-129
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4


 - [ ] ID-130
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4


 - [ ] ID-131
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4


 - [ ] ID-132
Pragma version[^0.8.0](contracts/System.sol#L2) allows old versions

contracts/System.sol#L2


 - [ ] ID-133
Pragma version[^0.8.0](contracts/utils/FeeVault.sol#L2) allows old versions

contracts/utils/FeeVault.sol#L2


 - [ ] ID-134
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4


 - [ ] ID-135
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4


 - [ ] ID-136
Pragma version[^0.8.0](contracts/SyntheX.sol#L2) allows old versions

contracts/SyntheX.sol#L2


 - [ ] ID-137
Pragma version[^0.8.0](contracts/token/TokenUnlocker.sol#L2) allows old versions

contracts/token/TokenUnlocker.sol#L2


 - [ ] ID-138
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4


 - [ ] ID-139
Pragma version[^0.8.0](contracts/interfaces/IDebtPool.sol#L2) allows old versions

contracts/interfaces/IDebtPool.sol#L2


 - [ ] ID-140
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4


 - [ ] ID-141
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Context.sol#L4


 - [ ] ID-142
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4


 - [ ] ID-143
Pragma version[^0.8.0](contracts/utils/Multicall2.sol#L2) allows old versions

contracts/utils/Multicall2.sol#L2


 - [ ] ID-144
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol#L4


 - [ ] ID-145
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4


 - [ ] ID-146
Pragma version[^0.8.0](contracts/mock/MockPriceFeed.sol#L2) allows old versions

contracts/mock/MockPriceFeed.sol#L2


 - [ ] ID-147
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Strings.sol#L4


 - [ ] ID-148
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4


 - [ ] ID-149
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4


 - [ ] ID-150
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4


 - [ ] ID-151
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4


 - [ ] ID-152
Pragma version[^0.8.0](contracts/SyntheXStorage.sol#L2) allows old versions

contracts/SyntheXStorage.sol#L2


 - [ ] ID-153
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4


 - [ ] ID-154
Pragma version[^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Address.sol#L4


 - [ ] ID-155
Pragma version[^0.8.0](contracts/interfaces/IStaking.sol#L2) allows old versions

contracts/interfaces/IStaking.sol#L2


 - [ ] ID-156
Pragma version[^0.8.0](contracts/token/Crowdsale.sol#L2) allows old versions

contracts/token/Crowdsale.sol#L2


 - [ ] ID-157
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4


 - [ ] ID-158
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4


 - [ ] ID-159
solc-0.8.17 is not recommended for deployment

 - [ ] ID-160
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4


 - [ ] ID-161
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4


 - [ ] ID-162
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4


 - [ ] ID-163
Pragma version[^0.8.0](contracts/utils/AddressStorage.sol#L2) allows old versions

contracts/utils/AddressStorage.sol#L2


 - [ ] ID-164
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4


 - [ ] ID-165
Pragma version[^0.8.0](contracts/token/SyntheXToken.sol#L2) allows old versions

contracts/token/SyntheXToken.sol#L2


 - [ ] ID-166
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Counters.sol#L4


 - [ ] ID-167
Pragma version[^0.8.0](contracts/interfaces/IChainlinkAggregator.sol#L2) allows old versions

contracts/interfaces/IChainlinkAggregator.sol#L2


 - [ ] ID-168
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4


 - [ ] ID-169
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4


 - [ ] ID-170
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4


 - [ ] ID-171
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3) allows old versions

node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3


 - [ ] ID-172
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4


 - [ ] ID-173
Pragma version[^0.8.0](contracts/token/StakingRewards.sol#L2) allows old versions

contracts/token/StakingRewards.sol#L2


 - [ ] ID-174
Pragma version[^0.8.0](contracts/token/SealedSYN.sol#L2) allows old versions

contracts/token/SealedSYN.sol#L2


 - [ ] ID-175
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4


 - [ ] ID-176
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4


 - [ ] ID-177
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4


 - [ ] ID-178
Pragma version[^0.8.0](contracts/ERC20X.sol#L2) allows old versions

contracts/ERC20X.sol#L2


 - [ ] ID-179
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4


 - [ ] ID-180
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4


 - [ ] ID-181
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4


 - [ ] ID-182
Pragma version[^0.8.0](contracts/DebtPool.sol#L2) allows old versions

contracts/DebtPool.sol#L2


 - [ ] ID-183
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4


 - [ ] ID-184
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/security/Pausable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/security/Pausable.sol#L4


 - [ ] ID-185
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4


 - [ ] ID-186
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4


 - [ ] ID-187
Pragma version[^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4


 - [ ] ID-188
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4


 - [ ] ID-189
Pragma version[^0.8.0](contracts/interfaces/ISyntheX.sol#L2) allows old versions

contracts/interfaces/ISyntheX.sol#L2


 - [ ] ID-190
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5) allows old versions

node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5


 - [ ] ID-191
Pragma version[^0.8.0](contracts/token/ERC20Sealed.sol#L2) allows old versions

contracts/token/ERC20Sealed.sol#L2


 - [ ] ID-192
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4


 - [ ] ID-193
Pragma version[^0.8.0](contracts/PriceOracle.sol#L2) allows old versions

contracts/PriceOracle.sol#L2


 - [ ] ID-194
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/Ownable.sol#L4


 - [ ] ID-195
Pragma version[^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4


 - [ ] ID-196
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4


 - [ ] ID-197
Pragma version[^0.8.1](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4


 - [ ] ID-198
Pragma version[^0.8.0](contracts/interfaces/IPriceOracle.sol#L2) allows old versions

contracts/interfaces/IPriceOracle.sol#L2


 - [ ] ID-199
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4


 - [ ] ID-200
Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-201
Low level call in [Multicall2.aggregate(Multicall2.Call[])](contracts/utils/Multicall2.sol#L20-L28):
	- [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L24)

contracts/utils/Multicall2.sol#L20-L28


 - [ ] ID-202
Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137):
	- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L135)

node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137


 - [ ] ID-203
Low level call in [Multicall2.tryAggregate(bool,Multicall2.Call[])](contracts/utils/Multicall2.sol#L56-L67):
	- [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L59)

contracts/utils/Multicall2.sol#L56-L67


 - [ ] ID-204
Low level call in [AddressUpgradeable.sendValue(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L60-L65):
	- [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L63)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L60-L65


 - [ ] ID-205
Low level call in [Address.sendValue(address,uint256)](node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65):
	- [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts/utils/Address.sol#L63)

node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65


 - [ ] ID-206
Low level call in [AddressUpgradeable.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137):
	- [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137


 - [ ] ID-207
Low level call in [AddressUpgradeable.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L155-L162):
	- [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L160)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L155-L162


 - [ ] ID-208
Low level call in [ERC1967UpgradeUpgradeable._functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204):
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L202)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204


 - [ ] ID-209
Low level call in [Address.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162):
	- [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L160)

node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162


 - [ ] ID-210
Low level call in [Address.functionDelegateCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187):
	- [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L185)

node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-211
Parameter [DebtPool.mint(address,address,address,uint256,uint256)._synth](contracts/DebtPool.sol#L238) is not in mixedCase

contracts/DebtPool.sol#L238


 - [ ] ID-212
Parameter [SyntheX.getUserTotalDebtUSD(address)._account](contracts/SyntheX.sol#L800) is not in mixedCase

contracts/SyntheX.sol#L800


 - [ ] ID-213
Parameter [SyntheX.enterPool(address)._tradingPool](contracts/SyntheX.sol#L97) is not in mixedCase

contracts/SyntheX.sol#L97


 - [ ] ID-214
Parameter [SyntheX.initialize(address,address,uint256)._sealedSyn](contracts/SyntheX.sol#L55) is not in mixedCase

contracts/SyntheX.sol#L55


 - [ ] ID-215
Parameter [DebtPool.mint(address,address,address,uint256,uint256)._borrower](contracts/DebtPool.sol#L238) is not in mixedCase

contracts/DebtPool.sol#L238


 - [ ] ID-216
Parameter [Vault.withdraw(address,uint256)._tokenAddress](contracts/utils/FeeVault.sol#L33) is not in mixedCase

contracts/utils/FeeVault.sol#L33


 - [ ] ID-217
Function [IERC20PermitUpgradeable.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L59) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L59


 - [ ] ID-218
Parameter [SyntheX.withdraw(address,uint256)._collateral](contracts/SyntheX.sol#L204) is not in mixedCase

contracts/SyntheX.sol#L204


 - [ ] ID-219
Parameter [SyntheX.burn(address,address,uint256)._synth](contracts/SyntheX.sol#L278) is not in mixedCase

contracts/SyntheX.sol#L278


 - [ ] ID-220
Parameter [DebtPool.removeSynth(address)._synth](contracts/DebtPool.sol#L122) is not in mixedCase

contracts/DebtPool.sol#L122


 - [ ] ID-221
Parameter [SyntheX.withdraw(address,uint256)._amount](contracts/SyntheX.sol#L204) is not in mixedCase

contracts/SyntheX.sol#L204


 - [ ] ID-222
Parameter [SyntheX.updatePoolRewardIndex(address,address)._tradingPool](contracts/SyntheX.sol#L552) is not in mixedCase

contracts/SyntheX.sol#L552


 - [ ] ID-223
Parameter [DebtPool.updateFee(uint256,uint256)._fee](contracts/DebtPool.sol#L88) is not in mixedCase

contracts/DebtPool.sol#L88


 - [ ] ID-224
Parameter [DebtPool.getUserDebtUSD(address)._account](contracts/DebtPool.sol#L170) is not in mixedCase

contracts/DebtPool.sol#L170


 - [ ] ID-225
Parameter [StakingRewards.setRewardsDuration(uint256)._rewardsDuration](contracts/token/StakingRewards.sol#L193) is not in mixedCase

contracts/token/StakingRewards.sol#L193


 - [ ] ID-226
Parameter [DebtPool.burn(address,address,address,uint256,uint256)._borrower](contracts/DebtPool.sol#L303) is not in mixedCase

contracts/DebtPool.sol#L303


 - [ ] ID-227
Function [AccessControlUpgradeable.__AccessControl_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L54-L55) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L54-L55


 - [ ] ID-228
Parameter [DebtPool.burn(address,address,address,uint256,uint256)._synth](contracts/DebtPool.sol#L303) is not in mixedCase

contracts/DebtPool.sol#L303


 - [ ] ID-229
Parameter [SyntheX.liquidate(address,address,address,uint256,address)._inAmount](contracts/SyntheX.sol#L339) is not in mixedCase

contracts/SyntheX.sol#L339


 - [ ] ID-230
Function [ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L24-L25


 - [ ] ID-231
Parameter [SyntheX.enableTradingPool(address,uint256)._volatilityRatio](contracts/SyntheX.sol#L438) is not in mixedCase

contracts/SyntheX.sol#L438


 - [ ] ID-232
Parameter [SyntheX.updatePoolRewardIndex(address,address)._rewardToken](contracts/SyntheX.sol#L552) is not in mixedCase

contracts/SyntheX.sol#L552


 - [ ] ID-233
Variable [ContextUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L36) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L36


 - [ ] ID-234
Parameter [DebtPool.burn(address,address,address,uint256,uint256)._amount](contracts/DebtPool.sol#L303) is not in mixedCase

contracts/DebtPool.sol#L303


 - [ ] ID-235
Parameter [SyntheX.grantRewardInternal(address,address,uint256)._reward](contracts/SyntheX.sol#L649) is not in mixedCase

contracts/SyntheX.sol#L649


 - [ ] ID-236
Function [ReentrancyGuardUpgradeable.__ReentrancyGuard_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46


 - [ ] ID-237
Variable [AccessControlUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259


 - [ ] ID-238
Parameter [TokenUnlocker.getRequestId(address,uint256)._user](contracts/token/TokenUnlocker.sol#L238) is not in mixedCase

contracts/token/TokenUnlocker.sol#L238


 - [ ] ID-239
Parameter [AddressStorage.getAddress(bytes32)._key](contracts/utils/AddressStorage.sol#L28) is not in mixedCase

contracts/utils/AddressStorage.sol#L28


 - [ ] ID-240
Variable [TokenUnlocker.SEALED_TOKEN](contracts/token/TokenUnlocker.sol#L39) is not in mixedCase

contracts/token/TokenUnlocker.sol#L39


 - [ ] ID-241
Parameter [SyntheX.setCollateralCap(address,uint256)._collateral](contracts/SyntheX.sol#L498) is not in mixedCase

contracts/SyntheX.sol#L498


 - [ ] ID-242
Parameter [SyntheX.setPoolSpeed(address,address,uint256)._rewardToken](contracts/SyntheX.sol#L534) is not in mixedCase

contracts/SyntheX.sol#L534


 - [ ] ID-243
Parameter [DebtPool.mint(address,address,address,uint256,uint256)._account](contracts/DebtPool.sol#L238) is not in mixedCase

contracts/DebtPool.sol#L238


 - [ ] ID-244
Parameter [DebtPool.disableSynth(address)._synth](contracts/DebtPool.sol#L109) is not in mixedCase

contracts/DebtPool.sol#L109


 - [ ] ID-245
Parameter [DebtPool.burnSynth(address,address,uint256)._synth](contracts/DebtPool.sol#L327) is not in mixedCase

contracts/DebtPool.sol#L327


 - [ ] ID-246
Parameter [DebtPool.burn(address,address,address,uint256,uint256)._repayer](contracts/DebtPool.sol#L303) is not in mixedCase

contracts/DebtPool.sol#L303


 - [ ] ID-247
Variable [TokenUnlocker.TOKEN](contracts/token/TokenUnlocker.sol#L41) is not in mixedCase

contracts/token/TokenUnlocker.sol#L41


 - [ ] ID-248
Parameter [SyntheX.grantRewardInternal(address,address,uint256)._user](contracts/SyntheX.sol#L649) is not in mixedCase

contracts/SyntheX.sol#L649


 - [ ] ID-249
Variable [UUPSUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L107) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L107


 - [ ] ID-250
Parameter [SyntheX.initialize(address,address,uint256)._system](contracts/SyntheX.sol#L55) is not in mixedCase

contracts/SyntheX.sol#L55


 - [ ] ID-251
Parameter [SyntheX.claimReward(address,address[],address[])._tradingPools](contracts/SyntheX.sol#L625) is not in mixedCase

contracts/SyntheX.sol#L625


 - [ ] ID-252
Variable [EIP712._TYPE_HASH](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L37) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L37


 - [ ] ID-253
Parameter [SyntheX.disableCollateral(address)._collateral](contracts/SyntheX.sol#L487) is not in mixedCase

contracts/SyntheX.sol#L487


 - [ ] ID-254
Variable [PausableUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L116) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L116


 - [ ] ID-255
Parameter [DebtPool.burnSynth(address,address,uint256)._user](contracts/DebtPool.sol#L327) is not in mixedCase

contracts/DebtPool.sol#L327


 - [ ] ID-256
Parameter [SyntheX.getRewardsAccrued(address,address,address[])._rewardToken](contracts/SyntheX.sol#L674) is not in mixedCase

contracts/SyntheX.sol#L674


 - [ ] ID-257
Parameter [SyntheX.disableTradingPool(address)._tradingPool](contracts/SyntheX.sol#L457) is not in mixedCase

contracts/SyntheX.sol#L457


 - [ ] ID-258
Function [ERC20Upgradeable.__ERC20_init_unchained(string,string)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L59-L62) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L59-L62


 - [ ] ID-259
Parameter [DebtPool.updateFeeToken(address)._feeToken](contracts/DebtPool.sol#L98) is not in mixedCase

contracts/DebtPool.sol#L98


 - [ ] ID-260
Parameter [SyntheX.liquidate(address,address,address,uint256,address)._outAsset](contracts/SyntheX.sol#L339) is not in mixedCase

contracts/SyntheX.sol#L339


 - [ ] ID-261
Parameter [SyntheX.grantRewardInternal(address,address,uint256)._amount](contracts/SyntheX.sol#L649) is not in mixedCase

contracts/SyntheX.sol#L649


 - [ ] ID-262
Variable [ERC1967UpgradeUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L211) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L211


 - [ ] ID-263
Parameter [SyntheX.exchange(address,address,address,uint256)._debtPool](contracts/SyntheX.sol#L306) is not in mixedCase

contracts/SyntheX.sol#L306


 - [ ] ID-264
Parameter [ERC20X.updateFlashFee(uint256)._flashLoanFee](contracts/ERC20X.sol#L40) is not in mixedCase

contracts/ERC20X.sol#L40


 - [ ] ID-265
Parameter [SyntheX.initialize(address,address,uint256)._safeCRatio](contracts/SyntheX.sol#L55) is not in mixedCase

contracts/SyntheX.sol#L55


 - [ ] ID-266
Parameter [SyntheX.getBorrowCapacity(address)._account](contracts/SyntheX.sol#L835) is not in mixedCase

contracts/SyntheX.sol#L835


 - [ ] ID-267
Parameter [Crowdsale.updateRate(uint256)._rate](contracts/token/Crowdsale.sol#L120) is not in mixedCase

contracts/token/Crowdsale.sol#L120


 - [ ] ID-268
Function [ERC20Upgradeable.__ERC20_init(string,string)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L55-L57) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L55-L57


 - [ ] ID-269
Parameter [TokenUnlocker.unlock(bytes32[])._requestIds](contracts/token/TokenUnlocker.sol#L229) is not in mixedCase

contracts/token/TokenUnlocker.sol#L229


 - [ ] ID-270
Function [ReentrancyGuardUpgradeable.__ReentrancyGuard_init()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L40-L42) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L40-L42


 - [ ] ID-271
Parameter [SyntheX.exchange(address,address,address,uint256)._synthFrom](contracts/SyntheX.sol#L306) is not in mixedCase

contracts/SyntheX.sol#L306


 - [ ] ID-272
Parameter [TokenUnlocker.startUnlock(uint256)._amount](contracts/token/TokenUnlocker.sol#L171) is not in mixedCase

contracts/token/TokenUnlocker.sol#L171


 - [ ] ID-273
Parameter [DebtPool.mintSynth(address,address,uint256,uint256)._amount](contracts/DebtPool.sol#L260) is not in mixedCase

contracts/DebtPool.sol#L260


 - [ ] ID-274
Function [ERC165Upgradeable.__ERC165_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L27-L28) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L27-L28


 - [ ] ID-275
Function [ContextUpgradeable.__Context_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L21-L22


 - [ ] ID-276
Parameter [SyntheX.exitPool(address)._tradingPool](contracts/SyntheX.sol#L112) is not in mixedCase

contracts/SyntheX.sol#L112


 - [ ] ID-277
Parameter [DebtPool.burnSynth(address,address,uint256)._amount](contracts/DebtPool.sol#L327) is not in mixedCase

contracts/DebtPool.sol#L327


 - [ ] ID-278
Parameter [SyntheX.issue(address,address,uint256)._debtPool](contracts/SyntheX.sol#L238) is not in mixedCase

contracts/SyntheX.sol#L238


 - [ ] ID-279
Variable [EIP712._CACHED_THIS](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L33) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L33


 - [ ] ID-280
Parameter [SyntheX.exchange(address,address,address,uint256)._synthTo](contracts/SyntheX.sol#L306) is not in mixedCase

contracts/SyntheX.sol#L306


 - [ ] ID-281
Function [UUPSUpgradeable.__UUPSUpgradeable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L26-L27) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L26-L27


 - [ ] ID-282
Parameter [MockPriceFeed.setPrice(int256,uint8).__decimals](contracts/mock/MockPriceFeed.sol#L14) is not in mixedCase

contracts/mock/MockPriceFeed.sol#L14


 - [ ] ID-283
Variable [ERC20Upgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L400) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L400


 - [ ] ID-284
Parameter [PriceOracle.setFeed(address,address)._feed](contracts/PriceOracle.sol#L29) is not in mixedCase

contracts/PriceOracle.sol#L29


 - [ ] ID-285
Parameter [SyntheX.burn(address,address,uint256)._debtPool](contracts/SyntheX.sol#L278) is not in mixedCase

contracts/SyntheX.sol#L278


 - [ ] ID-286
Variable [ReentrancyGuardUpgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L80) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L80


 - [ ] ID-287
Variable [ERC20Permit._PERMIT_TYPEHASH_DEPRECATED_SLOT](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L37) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L37


 - [ ] ID-288
Parameter [TokenUnlocker.setLockPeriod(uint256)._lockPeriod](contracts/token/TokenUnlocker.sol#L97) is not in mixedCase

contracts/token/TokenUnlocker.sol#L97


 - [ ] ID-289
Function [IERC20Permit.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L59) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L59


 - [ ] ID-290
Parameter [SyntheX.setPoolSpeed(address,address,uint256)._speed](contracts/SyntheX.sol#L534) is not in mixedCase

contracts/SyntheX.sol#L534


 - [ ] ID-291
Parameter [SyntheX.issue(address,address,uint256)._synth](contracts/SyntheX.sol#L238) is not in mixedCase

contracts/SyntheX.sol#L238


 - [ ] ID-292
Parameter [SyntheX.getAdjustedUserTotalDebtUSD(address)._account](contracts/SyntheX.sol#L818) is not in mixedCase

contracts/SyntheX.sol#L818


 - [ ] ID-293
Parameter [System.setAddress(bytes32,address)._value](contracts/System.sol#L40) is not in mixedCase

contracts/System.sol#L40


 - [ ] ID-294
Function [AccessControlUpgradeable.__AccessControl_init()](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L51-L52) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L51-L52


 - [ ] ID-295
Parameter [DebtPool.mintSynth(address,address,uint256,uint256)._synth](contracts/DebtPool.sol#L260) is not in mixedCase

contracts/DebtPool.sol#L260


 - [ ] ID-296
Variable [EIP712._CACHED_CHAIN_ID](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L32) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L32


 - [ ] ID-297
Parameter [DebtPool.initialize(string,string,address)._system](contracts/DebtPool.sol#L52) is not in mixedCase

contracts/DebtPool.sol#L52


 - [ ] ID-298
Parameter [SyntheX.burn(address,address,uint256)._amount](contracts/SyntheX.sol#L278) is not in mixedCase

contracts/SyntheX.sol#L278


 - [ ] ID-299
Parameter [SyntheX.getAdjustedUserTotalCollateralUSD(address)._account](contracts/SyntheX.sol#L771) is not in mixedCase

contracts/SyntheX.sol#L771


 - [ ] ID-300
Parameter [SyntheX.healthFactor(address)._account](contracts/SyntheX.sol#L713) is not in mixedCase

contracts/SyntheX.sol#L713


 - [ ] ID-301
Function [ERC20Permit.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L81-L83) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L81-L83


 - [ ] ID-302
Parameter [SyntheX.getUserTotalCollateralUSD(address)._account](contracts/SyntheX.sol#L746) is not in mixedCase

contracts/SyntheX.sol#L746


 - [ ] ID-303
Parameter [SyntheX.liquidate(address,address,address,uint256,address)._debtPool](contracts/SyntheX.sol#L339) is not in mixedCase

contracts/SyntheX.sol#L339


 - [ ] ID-304
Parameter [SyntheX.claimReward(address,address,address[])._rewardToken](contracts/SyntheX.sol#L613) is not in mixedCase

contracts/SyntheX.sol#L613


 - [ ] ID-305
Parameter [SyntheX.distributeAccountReward(address,address,address)._debtPool](contracts/SyntheX.sol#L574) is not in mixedCase

contracts/SyntheX.sol#L574


 - [ ] ID-306
Parameter [DebtPool.mint(address,address,address,uint256,uint256)._amountUSD](contracts/DebtPool.sol#L238) is not in mixedCase

contracts/DebtPool.sol#L238


 - [ ] ID-307
Parameter [MockPriceFeed.setPrice(int256,uint8)._price](contracts/mock/MockPriceFeed.sol#L14) is not in mixedCase

contracts/mock/MockPriceFeed.sol#L14


 - [ ] ID-308
Parameter [DebtPool.enableSynth(address)._synth](contracts/DebtPool.sol#L66) is not in mixedCase

contracts/DebtPool.sol#L66


 - [ ] ID-309
Parameter [SyntheX.setSafeCRatio(uint256)._safeCRatio](contracts/SyntheX.sol#L512) is not in mixedCase

contracts/SyntheX.sol#L512


 - [ ] ID-310
Variable [ERC165Upgradeable.__gap](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L41) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L41


 - [ ] ID-311
Parameter [TokenUnlocker.unlocked(bytes32)._requestId](contracts/token/TokenUnlocker.sol#L134) is not in mixedCase

contracts/token/TokenUnlocker.sol#L134


 - [ ] ID-312
Variable [UUPSUpgradeable.__self](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L29) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L29


 - [ ] ID-313
Function [ERC1967UpgradeUpgradeable.__ERC1967Upgrade_init()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L21-L22


 - [ ] ID-314
Parameter [SyntheX.setCollateralCap(address,uint256)._maxDeposit](contracts/SyntheX.sol#L498) is not in mixedCase

contracts/SyntheX.sol#L498


 - [ ] ID-315
Parameter [SyntheX.liquidate(address,address,address,uint256,address)._account](contracts/SyntheX.sol#L339) is not in mixedCase

contracts/SyntheX.sol#L339


 - [ ] ID-316
Parameter [DebtPool.updateFee(uint256,uint256)._alloc](contracts/DebtPool.sol#L88) is not in mixedCase

contracts/DebtPool.sol#L88


 - [ ] ID-317
Parameter [SyntheX.enterCollateral(address)._collateral](contracts/SyntheX.sol#L132) is not in mixedCase

contracts/SyntheX.sol#L132


 - [ ] ID-318
Function [UUPSUpgradeable.__UUPSUpgradeable_init()](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L23-L24) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L23-L24


 - [ ] ID-319
Parameter [PriceOracle.getAssetPrices(address[])._assets](contracts/PriceOracle.sol#L79) is not in mixedCase

contracts/PriceOracle.sol#L79


 - [ ] ID-320
Parameter [DebtPool.mint(address,address,address,uint256,uint256)._amount](contracts/DebtPool.sol#L238) is not in mixedCase

contracts/DebtPool.sol#L238


 - [ ] ID-321
Parameter [SyntheX.updateRewardToken(address,bool)._rewardToken](contracts/SyntheX.sol#L519) is not in mixedCase

contracts/SyntheX.sol#L519


 - [ ] ID-322
Parameter [Crowdsale.unlockTokens(bytes32)._requestId](contracts/token/Crowdsale.sol#L131) is not in mixedCase

contracts/token/Crowdsale.sol#L131


 - [ ] ID-323
Parameter [SyntheX.getRewardsAccrued(address,address,address[])._tradingPoolsList](contracts/SyntheX.sol#L674) is not in mixedCase

contracts/SyntheX.sol#L674


 - [ ] ID-324
Parameter [SyntheX.getLTV(address)._account](contracts/SyntheX.sol#L730) is not in mixedCase

contracts/SyntheX.sol#L730


 - [ ] ID-325
Parameter [PriceOracle.getAssetPrice(address)._asset](contracts/PriceOracle.sol#L61) is not in mixedCase

contracts/PriceOracle.sol#L61


 - [ ] ID-326
Parameter [SyntheX.issue(address,address,uint256)._amount](contracts/SyntheX.sol#L238) is not in mixedCase

contracts/SyntheX.sol#L238


 - [ ] ID-327
Variable [EIP712._HASHED_NAME](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L35) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L35


 - [ ] ID-328
Variable [AddressStorage.__gap](contracts/utils/AddressStorage.sol#L43) is not in mixedCase

contracts/utils/AddressStorage.sol#L43


 - [ ] ID-329
Variable [SyntheXStorage.__gap](contracts/SyntheXStorage.sol#L81) is not in mixedCase

contracts/SyntheXStorage.sol#L81


 - [ ] ID-330
Parameter [System.setAddress(bytes32,address)._key](contracts/System.sol#L40) is not in mixedCase

contracts/System.sol#L40


 - [ ] ID-331
Parameter [SyntheX.distributeAccountReward(address,address,address)._account](contracts/SyntheX.sol#L574) is not in mixedCase

contracts/SyntheX.sol#L574


 - [ ] ID-332
Parameter [TokenUnlocker.getRequestId(address,uint256)._unlockIndex](contracts/token/TokenUnlocker.sol#L238) is not in mixedCase

contracts/token/TokenUnlocker.sol#L238


 - [ ] ID-333
Parameter [SyntheX.setPoolSpeed(address,address,uint256)._tradingPool](contracts/SyntheX.sol#L534) is not in mixedCase

contracts/SyntheX.sol#L534


 - [ ] ID-334
Constant [SyntheXStorage.rewardInitialIndex](contracts/SyntheXStorage.sol#L25) is not in UPPER_CASE_WITH_UNDERSCORES

contracts/SyntheXStorage.sol#L25


 - [ ] ID-335
Parameter [SyntheX.claimReward(address,address[],address[])._rewardToken](contracts/SyntheX.sol#L625) is not in mixedCase

contracts/SyntheX.sol#L625


 - [ ] ID-336
Parameter [DebtPool.mintSynth(address,address,uint256,uint256)._user](contracts/DebtPool.sol#L260) is not in mixedCase

contracts/DebtPool.sol#L260


 - [ ] ID-337
Parameter [PriceOracle.getFeed(address)._token](contracts/PriceOracle.sol#L52) is not in mixedCase

contracts/PriceOracle.sol#L52


 - [ ] ID-338
Function [PausableUpgradeable.__Pausable_init()](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L34-L36) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L34-L36


 - [ ] ID-339
Parameter [PriceOracle.setFeed(address,address)._token](contracts/PriceOracle.sol#L29) is not in mixedCase

contracts/PriceOracle.sol#L29


 - [ ] ID-340
Parameter [SyntheX.enableTradingPool(address,uint256)._tradingPool](contracts/SyntheX.sol#L438) is not in mixedCase

contracts/SyntheX.sol#L438


 - [ ] ID-341
Function [ContextUpgradeable.__Context_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L18-L19) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L18-L19


 - [ ] ID-342
Parameter [SyntheX.deposit(address,uint256)._collateral](contracts/SyntheX.sol#L164) is not in mixedCase

contracts/SyntheX.sol#L164


 - [ ] ID-343
Parameter [SyntheX.exchange(address,address,address,uint256)._amount](contracts/SyntheX.sol#L306) is not in mixedCase

contracts/SyntheX.sol#L306


 - [ ] ID-344
Parameter [SyntheX.enableCollateral(address,uint256)._volatilityRatio](contracts/SyntheX.sol#L470) is not in mixedCase

contracts/SyntheX.sol#L470


 - [ ] ID-345
Parameter [SyntheX.deposit(address,uint256)._amount](contracts/SyntheX.sol#L164) is not in mixedCase

contracts/SyntheX.sol#L164


 - [ ] ID-346
Function [ERC165Upgradeable.__ERC165_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L24-L25


 - [ ] ID-347
Variable [EIP712._CACHED_DOMAIN_SEPARATOR](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L31) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L31


 - [ ] ID-348
Parameter [TokenUnlocker.withdraw(uint256)._amount](contracts/token/TokenUnlocker.sol#L108) is not in mixedCase

contracts/token/TokenUnlocker.sol#L108


 - [ ] ID-349
Parameter [SyntheX.getRewardsAccrued(address,address,address[])._account](contracts/SyntheX.sol#L674) is not in mixedCase

contracts/SyntheX.sol#L674


 - [ ] ID-350
Parameter [SyntheX.liquidate(address,address,address,uint256,address)._inAsset](contracts/SyntheX.sol#L339) is not in mixedCase

contracts/SyntheX.sol#L339


 - [ ] ID-351
Variable [EIP712._HASHED_VERSION](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L36) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L36


 - [ ] ID-352
Parameter [SyntheX.enableCollateral(address,uint256)._collateral](contracts/SyntheX.sol#L470) is not in mixedCase

contracts/SyntheX.sol#L470


 - [ ] ID-353
Parameter [SyntheX.exitCollateral(address)._collateral](contracts/SyntheX.sol#L147) is not in mixedCase

contracts/SyntheX.sol#L147


 - [ ] ID-354
Function [PausableUpgradeable.__Pausable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L38-L40) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L38-L40


 - [ ] ID-355
Parameter [SyntheX.distributeAccountReward(address,address,address)._rewardToken](contracts/SyntheX.sol#L574) is not in mixedCase

contracts/SyntheX.sol#L574


## redundant-statements
Impact: Informational
Confidence: High
 - [ ] ID-356
Redundant expression "[amount](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L55)" in[ERC20FlashMint](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L19-L109)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L55


 - [ ] ID-357
Redundant expression "[token](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L54)" in[ERC20FlashMint](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L19-L109)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L54


 - [ ] ID-358
Redundant expression "[token](contracts/ERC20X.sol#L53)" in[ERC20X](contracts/ERC20X.sol#L16-L94)

contracts/ERC20X.sol#L53


## reentrancy-unlimited-gas
Impact: Informational
Confidence: Medium
 - [ ] ID-359
Reentrancy in [Crowdsale.buyTokens()](contracts/token/Crowdsale.sol#L83-L117):
	External calls:
	- [wallet.transfer(msg.value)](contracts/token/Crowdsale.sol#L115)
	Event emitted after the call(s):
	- [TokenPurchase(msg.sender,msg.value,tokens)](contracts/token/Crowdsale.sol#L116)

contracts/token/Crowdsale.sol#L83-L117


 - [ ] ID-360
Reentrancy in [SyntheX.withdraw(address,uint256)](contracts/SyntheX.sol#L204-L230):
	External calls:
	- [address(msg.sender).transfer(_amount)](contracts/SyntheX.sol#L216)
	State variables written after the call(s):
	- [supply.totalDeposits = supply.totalDeposits.sub(_amount)](contracts/SyntheX.sol#L226)
	Event emitted after the call(s):
	- [Withdraw(msg.sender,_collateral,_amount)](contracts/SyntheX.sol#L229)

contracts/SyntheX.sol#L204-L230


## similar-names
Impact: Informational
Confidence: Medium
 - [ ] ID-361
Variable [SyntheX.enableTradingPool(address,uint256)._tradingPool](contracts/SyntheX.sol#L438) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/SyntheX.sol#L438


 - [ ] ID-362
Variable [ISyntheX.enterPool(address)._tradingPool](contracts/interfaces/ISyntheX.sol#L10) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L10


 - [ ] ID-363
Variable [SyntheX.exitCollateral(address)._collateral](contracts/SyntheX.sol#L147) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L147


 - [ ] ID-364
Variable [TokenUnlocker.startUnlock(uint256)._unlockRequest](contracts/token/TokenUnlocker.sol#L182) is too similar to [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L53)

contracts/token/TokenUnlocker.sol#L182


 - [ ] ID-365
Variable [ISyntheX.deposit(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L14) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L14


 - [ ] ID-366
Variable [ISyntheX.burn(address,address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L17) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L17


 - [ ] ID-367
Variable [SyntheX.setPoolSpeed(address,address,uint256)._tradingPool](contracts/SyntheX.sol#L534) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/SyntheX.sol#L534


 - [ ] ID-368
Variable [SyntheX.setCollateralCap(address,uint256)._collateral](contracts/SyntheX.sol#L498) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L498


 - [ ] ID-369
Variable [SyntheX.disableCollateral(address)._collateral](contracts/SyntheX.sol#L487) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L487


 - [ ] ID-370
Variable [ISyntheX.withdraw(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L15) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L15


 - [ ] ID-371
Variable [ISyntheX.setPoolSpeed(address,address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L19) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L19


 - [ ] ID-372
Variable [SyntheX.enableCollateral(address,uint256)._collateral](contracts/SyntheX.sol#L470) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L470


 - [ ] ID-373
Variable [SyntheX.enterCollateral(address)._collateral](contracts/SyntheX.sol#L132) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L132


 - [ ] ID-374
Variable [System.L1_ADMIN_ROLE](contracts/System.sol#L24) is too similar to [System.L2_ADMIN_ROLE](contracts/System.sol#L25)

contracts/System.sol#L24


 - [ ] ID-375
Variable [ISyntheX.exitPool(address)._tradingPool](contracts/interfaces/ISyntheX.sol#L11) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L11


 - [ ] ID-376
Variable [ISyntheX.exitCollateral(address)._collateral](contracts/interfaces/ISyntheX.sol#L13) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L13


 - [ ] ID-377
Variable [SyntheX.exitPool(address)._tradingPool](contracts/SyntheX.sol#L112) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/SyntheX.sol#L112


 - [ ] ID-378
Variable [ISyntheX.enterCollateral(address)._collateral](contracts/interfaces/ISyntheX.sol#L12) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L12


 - [ ] ID-379
Variable [ISyntheX.issue(address,address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L16) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L16


 - [ ] ID-380
Variable [ISyntheX.exchange(address,address,address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L18) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L18


 - [ ] ID-381
Variable [ISyntheX.setCollateralCap(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L30) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L30


 - [ ] ID-382
Variable [SyntheX.updatePoolRewardIndex(address,address)._tradingPool](contracts/SyntheX.sol#L552) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/SyntheX.sol#L552


 - [ ] ID-383
Variable [ISyntheX.enableCollateral(address,uint256)._collateral](contracts/interfaces/ISyntheX.sol#L27) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L27


 - [ ] ID-384
Variable [SyntheX.enterPool(address)._tradingPool](contracts/SyntheX.sol#L97) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/SyntheX.sol#L97


 - [ ] ID-385
Variable [ISyntheX.liquidate(address,address,address,uint256,address)._tradingPool](contracts/interfaces/ISyntheX.sol#L20) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L20


 - [ ] ID-386
Variable [ISyntheX.disableCollateral(address)._collateral](contracts/interfaces/ISyntheX.sol#L28) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/interfaces/ISyntheX.sol#L28


 - [ ] ID-387
Variable [SyntheX.disableTradingPool(address)._tradingPool](contracts/SyntheX.sol#L457) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/SyntheX.sol#L457


 - [ ] ID-388
Variable [SyntheXToken.L1_ADMIN_ROLE](contracts/token/SyntheXToken.sol#L17) is too similar to [SyntheXToken.L2_ADMIN_ROLE](contracts/token/SyntheXToken.sol#L18)

contracts/token/SyntheXToken.sol#L17


 - [ ] ID-389
Variable [ISyntheX.disableTradingPool(address)._tradingPool](contracts/interfaces/ISyntheX.sol#L26) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L26


 - [ ] ID-390
Variable [SyntheX.deposit(address,uint256)._collateral](contracts/SyntheX.sol#L164) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L164


 - [ ] ID-391
Variable [ISyntheX.enableTradingPool(address,uint256)._tradingPool](contracts/interfaces/ISyntheX.sol#L25) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L52)

contracts/interfaces/ISyntheX.sol#L25


 - [ ] ID-392
Variable [SyntheX.withdraw(address,uint256)._collateral](contracts/SyntheX.sol#L204) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L55)

contracts/SyntheX.sol#L204


## unused-state
Impact: Informational
Confidence: High
 - [ ] ID-393
[Crowdsale.sealedToken](contracts/token/Crowdsale.sol#L53) is never used in [Crowdsale](contracts/token/Crowdsale.sol#L14-L161)

contracts/token/Crowdsale.sol#L53


## constable-states
Impact: Optimization
Confidence: High
 - [ ] ID-394
[Crowdsale.sealedToken](contracts/token/Crowdsale.sol#L53) should be constant 

contracts/token/Crowdsale.sol#L53


## immutable-states
Impact: Optimization
Confidence: High
 - [ ] ID-395
[SyntheXToken.system](contracts/token/SyntheXToken.sol#L15) should be immutable 

contracts/token/SyntheXToken.sol#L15


 - [ ] ID-396
[Crowdsale.startTime](contracts/token/Crowdsale.sol#L18) should be immutable 

contracts/token/Crowdsale.sol#L18


 - [ ] ID-397
[ERC20X.pool](contracts/ERC20X.sol#L21) should be immutable 

contracts/ERC20X.sol#L21


 - [ ] ID-398
[TokenUnlocker.system](contracts/token/TokenUnlocker.sol#L57) should be immutable 

contracts/token/TokenUnlocker.sol#L57


 - [ ] ID-399
[StakingRewards.system](contracts/token/StakingRewards.sol#L22) should be immutable 

contracts/token/StakingRewards.sol#L22


 - [ ] ID-400
[Vault.system](contracts/utils/FeeVault.sol#L17) should be immutable 

contracts/utils/FeeVault.sol#L17


 - [ ] ID-401
[Crowdsale.wallet](contracts/token/Crowdsale.sol#L23) should be immutable 

contracts/token/Crowdsale.sol#L23


 - [ ] ID-402
[StakingRewards.stakingToken](contracts/token/StakingRewards.sol#L26) should be immutable 

contracts/token/StakingRewards.sol#L26


 - [ ] ID-403
[ERC20X.system](contracts/ERC20X.sol#L23) should be immutable 

contracts/ERC20X.sol#L23


 - [ ] ID-404
[PriceOracle.system](contracts/PriceOracle.sol#L18) should be immutable 

contracts/PriceOracle.sol#L18


 - [ ] ID-405
[TokenUnlocker.SEALED_TOKEN](contracts/token/TokenUnlocker.sol#L39) should be immutable 

contracts/token/TokenUnlocker.sol#L39


 - [ ] ID-406
[TokenUnlocker.percUnlockAtRelease](contracts/token/TokenUnlocker.sol#L49) should be immutable 

contracts/token/TokenUnlocker.sol#L49


 - [ ] ID-407
[TokenUnlocker.unlockPeriod](contracts/token/TokenUnlocker.sol#L47) should be immutable 

contracts/token/TokenUnlocker.sol#L47


 - [ ] ID-408
[Crowdsale.unlockIntervals](contracts/token/Crowdsale.sol#L38) should be immutable 

contracts/token/Crowdsale.sol#L38


 - [ ] ID-409
[SealedSYN.system](contracts/token/SealedSYN.sol#L16) should be immutable 

contracts/token/SealedSYN.sol#L16


 - [ ] ID-410
[Crowdsale.lockInDuration](contracts/token/Crowdsale.sol#L35) should be immutable 

contracts/token/Crowdsale.sol#L35


 - [ ] ID-411
[TokenUnlocker.TOKEN](contracts/token/TokenUnlocker.sol#L41) should be immutable 

contracts/token/TokenUnlocker.sol#L41


 - [ ] ID-412
[StakingRewards.rewardsToken](contracts/token/StakingRewards.sol#L24) should be immutable 

contracts/token/StakingRewards.sol#L24


 - [ ] ID-413
[Crowdsale.token](contracts/token/Crowdsale.sol#L52) should be immutable 

contracts/token/Crowdsale.sol#L52


