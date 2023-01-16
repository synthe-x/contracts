Summary

-   [controlled-delegatecall](#controlled-delegatecall) (1 results) (High)
-   [reentrancy-eth](#reentrancy-eth) (2 results) (High)
-   [unchecked-transfer](#unchecked-transfer) (3 results) (High)
-   [unprotected-upgrade](#unprotected-upgrade) (2 results) (High)
-   [divide-before-multiply](#divide-before-multiply) (22 results) (Medium)
-   [incorrect-equality](#incorrect-equality) (6 results) (Medium)
-   [reentrancy-no-eth](#reentrancy-no-eth) (6 results) (Medium)
-   [tautology](#tautology) (2 results) (Medium)
-   [uninitialized-local](#uninitialized-local) (3 results) (Medium)
-   [unused-return](#unused-return) (1 results) (Medium)
-   [shadowing-local](#shadowing-local) (9 results) (Low)
-   [events-maths](#events-maths) (1 results) (Low)
-   [missing-zero-check](#missing-zero-check) (3 results) (Low)
-   [calls-loop](#calls-loop) (15 results) (Low)
-   [variable-scope](#variable-scope) (3 results) (Low)
-   [reentrancy-benign](#reentrancy-benign) (3 results) (Low)
-   [reentrancy-events](#reentrancy-events) (6 results) (Low)
-   [timestamp](#timestamp) (9 results) (Low)
-   [assembly](#assembly) (13 results) (Informational)
-   [pragma](#pragma) (1 results) (Informational)
-   [costly-loop](#costly-loop) (3 results) (Informational)
-   [solc-version](#solc-version) (71 results) (Informational)
-   [low-level-calls](#low-level-calls) (10 results) (Informational)
-   [naming-convention](#naming-convention) (137 results) (Informational)
-   [redundant-statements](#redundant-statements) (3 results) (Informational)
-   [reentrancy-unlimited-gas](#reentrancy-unlimited-gas) (1 results) (Informational)
-   [similar-names](#similar-names) (42 results) (Informational)
-   [unused-state](#unused-state) (1 results) (Informational)
-   [constable-states](#constable-states) (1 results) (Optimization)
-   [immutable-states](#immutable-states) (4 results) (Optimization)

## controlled-delegatecall

Impact: High
Confidence: Medium

-   [] ID-0
    [ERC1967UpgradeUpgradeable.\_functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204) uses delegatecall to a input-controlled function id - [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L202)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204

## reentrancy-eth

Impact: High
Confidence: Medium

-   [ ] ID-1
        Reentrancy in [StakingRewards.exit()](contracts/token/StakingRewards.sol#L124-L127):
        External calls: - [withdraw(\_balances[msg.sender])](contracts/token/StakingRewards.sol#L125) - [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L110) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135) - [IERC20Upgradeable(stakingToken).safeTransfer(msg.sender,amount)](contracts/token/StakingRewards.sol#L107) - [getReward()](contracts/token/StakingRewards.sol#L126) - [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L110) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135) - [IERC20Upgradeable(rewardsToken).safeTransfer(msg.sender,reward)](contracts/token/StakingRewards.sol#L118)
        External calls sending eth: - [withdraw(\_balances[msg.sender])](contracts/token/StakingRewards.sol#L125) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135) - [getReward()](contracts/token/StakingRewards.sol#L126) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)
        State variables written after the call(s): - [getReward()](contracts/token/StakingRewards.sol#L126) - [\_status = \_NOT_ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L72) - [\_status = \_ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L66)
        [ReentrancyGuardUpgradeable.\_status](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L38) can be used in cross function reentrancies: - [ReentrancyGuardUpgradeable.\_\_ReentrancyGuard_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46) - [ReentrancyGuardUpgradeable.\_nonReentrantAfter()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73) - [ReentrancyGuardUpgradeable.\_nonReentrantBefore()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67) - [getReward()](contracts/token/StakingRewards.sol#L126) - [lastUpdateTime = lastTimeRewardApplicable()](contracts/token/StakingRewards.sol#L177)
        [StakingRewards.lastUpdateTime](contracts/token/StakingRewards.sol#L27) can be used in cross function reentrancies: - [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) - [StakingRewards.lastUpdateTime](contracts/token/StakingRewards.sol#L27) - [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L69-L77) - [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L175-L183) - [getReward()](contracts/token/StakingRewards.sol#L126) - [rewardPerTokenStored = rewardPerToken()](contracts/token/StakingRewards.sol#L176)
        [StakingRewards.rewardPerTokenStored](contracts/token/StakingRewards.sol#L28) can be used in cross function reentrancies: - [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L69-L77) - [StakingRewards.rewardPerTokenStored](contracts/token/StakingRewards.sol#L28) - [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L175-L183) - [getReward()](contracts/token/StakingRewards.sol#L126) - [rewards[msg.sender] = 0](contracts/token/StakingRewards.sol#L117) - [rewards[account] = earned(account)](contracts/token/StakingRewards.sol#L179)
        [StakingRewards.rewards](contracts/token/StakingRewards.sol#L31) can be used in cross function reentrancies: - [StakingRewards.earned(address)](contracts/token/StakingRewards.sol#L80-L82) - [StakingRewards.getReward()](contracts/token/StakingRewards.sol#L113-L121) - [StakingRewards.rewards](contracts/token/StakingRewards.sol#L31) - [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L175-L183) - [getReward()](contracts/token/StakingRewards.sol#L126) - [userRewardPerTokenPaid[account] = rewardPerTokenStored](contracts/token/StakingRewards.sol#L180)
        [StakingRewards.userRewardPerTokenPaid](contracts/token/StakingRewards.sol#L30) can be used in cross function reentrancies: - [StakingRewards.earned(address)](contracts/token/StakingRewards.sol#L80-L82) - [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L175-L183) - [StakingRewards.userRewardPerTokenPaid](contracts/token/StakingRewards.sol#L30)

contracts/token/StakingRewards.sol#L124-L127

-   [ ] ID-2
        Reentrancy in [SyntheX.withdraw(address,uint256)](contracts/SyntheX.sol#L162-L188):
        External calls: - [ERC20Upgradeable(\_collateral).safeTransfer(msg.sender,\_amount)](contracts/SyntheX.sol#L177)
        External calls sending eth: - [address(msg.sender).transfer(\_amount)](contracts/SyntheX.sol#L174)
        State variables written after the call(s): - [supply.totalDeposits = supply.totalDeposits.sub(\_amount)](contracts/SyntheX.sol#L184)
        [SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L61) can be used in cross function reentrancies: - [SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L61) - [SyntheX.setCollateralCap(address,uint256)](contracts/SyntheX.sol#L441-L446)

contracts/SyntheX.sol#L162-L188

## unchecked-transfer

Impact: High
Confidence: Medium

-   [ ] ID-3
        [TokenUnlocker.withdraw(uint256)](contracts/token/TokenUnlocker.sol#L81-L84) ignores return value by [SYN.transfer(msg.sender,\_amount)](contracts/token/TokenUnlocker.sol#L83)

contracts/token/TokenUnlocker.sol#L81-L84

-   [ ] ID-4
        [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) ignores return value by [SEALED_SYN.transferFrom(msg.sender,address(this),\_amount)](contracts/token/TokenUnlocker.sol#L112)

contracts/token/TokenUnlocker.sol#L105-L124

-   [ ] ID-5
        [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) ignores return value by [SYN.transfer(msg.sender,transferAmount)](contracts/token/TokenUnlocker.sol#L135)

contracts/token/TokenUnlocker.sol#L126-L142

## unprotected-upgrade

Impact: High
Confidence: High

-   [ ] ID-6
        [StakingRewards](contracts/token/StakingRewards.sol#L15-L185) is an upgradeable contract that does not protect its initialize functions: [StakingRewards.initialize(address,address)](contracts/token/StakingRewards.sol#L39-L49). Anyone can delete the contract with: [UUPSUpgradeable.upgradeTo(address)](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L72-L75)[UUPSUpgradeable.upgradeToAndCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L85-L88)
        contracts/token/StakingRewards.sol#L15-L185

-   [ ] ID-7
        [SyntheX](contracts/SyntheX.sol#L22-L800) is an upgradeable contract that does not protect its initialize functions: [SyntheX.initialize(address,address)](contracts/SyntheX.sol#L45-L52). Anyone can delete the contract with: [UUPSUpgradeable.upgradeTo(address)](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L72-L75)[UUPSUpgradeable.upgradeToAndCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L85-L88)
        contracts/SyntheX.sol#L22-L800

## divide-before-multiply

Impact: Medium
Confidence: Medium

-   [ ] ID-8
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L124)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-9
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L121)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-10
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L126)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-11
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse = (3 \* denominator) ^ 2](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L117)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-12
        [SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L298-L359) performs a multiplication on the result of a division: - [collateralToSieze = \_inAmount.mul(prices[0].price).mul(10 ** prices[1].decimals).mul(incentive).div(1e18).div(prices[1].price).div(10 ** prices[0].decimals)](contracts/SyntheX.sol#L330-L336) - [SyntheXPool(\_tradingPool).burnSynth(\_inAsset,msg.sender,collateralToSieze.mul(prices[1].price).mul(10 ** prices[0].decimals).mul(1e18).div(incentive).div(prices[0].price).div(10 ** prices[1].decimals))](contracts/SyntheX.sol#L348-L355)

contracts/SyntheX.sol#L298-L359

-   [ ] ID-13
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [prod0 = prod0 / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L105) - [result = prod0 \* inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L132)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-14
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L124)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-15
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L122)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-16
        [SyntheXPool.mintSynth(address,address,uint256)](contracts/SyntheXPool.sol#L219-L226) performs a multiplication on the result of a division: - [ERC20X(\_synth).mint(addressStorage.getAddress(VAULT),\_amount.mul(\_fee.div(BASIS_POINTS)).div(1e18))](contracts/SyntheXPool.sol#L225)

contracts/SyntheXPool.sol#L219-L226

-   [ ] ID-17
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L123)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-18
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L121)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-19
        [SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L298-L359) performs a multiplication on the result of a division: - [collateralToSieze = \_inAmount.mul(prices[0].price).mul(10 ** prices[1].decimals).mul(incentive).div(1e18).div(prices[1].price).div(10 ** prices[0].decimals)](contracts/SyntheX.sol#L330-L336) - [SyntheXPool(\_tradingPool).burn(\_account,collateralToSieze.mul(prices[1].price).mul(1e18).div(incentive).div(10 \*\* prices[1].decimals))](contracts/SyntheX.sol#L347)

contracts/SyntheX.sol#L298-L359

-   [ ] ID-20
        [SyntheX.burn(address,address,uint256)](contracts/SyntheX.sol#L236-L259) performs a multiplication on the result of a division: - [burnablePerc = getUserPoolDebtUSD(msg.sender,\_tradingPool).min(amountUSD).mul(1e18).div(amountUSD)](contracts/SyntheX.sol#L250) - [SyntheXPool(\_tradingPool).burnSynth(\_synth,msg.sender,\_amount.mul(burnablePerc).div(1e18))](contracts/SyntheX.sol#L256)

contracts/SyntheX.sol#L236-L259

-   [ ] ID-21
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse = (3 \* denominator) ^ 2](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L117)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-22
        [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) performs a multiplication on the result of a division: - [rewardRate = reward.div(rewardsDuration)](contracts/token/StakingRewards.sol#L135) - [leftover = remaining.mul(rewardRate)](contracts/token/StakingRewards.sol#L139)

contracts/token/StakingRewards.sol#L132-L153

-   [ ] ID-23
        [SyntheX.burn(address,address,uint256)](contracts/SyntheX.sol#L236-L259) performs a multiplication on the result of a division: - [amountUSD = \_amount.mul(price.price).div(10 \*\* price.decimals)](contracts/SyntheX.sol#L248) - [burnablePerc = getUserPoolDebtUSD(msg.sender,\_tradingPool).min(amountUSD).mul(1e18).div(amountUSD)](contracts/SyntheX.sol#L250) - [SyntheXPool(\_tradingPool).burn(msg.sender,amountUSD.mul(burnablePerc).div(1e18))](contracts/SyntheX.sol#L255)

contracts/SyntheX.sol#L236-L259

-   [ ] ID-24
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L123)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-25
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L122)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-26
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L125)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-27
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [prod0 = prod0 / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L105) - [result = prod0 \* inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L132)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-28
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L126)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

-   [ ] ID-29
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) performs a multiplication on the result of a division: - [denominator = denominator / twos](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L102) - [inverse _= 2 - denominator _ inverse](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L125)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

## incorrect-equality

Impact: Medium
Confidence: High

-   [ ] ID-30
        [SyntheX.burn(address,address,uint256)](contracts/SyntheX.sol#L236-L259) uses a dangerous strict equality: - [burnablePerc == 0](contracts/SyntheX.sol#L253)

contracts/SyntheX.sol#L236-L259

-   [ ] ID-31
        [ERC20Votes.\_writeCheckpoint(ERC20Votes.Checkpoint[],function(uint256,uint256) returns(uint256),uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L239-L256) uses a dangerous strict equality: - [pos > 0 && oldCkpt.fromBlock == block.number](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L251)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L239-L256

-   [ ] ID-32
        [SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L497-L511) uses a dangerous strict equality: - [deltaTimestamp == 0](contracts/SyntheX.sol#L501)

contracts/SyntheX.sol#L497-L511

-   [ ] ID-33
        [SyntheX.healthFactor(address)](contracts/SyntheX.sol#L652-L661) uses a dangerous strict equality: - [totalDebt == 0](contracts/SyntheX.sol#L658)

contracts/SyntheX.sol#L652-L661

-   [ ] ID-34
        [SyntheX.getLTV(address)](contracts/SyntheX.sol#L669-L678) uses a dangerous strict equality: - [totalDebt == 0](contracts/SyntheX.sol#L675)

contracts/SyntheX.sol#L669-L678

-   [ ] ID-35
        [SyntheX.exitPool(address)](contracts/SyntheX.sol#L78-L90) uses a dangerous strict equality: - [require(bool,string)(getUserPoolDebtUSD(msg.sender,\_tradingPool) == 0,SyntheX: Pool debt must be zero)](contracts/SyntheX.sol#L79)

contracts/SyntheX.sol#L78-L90

## reentrancy-no-eth

Impact: Medium
Confidence: Medium

-   [ ] ID-36
        Reentrancy in [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153):
        External calls: - [IERC20Upgradeable(rewardsToken).safeTransferFrom(msg.sender,address(this),reward)](contracts/token/StakingRewards.sol#L133)
        State variables written after the call(s): - [lastUpdateTime = block.timestamp](contracts/token/StakingRewards.sol#L150)
        [StakingRewards.lastUpdateTime](contracts/token/StakingRewards.sol#L27) can be used in cross function reentrancies: - [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) - [StakingRewards.lastUpdateTime](contracts/token/StakingRewards.sol#L27) - [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L69-L77) - [StakingRewards.updateReward(address)](contracts/token/StakingRewards.sol#L175-L183) - [periodFinish = block.timestamp.add(rewardsDuration)](contracts/token/StakingRewards.sol#L151)
        [StakingRewards.periodFinish](contracts/token/StakingRewards.sol#L24) can be used in cross function reentrancies: - [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) - [StakingRewards.initialize(address,address)](contracts/token/StakingRewards.sol#L39-L49) - [StakingRewards.lastTimeRewardApplicable()](contracts/token/StakingRewards.sol#L64-L66) - [StakingRewards.periodFinish](contracts/token/StakingRewards.sol#L24) - [StakingRewards.setRewardsDuration(uint256)](contracts/token/StakingRewards.sol#L163-L170) - [rewardRate = reward.div(rewardsDuration)](contracts/token/StakingRewards.sol#L135)
        [StakingRewards.rewardRate](contracts/token/StakingRewards.sol#L25) can be used in cross function reentrancies: - [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) - [StakingRewards.getRewardForDuration()](contracts/token/StakingRewards.sol#L85-L87) - [StakingRewards.initialize(address,address)](contracts/token/StakingRewards.sol#L39-L49) - [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L69-L77) - [StakingRewards.rewardRate](contracts/token/StakingRewards.sol#L25) - [rewardRate = reward.add(leftover).div(rewardsDuration)](contracts/token/StakingRewards.sol#L140)
        [StakingRewards.rewardRate](contracts/token/StakingRewards.sol#L25) can be used in cross function reentrancies: - [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) - [StakingRewards.getRewardForDuration()](contracts/token/StakingRewards.sol#L85-L87) - [StakingRewards.initialize(address,address)](contracts/token/StakingRewards.sol#L39-L49) - [StakingRewards.rewardPerToken()](contracts/token/StakingRewards.sol#L69-L77) - [StakingRewards.rewardRate](contracts/token/StakingRewards.sol#L25)

contracts/token/StakingRewards.sol#L132-L153

-   [ ] ID-37
        Reentrancy in [SyntheX.deposit(address,uint256)](contracts/SyntheX.sol#L122-L153):
        External calls: - [ERC20Upgradeable(\_collateral).safeTransferFrom(msg.sender,address(this),\_amount)](contracts/SyntheX.sol#L142)
        State variables written after the call(s): - [supply.totalDeposits = supply.totalDeposits.add(\_amount)](contracts/SyntheX.sol#L148)
        [SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L61) can be used in cross function reentrancies: - [SyntheXStorage.collateralSupplies](contracts/SyntheXStorage.sol#L61) - [SyntheX.setCollateralCap(address,uint256)](contracts/SyntheX.sol#L441-L446)

contracts/SyntheX.sol#L122-L153

-   [ ] ID-38
        Reentrancy in [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142):
        External calls: - [SYN.transfer(msg.sender,transferAmount)](contracts/token/TokenUnlocker.sol#L135)
        State variables written after the call(s): - [unlockRequests[\_requestId].amount = unlockRequests[\_requestId].amount.sub(transferAmount)](contracts/token/TokenUnlocker.sol#L136)
        [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34) can be used in cross function reentrancies: - [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) - [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) - [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34)

contracts/token/TokenUnlocker.sol#L126-L142

-   [ ] ID-39
        Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
        External calls: - [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == \_RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
        State variables written after the call(s): - [\_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L102) - [\_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L293)
        [ERC20.\_balances](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L36) can be used in cross function reentrancies: - [ERC20.\_burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301) - [ERC20.\_mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272) - [ERC20.\_transfer(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L226-L248) - [ERC20.balanceOf(address)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L101-L103) - [\_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L104) - [\_balances[account] = accountBalance - amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L293)
        [ERC20.\_balances](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L36) can be used in cross function reentrancies: - [ERC20.\_burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301) - [ERC20.\_mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272) - [ERC20.\_transfer(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L226-L248) - [ERC20.balanceOf(address)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L101-L103) - [\_transfer(address(receiver),flashFeeReceiver,fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L105) - [\_balances[from] = fromBalance - amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L239) - [\_balances[to] += amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L242)
        [ERC20.\_balances](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L36) can be used in cross function reentrancies: - [ERC20.\_burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301) - [ERC20.\_mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272) - [ERC20.\_transfer(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L226-L248) - [ERC20.balanceOf(address)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L101-L103) - [\_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L102) - [\_totalSupply -= amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L295)
        [ERC20.\_totalSupply](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L40) can be used in cross function reentrancies: - [ERC20.\_burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301) - [ERC20.\_mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272) - [ERC20.totalSupply()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L94-L96) - [\_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L104) - [\_totalSupply -= amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L295)
        [ERC20.\_totalSupply](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L40) can be used in cross function reentrancies: - [ERC20.\_burn(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L285-L301) - [ERC20.\_mint(address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L259-L272) - [ERC20.totalSupply()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L94-L96)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108

-   [ ] ID-40
        Reentrancy in [SyntheX.liquidate(address,address,address,uint256,address)](contracts/SyntheX.sol#L298-L359):
        External calls: - [SyntheXPool(\_tradingPool).burn(\_account,collateralToSieze.mul(prices[1].price).mul(1e18).div(incentive).div(10 \*\* prices[1].decimals))](contracts/SyntheX.sol#L347) - [SyntheXPool(\_tradingPool).burnSynth(\_inAsset,msg.sender,collateralToSieze.mul(prices[1].price).mul(10 ** prices[0].decimals).mul(1e18).div(incentive).div(prices[0].price).div(10 ** prices[1].decimals))](contracts/SyntheX.sol#L348-L355)
        State variables written after the call(s): - [accountCollateralBalance[msg.sender][\_outAsset] = accountCollateralBalance[msg.sender][\_outAsset].add(collateralToSieze)](contracts/SyntheX.sol#L358)
        [SyntheXStorage.accountCollateralBalance](contracts/SyntheXStorage.sol#L31) can be used in cross function reentrancies: - [SyntheXStorage.accountCollateralBalance](contracts/SyntheXStorage.sol#L31) - [SyntheX.getAdjustedUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L710-L732) - [SyntheX.getUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L685-L703)

contracts/SyntheX.sol#L298-L359

-   [ ] ID-41
        Reentrancy in [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124):
        External calls: - [SEALED_SYN.transferFrom(msg.sender,address(this),\_amount)](contracts/token/TokenUnlocker.sol#L112)
        State variables written after the call(s): - [reservedForUnlock = reservedForUnlock.add(\_amount)](contracts/token/TokenUnlocker.sol#L121)
        [TokenUnlocker.reservedForUnlock](contracts/token/TokenUnlocker.sol#L25) can be used in cross function reentrancies: - [TokenUnlocker.remainingQuota()](contracts/token/TokenUnlocker.sol#L57-L59) - [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) - [TokenUnlocker.reservedForUnlock](contracts/token/TokenUnlocker.sol#L25) - [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) - [unlockRequestCount[msg.sender] ++](contracts/token/TokenUnlocker.sol#L118)
        [TokenUnlocker.unlockRequestCount](contracts/token/TokenUnlocker.sol#L36) can be used in cross function reentrancies: - [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) - [TokenUnlocker.unlockRequestCount](contracts/token/TokenUnlocker.sol#L36) - [\_unlock.amount = \_amount](contracts/token/TokenUnlocker.sol#L114)
        [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34) can be used in cross function reentrancies: - [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) - [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) - [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34) - [\_unlock.requestTime = block.timestamp](contracts/token/TokenUnlocker.sol#L115)
        [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34) can be used in cross function reentrancies: - [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) - [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) - [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34) - [\_unlock.claimed = 0](contracts/token/TokenUnlocker.sol#L116)
        [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34) can be used in cross function reentrancies: - [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) - [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) - [TokenUnlocker.unlockRequests](contracts/token/TokenUnlocker.sol#L34)

contracts/token/TokenUnlocker.sol#L105-L124

## tautology

Impact: Medium
Confidence: High

-   [ ] ID-42
        [PriceOracle.setFeed(address,address)](contracts/PriceOracle.sol#L20-L30) contains a tautology or contradiction: - [require(bool,string)(feeds[\_token].decimals() >= 0,PriceOracle: Decimals is <= 0)](contracts/PriceOracle.sol#L26)

contracts/PriceOracle.sol#L20-L30

-   [ ] ID-43
        [PriceOracle.getAssetPrice(address)](contracts/PriceOracle.sol#L45-L57) contains a tautology or contradiction: - [require(bool,string)(decimals >= 0,PriceOracle: Decimals is <= 0)](contracts/PriceOracle.sol#L51)

contracts/PriceOracle.sol#L45-L57

## uninitialized-local

Impact: Medium
Confidence: Medium

-   [ ] ID-44
        [ERC20Votes.\_moveVotingPower(address,address,uint256).oldWeight_scope_0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233) is a local variable never initialized

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233

-   [ ] ID-45
        [ERC20Votes.\_moveVotingPower(address,address,uint256).newWeight_scope_1](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233) is a local variable never initialized

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233

-   [ ] ID-46
        [ERC1967UpgradeUpgradeable.\_upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98) is a local variable never initialized

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98

## unused-return

Impact: Medium
Confidence: Medium

-   [ ] ID-47
        [ERC1967UpgradeUpgradeable.\_upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105) ignores return value by [IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98-L102)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105

## shadowing-local

Impact: Low
Confidence: High

-   [ ] ID-48
        [SyntheXPool.burn(address,uint256).totalSupply](contracts/SyntheXPool.sol#L235) shadows: - [ERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L99-L101) (function) - [IERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L27) (function)

contracts/SyntheXPool.sol#L235

-   [ ] ID-49
        [ERC20Permit.constructor(string).name](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L44) shadows: - [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function) - [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L44

-   [ ] ID-50
        [ERC20X.constructor(string,string,address,address).name](contracts/ERC20X.sol#L16) shadows: - [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function) - [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

contracts/ERC20X.sol#L16

-   [ ] ID-51
        [MockToken.constructor(string,string).symbol](contracts/mock/MockToken.sol#L7) shadows: - [ERC20.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L70-L72) (function) - [IERC20Metadata.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L22) (function)

contracts/mock/MockToken.sol#L7

-   [ ] ID-52
        [ERC20X.constructor(string,string,address,address).symbol](contracts/ERC20X.sol#L16) shadows: - [ERC20.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L70-L72) (function) - [IERC20Metadata.symbol()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L22) (function)

contracts/ERC20X.sol#L16

-   [ ] ID-53
        [SyntheXPool.mint(address,uint256).totalSupply](contracts/SyntheXPool.sol#L205) shadows: - [ERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L99-L101) (function) - [IERC20Upgradeable.totalSupply()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L27) (function)

contracts/SyntheXPool.sol#L205

-   [ ] ID-54
        [MockToken.constructor(string,string).name](contracts/mock/MockToken.sol#L7) shadows: - [ERC20.name()](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L62-L64) (function) - [IERC20Metadata.name()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L17) (function)

contracts/mock/MockToken.sol#L7

-   [ ] ID-55
        [SyntheXPool.initialize(string,string,address).symbol](contracts/SyntheXPool.sol#L55) shadows: - [ERC20Upgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L75-L77) (function) - [IERC20MetadataUpgradeable.symbol()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L22) (function)

contracts/SyntheXPool.sol#L55

-   [ ] ID-56
        [SyntheXPool.initialize(string,string,address).name](contracts/SyntheXPool.sol#L55) shadows: - [ERC20Upgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L67-L69) (function) - [IERC20MetadataUpgradeable.name()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L17) (function)

contracts/SyntheXPool.sol#L55

## events-maths

Impact: Low
Confidence: Medium

-   [ ] ID-57
        [ERC20X.updateFlashFee(uint256)](contracts/ERC20X.sol#L25-L28) should emit an event for: - [flashLoanFee = \_flashLoanFee](contracts/ERC20X.sol#L27)

contracts/ERC20X.sol#L25-L28

## missing-zero-check

Impact: Low
Confidence: Medium

-   [ ] ID-58
        [ERC20X.constructor(string,string,address,address).\_pool](contracts/ERC20X.sol#L16) lacks a zero-check on : - [pool = \_pool](contracts/ERC20X.sol#L17)

contracts/ERC20X.sol#L16

-   [ ] ID-59
        [StakingRewards.initialize(address,address).\_stakingToken](contracts/token/StakingRewards.sol#L39) lacks a zero-check on : - [stakingToken = \_stakingToken](contracts/token/StakingRewards.sol#L46)

contracts/token/StakingRewards.sol#L39

-   [ ] ID-60
        [StakingRewards.initialize(address,address).\_rewardsToken](contracts/token/StakingRewards.sol#L39) lacks a zero-check on : - [rewardsToken = \_rewardsToken](contracts/token/StakingRewards.sol#L45)

contracts/token/StakingRewards.sol#L39

## calls-loop

Impact: Low
Confidence: Medium

-   [ ] ID-61
        [SyntheX.getUserPoolDebtUSD(address,address)](contracts/SyntheX.sol#L780-L791) has external calls inside a loop: [poolDebt = SyntheXPool(\_tradingPool).getTotalDebtUSD()](contracts/SyntheX.sol#L788)

contracts/SyntheX.sol#L780-L791

-   [ ] ID-62
        [AddressUpgradeable.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137) has external calls inside a loop: [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137

-   [ ] ID-63
        [SyntheX.distributeAccountReward(address,address,address)](contracts/SyntheX.sol#L518-L549) has external calls inside a loop: [accountDebtTokens = SyntheXPool(\_tradingPool).balanceOf(\_account)](contracts/SyntheX.sol#L540)

contracts/SyntheX.sol#L518-L549

-   [ ] ID-64
        [SyntheX.getAdjustedUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L710-L732) has external calls inside a loop: [price = \_oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L720)

contracts/SyntheX.sol#L710-L732

-   [ ] ID-65
        [SyntheXPool.getTotalDebtUSD()](contracts/SyntheXPool.sol#L137-L152) has external calls inside a loop: [price = \_oracle.getAssetPrice(synth)](contracts/SyntheXPool.sol#L147)

contracts/SyntheXPool.sol#L137-L152

-   [ ] ID-66
        [Multicall2.tryAggregate(bool,Multicall2.Call[])](contracts/utils/Multicall2.sol#L56-L67) has external calls inside a loop: [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L59)

contracts/utils/Multicall2.sol#L56-L67

-   [ ] ID-67
        [SyntheX.getUserTotalCollateralUSD(address)](contracts/SyntheX.sol#L685-L703) has external calls inside a loop: [price = \_oracle.getAssetPrice(collateral)](contracts/SyntheX.sol#L695)

contracts/SyntheX.sol#L685-L703

-   [ ] ID-68
        [PriceOracle.getAssetPrice(address)](contracts/PriceOracle.sol#L45-L57) has external calls inside a loop: [decimals = \_feed.decimals()](contracts/PriceOracle.sol#L48)

contracts/PriceOracle.sol#L45-L57

-   [ ] ID-69
        [SyntheX.getUserPoolDebtUSD(address,address)](contracts/SyntheX.sol#L780-L791) has external calls inside a loop: [totalDebtShare = IERC20(\_tradingPool).totalSupply()](contracts/SyntheX.sol#L782)

contracts/SyntheX.sol#L780-L791

-   [ ] ID-70
        [SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L497-L511) has external calls inside a loop: [borrowAmount = SyntheXPool(\_tradingPool).totalSupply()](contracts/SyntheX.sol#L503)

contracts/SyntheX.sol#L497-L511

-   [ ] ID-71
        [SyntheX.grantRewardInternal(address,address,uint256)](contracts/SyntheX.sol#L596-L604) has external calls inside a loop: [synRemaining = syn.balanceOf(address(this))](contracts/SyntheX.sol#L598)

contracts/SyntheX.sol#L596-L604

-   [ ] ID-72
        [PriceOracle.getAssetPrice(address)](contracts/PriceOracle.sol#L45-L57) has external calls inside a loop: [price = \_feed.latestAnswer()](contracts/PriceOracle.sol#L47)

contracts/PriceOracle.sol#L45-L57

-   [ ] ID-73
        [SyntheX.getUserPoolDebtUSD(address,address)](contracts/SyntheX.sol#L780-L791) has external calls inside a loop: [IERC20(\_tradingPool).balanceOf(\_account).mul(poolDebt).div(totalDebtShare)](contracts/SyntheX.sol#L790)

contracts/SyntheX.sol#L780-L791

-   [ ] ID-74
        [Multicall2.aggregate(Multicall2.Call[])](contracts/utils/Multicall2.sol#L20-L28) has external calls inside a loop: [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L24)

contracts/utils/Multicall2.sol#L20-L28

-   [ ] ID-75
        [SyntheXPool.getTotalDebtUSD()](contracts/SyntheXPool.sol#L137-L152) has external calls inside a loop: [totalDebt = totalDebt.add(ERC20X(synth).totalSupply().mul(price.price).div(10 \*\* price.decimals))](contracts/SyntheXPool.sol#L149)

contracts/SyntheXPool.sol#L137-L152

## variable-scope

Impact: Low
Confidence: High

-   [ ] ID-76
        Variable '[ERC20Votes.\_moveVotingPower(address,address,uint256).oldWeight](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228)' in [ERC20Votes.\_moveVotingPower(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L221-L237) potentially used before declaration: [(oldWeight,newWeight) = \_writeCheckpoint(\_checkpoints[dst],\_add,amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228

-   [ ] ID-77
        Variable '[ERC1967UpgradeUpgradeable.\_upgradeToAndCallUUPS(address,bytes,bool).slot](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98)' in [ERC1967UpgradeUpgradeable.\_upgradeToAndCallUUPS(address,bytes,bool)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L87-L105) potentially used before declaration: [require(bool,string)(slot == \_IMPLEMENTATION_SLOT,ERC1967Upgrade: unsupported proxiableUUID)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L99)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L98

-   [ ] ID-78
        Variable '[ERC20Votes.\_moveVotingPower(address,address,uint256).newWeight](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228)' in [ERC20Votes.\_moveVotingPower(address,address,uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L221-L237) potentially used before declaration: [(oldWeight,newWeight) = \_writeCheckpoint(\_checkpoints[dst],\_add,amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L233)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L228

## reentrancy-benign

Impact: Low
Confidence: Medium

-   [ ] ID-79
        Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
        External calls: - [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == \_RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
        State variables written after the call(s): - [\_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L100) - [\_allowances[owner][spender] = amount](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L324)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108

-   [ ] ID-80
        Reentrancy in [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142):
        External calls: - [SYN.transfer(msg.sender,transferAmount)](contracts/token/TokenUnlocker.sol#L135)
        State variables written after the call(s): - [reservedForUnlock = reservedForUnlock.sub(transferAmount)](contracts/token/TokenUnlocker.sol#L139)

contracts/token/TokenUnlocker.sol#L126-L142

-   [ ] ID-81
        Reentrancy in [SyntheX.deposit(address,uint256)](contracts/SyntheX.sol#L122-L153):
        External calls: - [ERC20Upgradeable(\_collateral).safeTransferFrom(msg.sender,address(this),\_amount)](contracts/SyntheX.sol#L142)
        State variables written after the call(s): - [accountCollateralBalance[msg.sender][\_collateral] = accountCollateralBalance[msg.sender][\_collateral].add(\_amount)](contracts/SyntheX.sol#L145)

contracts/SyntheX.sol#L122-L153

## reentrancy-events

Impact: Low
Confidence: Medium

-   [ ] ID-82
        Reentrancy in [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124):
        External calls: - [SEALED_SYN.transferFrom(msg.sender,address(this),\_amount)](contracts/token/TokenUnlocker.sol#L112)
        Event emitted after the call(s): - [UnlockRequested(msg.sender,requestId,\_amount)](contracts/token/TokenUnlocker.sol#L123)

contracts/token/TokenUnlocker.sol#L105-L124

-   [ ] ID-83
        Reentrancy in [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153):
        External calls: - [IERC20Upgradeable(rewardsToken).safeTransferFrom(msg.sender,address(this),reward)](contracts/token/StakingRewards.sol#L133)
        Event emitted after the call(s): - [RewardAdded(reward)](contracts/token/StakingRewards.sol#L152)

contracts/token/StakingRewards.sol#L132-L153

-   [ ] ID-84
        Reentrancy in [ERC20FlashMint.flashLoan(IERC3156FlashBorrower,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108):
        External calls: - [require(bool,string)(receiver.onFlashLoan(msg.sender,token,amount,fee,data) == \_RETURN_VALUE,ERC20FlashMint: invalid return value)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L95-L98)
        Event emitted after the call(s): - [Approval(owner,spender,amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L325) - [\_spendAllowance(address(receiver),address(this),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L100) - [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L298) - [\_burn(address(receiver),amount + fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L102) - [Transfer(account,address(0),amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L298) - [\_burn(address(receiver),amount)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L104) - [Transfer(from,to,amount)](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L245) - [\_transfer(address(receiver),flashFeeReceiver,fee)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L105)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L86-L108

-   [ ] ID-85
        Reentrancy in [StakingRewards.recoverERC20(address,uint256)](contracts/token/StakingRewards.sol#L156-L160):
        External calls: - [IERC20Upgradeable(tokenAddress).safeTransfer(owner(),tokenAmount)](contracts/token/StakingRewards.sol#L158)
        Event emitted after the call(s): - [Recovered(tokenAddress,tokenAmount)](contracts/token/StakingRewards.sol#L159)

contracts/token/StakingRewards.sol#L156-L160

-   [ ] ID-86
        Reentrancy in [StakingRewards.exit()](contracts/token/StakingRewards.sol#L124-L127):
        External calls: - [withdraw(\_balances[msg.sender])](contracts/token/StakingRewards.sol#L125) - [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L110) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135) - [IERC20Upgradeable(stakingToken).safeTransfer(msg.sender,amount)](contracts/token/StakingRewards.sol#L107) - [getReward()](contracts/token/StakingRewards.sol#L126) - [returndata = address(token).functionCall(data,SafeERC20: low-level call failed)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L110) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135) - [IERC20Upgradeable(rewardsToken).safeTransfer(msg.sender,reward)](contracts/token/StakingRewards.sol#L118)
        External calls sending eth: - [withdraw(\_balances[msg.sender])](contracts/token/StakingRewards.sol#L125) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135) - [getReward()](contracts/token/StakingRewards.sol#L126) - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)
        Event emitted after the call(s): - [RewardPaid(msg.sender,reward)](contracts/token/StakingRewards.sol#L119) - [getReward()](contracts/token/StakingRewards.sol#L126)

contracts/token/StakingRewards.sol#L124-L127

-   [ ] ID-87
        Reentrancy in [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142):
        External calls: - [SYN.transfer(msg.sender,transferAmount)](contracts/token/TokenUnlocker.sol#L135)
        Event emitted after the call(s): - [Unlocked(msg.sender,\_requestId,transferAmount)](contracts/token/TokenUnlocker.sol#L141)

contracts/token/TokenUnlocker.sol#L126-L142

## timestamp

Impact: Low
Confidence: Medium

-   [ ] ID-88
        [StakingRewards.addReward(uint256)](contracts/token/StakingRewards.sol#L132-L153) uses timestamp for comparisons
        Dangerous comparisons: - [block.timestamp >= periodFinish](contracts/token/StakingRewards.sol#L134) - [require(bool,string)(rewardRate <= balance.div(rewardsDuration),Provided reward too high)](contracts/token/StakingRewards.sol#L148)

contracts/token/StakingRewards.sol#L132-L153

-   [ ] ID-89
        [ERC20Permit.permit(address,address,uint256,uint256,uint8,bytes32,bytes32)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L49-L68) uses timestamp for comparisons
        Dangerous comparisons: - [require(bool,string)(block.timestamp <= deadline,ERC20Permit: expired deadline)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L58)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L49-L68

-   [ ] ID-90
        [ERC20Votes.delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L146-L163) uses timestamp for comparisons
        Dangerous comparisons: - [require(bool,string)(block.timestamp <= expiry,ERC20Votes: signature expired)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L154)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L146-L163

-   [ ] ID-91
        [TokenUnlocker.unlock(bytes32)](contracts/token/TokenUnlocker.sol#L126-L142) uses timestamp for comparisons
        Dangerous comparisons: - [require(bool,string)(block.timestamp >= unlockRequest.requestTime.add(lockPeriod),Unlock period has not passed)](contracts/token/TokenUnlocker.sol#L129)

contracts/token/TokenUnlocker.sol#L126-L142

-   [ ] ID-92
        [StakingRewards.getReward()](contracts/token/StakingRewards.sol#L113-L121) uses timestamp for comparisons
        Dangerous comparisons: - [reward > 0](contracts/token/StakingRewards.sol#L116)

contracts/token/StakingRewards.sol#L113-L121

-   [ ] ID-93
        [TokenUnlocker.requestUnlock(uint256)](contracts/token/TokenUnlocker.sol#L105-L124) uses timestamp for comparisons
        Dangerous comparisons: - [require(bool,string)(unlockRequests[requestId].amount == 0,Unlock request already exists)](contracts/token/TokenUnlocker.sol#L110)

contracts/token/TokenUnlocker.sol#L105-L124

-   [ ] ID-94
        [SyntheX.updatePoolRewardIndex(address,address)](contracts/SyntheX.sol#L497-L511) uses timestamp for comparisons
        Dangerous comparisons: - [deltaTimestamp == 0](contracts/SyntheX.sol#L501)

contracts/SyntheX.sol#L497-L511

-   [ ] ID-95
        [StakingRewards.setRewardsDuration(uint256)](contracts/token/StakingRewards.sol#L163-L170) uses timestamp for comparisons
        Dangerous comparisons: - [require(bool,string)(block.timestamp > periodFinish,Previous rewards period must be complete before changing the duration for the new period)](contracts/token/StakingRewards.sol#L164-L167)

contracts/token/StakingRewards.sol#L163-L170

-   [ ] ID-96
        [StakingRewards.lastTimeRewardApplicable()](contracts/token/StakingRewards.sol#L64-L66) uses timestamp for comparisons
        Dangerous comparisons: - [block.timestamp < periodFinish](contracts/token/StakingRewards.sol#L65)

contracts/token/StakingRewards.sol#L64-L66

## assembly

Impact: Informational
Confidence: High

-   [ ] ID-97
        [AddressUpgradeable.\_revert(bytes,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L206-L218) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L211-L214)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L206-L218

-   [ ] ID-98
        [StorageSlotUpgradeable.getAddressSlot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L52-L57) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L54-L56)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L52-L57

-   [ ] ID-99
        [ECDSA.tryRecover(bytes32,bytes)](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L55-L72) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L63-L67)

node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L55-L72

-   [ ] ID-100
        [StorageSlotUpgradeable.getBytes32Slot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L72-L77) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L74-L76)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L72-L77

-   [ ] ID-101
        [console.\_sendLogPayload(bytes)](node_modules/hardhat/console.sol#L7-L14) uses assembly - [INLINE ASM](node_modules/hardhat/console.sol#L10-L13)

node_modules/hardhat/console.sol#L7-L14

-   [ ] ID-102
        [Math.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L66-L70) - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L86-L93) - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L100-L109)

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L55-L135

-   [ ] ID-103
        [StorageSlotUpgradeable.getBooleanSlot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L62-L67) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L64-L66)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L62-L67

-   [ ] ID-104
        [Strings.toString(uint256)](node_modules/@openzeppelin/contracts/utils/Strings.sol#L18-L38) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Strings.sol#L24-L26) - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Strings.sol#L30-L32)

node_modules/@openzeppelin/contracts/utils/Strings.sol#L18-L38

-   [ ] ID-105
        [ERC20Votes.\_unsafeAccess(ERC20Votes.Checkpoint[],uint256)](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L266-L271) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L267-L270)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L266-L271

-   [ ] ID-106
        [StringsUpgradeable.toString(uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L18-L38) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L24-L26) - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L30-L32)

node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L18-L38

-   [ ] ID-107
        [Address.\_revert(bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L231-L243) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts/utils/Address.sol#L236-L239)

node_modules/@openzeppelin/contracts/utils/Address.sol#L231-L243

-   [ ] ID-108
        [StorageSlotUpgradeable.getUint256Slot(bytes32)](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L82-L87) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L84-L86)

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L82-L87

-   [ ] ID-109
        [MathUpgradeable.mulDiv(uint256,uint256,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135) uses assembly - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L66-L70) - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L86-L93) - [INLINE ASM](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L100-L109)

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L55-L135

## pragma

Impact: Informational
Confidence: High

-   [ ] ID-110
        Different versions of Solidity are used: - Version used: ['>=0.4.22<0.9.0', '>=0.5.0', '^0.8.0', '^0.8.1', '^0.8.16', '^0.8.2', '^0.8.9'] - [>=0.4.22<0.9.0](node_modules/hardhat/console.sol#L2) - [>=0.5.0](contracts/utils/Multicall2.sol#L2) - [ABIEncoderV2](contracts/utils/Multicall2.sol#L3) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3) - [^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/security/Pausable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4) - [^0.8.1](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4) - [^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4) - [^0.8.16](contracts/interfaces/IChainlinkAggregator.sol#L2) - [^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4) - [^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4) - [^0.8.9](contracts/ERC20X.sol#L2) - [^0.8.9](contracts/PriceOracle.sol#L2) - [^0.8.9](contracts/SyntheX.sol#L2) - [^0.8.9](contracts/SyntheXPool.sol#L2) - [^0.8.9](contracts/SyntheXStorage.sol#L2) - [^0.8.9](contracts/interfaces/IPriceOracle.sol#L2) - [^0.8.9](contracts/interfaces/IStaking.sol#L2) - [^0.8.9](contracts/interfaces/ISyntheX.sol#L2) - [^0.8.9](contracts/interfaces/ISyntheXPool.sol#L2) - [^0.8.9](contracts/mock/MockPriceFeed.sol#L2) - [^0.8.9](contracts/mock/MockToken.sol#L2) - [^0.8.9](contracts/token/Crowdsale.sol#L2) - [^0.8.9](contracts/token/SealedSYN.sol#L2) - [^0.8.9](contracts/token/StakingRewards.sol#L2) - [^0.8.9](contracts/token/SyntheXToken.sol#L2) - [^0.8.9](contracts/token/TokenUnlocker.sol#L2) - [^0.8.9](contracts/utils/AddressStorage.sol#L2) - [^0.8.9](contracts/utils/FeeVault.sol#L2)

node_modules/hardhat/console.sol#L2

## costly-loop

Impact: Informational
Confidence: Medium

-   [ ] ID-111
        [SyntheXPool.removeSynth(address)](contracts/SyntheXPool.sol#L103-L113) has costly operations inside a loop: - [\_synthsList.pop()](contracts/SyntheXPool.sol#L108)

contracts/SyntheXPool.sol#L103-L113

-   [ ] ID-112
        [ReentrancyGuardUpgradeable.\_nonReentrantAfter()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73) has costly operations inside a loop: - [\_status = \_NOT_ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L72)

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L69-L73

-   [ ] ID-113
        [ReentrancyGuardUpgradeable.\_nonReentrantBefore()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67) has costly operations inside a loop: - [\_status = \_ENTERED](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L66)

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L61-L67

## solc-version

Impact: Informational
Confidence: High

-   [ ] ID-114
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L4

-   [ ] ID-115
        Pragma version[^0.8.9](contracts/PriceOracle.sol#L2) allows old versions

contracts/PriceOracle.sol#L2

-   [ ] ID-116
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol#L4

-   [ ] ID-117
        Pragma version[^0.8.9](contracts/mock/MockPriceFeed.sol#L2) allows old versions

contracts/mock/MockPriceFeed.sol#L2

-   [ ] ID-118
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L4

-   [ ] ID-119
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol#L4

-   [ ] ID-120
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L4

-   [ ] ID-121
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4

-   [ ] ID-122
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol#L4

-   [ ] ID-123
        Pragma version[^0.8.9](contracts/interfaces/IStaking.sol#L2) allows old versions

contracts/interfaces/IStaking.sol#L2

-   [ ] ID-124
        Pragma version[^0.8.9](contracts/token/TokenUnlocker.sol#L2) allows old versions

contracts/token/TokenUnlocker.sol#L2

-   [ ] ID-125
        Pragma version[^0.8.9](contracts/utils/AddressStorage.sol#L2) allows old versions

contracts/utils/AddressStorage.sol#L2

-   [ ] ID-126
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Context.sol#L4

-   [ ] ID-127
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L4

-   [ ] ID-128
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol#L4

-   [ ] ID-129
        Pragma version[^0.8.9](contracts/token/Crowdsale.sol#L2) allows old versions

contracts/token/Crowdsale.sol#L2

-   [ ] ID-130
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Strings.sol#L4

-   [ ] ID-131
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L4

-   [ ] ID-132
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol#L4

-   [ ] ID-133
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L4

-   [ ] ID-134
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol#L4

-   [ ] ID-135
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol#L4

-   [ ] ID-136
        Pragma version[^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Address.sol#L4

-   [ ] ID-137
        Pragma version[^0.8.9](contracts/utils/FeeVault.sol#L2) allows old versions

contracts/utils/FeeVault.sol#L2

-   [ ] ID-138
        Pragma version[^0.8.9](contracts/mock/MockToken.sol#L2) allows old versions

contracts/mock/MockToken.sol#L2

-   [ ] ID-139
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L4

-   [ ] ID-140
        Pragma version[^0.8.9](contracts/SyntheXPool.sol#L2) allows old versions

contracts/SyntheXPool.sol#L2

-   [ ] ID-141
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L4

-   [ ] ID-142
        solc-0.8.17 is not recommended for deployment

-   [ ] ID-143
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol#L4

-   [ ] ID-144
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L4

-   [ ] ID-145
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol#L4

-   [ ] ID-146
        Pragma version[^0.8.9](contracts/token/SyntheXToken.sol#L2) allows old versions

contracts/token/SyntheXToken.sol#L2

-   [ ] ID-147
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol#L4

-   [ ] ID-148
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Counters.sol#L4

-   [ ] ID-149
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4

-   [ ] ID-150
        Pragma version[^0.8.9](contracts/ERC20X.sol#L2) allows old versions

contracts/ERC20X.sol#L2

-   [ ] ID-151
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L4

-   [ ] ID-152
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/IAccessControl.sol#L4

-   [ ] ID-153
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3) allows old versions

node_modules/@openzeppelin/contracts/governance/utils/IVotes.sol#L3

-   [ ] ID-154
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/AccessControl.sol#L4

-   [ ] ID-155
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4

-   [ ] ID-156
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol#L4

-   [ ] ID-157
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol#L4

-   [ ] ID-158
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L4

-   [ ] ID-159
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol#L4

-   [ ] ID-160
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol#L4

-   [ ] ID-161
        Pragma version[^0.8.9](contracts/interfaces/ISyntheXPool.sol#L2) allows old versions

contracts/interfaces/ISyntheXPool.sol#L2

-   [ ] ID-162
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol#L4

-   [ ] ID-163
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/security/Pausable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/security/Pausable.sol#L4

-   [ ] ID-164
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol#L4

-   [ ] ID-165
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol#L4

-   [ ] ID-166
        Pragma version[^0.8.9](contracts/SyntheX.sol#L2) allows old versions

contracts/SyntheX.sol#L2

-   [ ] ID-167
        Pragma version[^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L4

-   [ ] ID-168
        Pragma version[^0.8.9](contracts/SyntheXStorage.sol#L2) allows old versions

contracts/SyntheXStorage.sol#L2

-   [ ] ID-169
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol#L4

-   [ ] ID-170
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5) allows old versions

node_modules/@openzeppelin/contracts/utils/math/SafeCast.sol#L5

-   [ ] ID-171
        Pragma version[^0.8.9](contracts/token/SealedSYN.sol#L2) allows old versions

contracts/token/SealedSYN.sol#L2

-   [ ] ID-172
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L4

-   [ ] ID-173
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/Ownable.sol#L4

-   [ ] ID-174
        Pragma version[^0.8.2](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol#L4

-   [ ] ID-175
        Pragma version[>=0.5.0](contracts/utils/Multicall2.sol#L2) allows old versions

contracts/utils/Multicall2.sol#L2

-   [ ] ID-176
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4

-   [ ] ID-177
        Pragma version[^0.8.9](contracts/interfaces/IPriceOracle.sol#L2) allows old versions

contracts/interfaces/IPriceOracle.sol#L2

-   [ ] ID-178
        Pragma version[^0.8.1](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L4

-   [ ] ID-179
        Pragma version[^0.8.9](contracts/token/StakingRewards.sol#L2) allows old versions

contracts/token/StakingRewards.sol#L2

-   [ ] ID-180
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L4

-   [ ] ID-181
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol#L4

-   [ ] ID-182
        Pragma version[^0.8.9](contracts/interfaces/ISyntheX.sol#L2) allows old versions

contracts/interfaces/ISyntheX.sol#L2

-   [ ] ID-183
        Pragma version[>=0.4.22<0.9.0](node_modules/hardhat/console.sol#L2) is too complex

node_modules/hardhat/console.sol#L2

-   [ ] ID-184
        Pragma version[^0.8.0](node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol#L4

## low-level-calls

Impact: Informational
Confidence: High

-   [ ] ID-185
        Low level call in [Multicall2.aggregate(Multicall2.Call[])](contracts/utils/Multicall2.sol#L20-L28): - [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L24)

contracts/utils/Multicall2.sol#L20-L28

-   [ ] ID-186
        Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137): - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L135)

node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137

-   [ ] ID-187
        Low level call in [Multicall2.tryAggregate(bool,Multicall2.Call[])](contracts/utils/Multicall2.sol#L56-L67): - [(success,ret) = calls[i].target.call(calls[i].callData)](contracts/utils/Multicall2.sol#L59)

contracts/utils/Multicall2.sol#L56-L67

-   [ ] ID-188
        Low level call in [AddressUpgradeable.sendValue(address,uint256)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L60-L65): - [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L63)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L60-L65

-   [ ] ID-189
        Low level call in [Address.sendValue(address,uint256)](node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65): - [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts/utils/Address.sol#L63)

node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65

-   [ ] ID-190
        Low level call in [AddressUpgradeable.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137): - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L135)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L128-L137

-   [ ] ID-191
        Low level call in [AddressUpgradeable.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L155-L162): - [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L160)

node_modules/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol#L155-L162

-   [ ] ID-192
        Low level call in [ERC1967UpgradeUpgradeable.\_functionDelegateCall(address,bytes)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204): - [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L202)

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L198-L204

-   [ ] ID-193
        Low level call in [Address.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162): - [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L160)

node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162

-   [ ] ID-194
        Low level call in [Address.functionDelegateCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187): - [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L185)

node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187

## naming-convention

Impact: Informational
Confidence: High

-   [ ] ID-195
        Parameter [SyntheX.getUserTotalDebtUSD(address).\_account](contracts/SyntheX.sol#L739) is not in mixedCase

contracts/SyntheX.sol#L739

-   [ ] ID-196
        Parameter [TokenUnlocker.requestUnlock(uint256).\_amount](contracts/token/TokenUnlocker.sol#L105) is not in mixedCase

contracts/token/TokenUnlocker.sol#L105

-   [ ] ID-197
        Parameter [SyntheXPool.initialize(string,string,address).\_addressStorage](contracts/SyntheXPool.sol#L55) is not in mixedCase

contracts/SyntheXPool.sol#L55

-   [ ] ID-198
        Parameter [SyntheX.enterPool(address).\_tradingPool](contracts/SyntheX.sol#L69) is not in mixedCase

contracts/SyntheX.sol#L69

-   [ ] ID-199
        Parameter [Vault.withdraw(address,uint256).\_tokenAddress](contracts/utils/FeeVault.sol#L15) is not in mixedCase

contracts/utils/FeeVault.sol#L15

-   [ ] ID-200
        Parameter [SyntheXPool.burn(address,uint256).\_user](contracts/SyntheXPool.sol#L233) is not in mixedCase

contracts/SyntheXPool.sol#L233

-   [ ] ID-201
        Function [IERC20PermitUpgradeable.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L59) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol#L59

-   [ ] ID-202
        Parameter [SyntheX.withdraw(address,uint256).\_collateral](contracts/SyntheX.sol#L162) is not in mixedCase

contracts/SyntheX.sol#L162

-   [ ] ID-203
        Parameter [AddressStorage.setAddress(bytes32,address).\_value](contracts/utils/AddressStorage.sol#L34) is not in mixedCase

contracts/utils/AddressStorage.sol#L34

-   [ ] ID-204
        Parameter [SyntheX.burn(address,address,uint256).\_synth](contracts/SyntheX.sol#L236) is not in mixedCase

contracts/SyntheX.sol#L236

-   [ ] ID-205
        Parameter [SyntheX.withdraw(address,uint256).\_amount](contracts/SyntheX.sol#L162) is not in mixedCase

contracts/SyntheX.sol#L162

-   [ ] ID-206
        Parameter [SyntheX.updatePoolRewardIndex(address,address).\_tradingPool](contracts/SyntheX.sol#L497) is not in mixedCase

contracts/SyntheX.sol#L497

-   [ ] ID-207
        Parameter [SyntheXPool.disableSynth(address).\_synth](contracts/SyntheXPool.sol#L91) is not in mixedCase

contracts/SyntheXPool.sol#L91

-   [ ] ID-208
        Parameter [StakingRewards.setRewardsDuration(uint256).\_rewardsDuration](contracts/token/StakingRewards.sol#L163) is not in mixedCase

contracts/token/StakingRewards.sol#L163

-   [ ] ID-209
        Function [AccessControlUpgradeable.\_\_AccessControl_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L54-L55) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L54-L55

-   [ ] ID-210
        Parameter [SyntheX.claimSYN(address[],address[]).\_tradingPools](contracts/SyntheX.sol#L568) is not in mixedCase

contracts/SyntheX.sol#L568

-   [ ] ID-211
        Parameter [SyntheX.liquidate(address,address,address,uint256,address).\_inAmount](contracts/SyntheX.sol#L298) is not in mixedCase

contracts/SyntheX.sol#L298

-   [ ] ID-212
        Function [ERC1967UpgradeUpgradeable.\_\_ERC1967Upgrade_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L24-L25

-   [ ] ID-213
        Parameter [SyntheXPool.enableSynth(address).\_synth](contracts/SyntheXPool.sol#L69) is not in mixedCase

contracts/SyntheXPool.sol#L69

-   [ ] ID-214
        Parameter [SyntheX.enableTradingPool(address,uint256).\_volatilityRatio](contracts/SyntheX.sol#L384) is not in mixedCase

contracts/SyntheX.sol#L384

-   [ ] ID-215
        Parameter [SyntheXPool.exchange(address,address,address,uint256,uint256).\_user](contracts/SyntheXPool.sol#L259) is not in mixedCase

contracts/SyntheXPool.sol#L259

-   [ ] ID-216
        Parameter [StakingRewards.initialize(address,address).\_rewardsToken](contracts/token/StakingRewards.sol#L39) is not in mixedCase

contracts/token/StakingRewards.sol#L39

-   [ ] ID-217
        Parameter [SyntheXPool.exchange(address,address,address,uint256,uint256).\_fromAmount](contracts/SyntheXPool.sol#L259) is not in mixedCase

contracts/SyntheXPool.sol#L259

-   [ ] ID-218
        Parameter [SyntheX.updatePoolRewardIndex(address,address).\_rewardToken](contracts/SyntheX.sol#L497) is not in mixedCase

contracts/SyntheX.sol#L497

-   [ ] ID-219
        Parameter [SyntheXPool.mint(address,uint256).\_amountUSD](contracts/SyntheXPool.sol#L194) is not in mixedCase

contracts/SyntheXPool.sol#L194

-   [ ] ID-220
        Parameter [SyntheXPool.mint(address,uint256).\_user](contracts/SyntheXPool.sol#L194) is not in mixedCase

contracts/SyntheXPool.sol#L194

-   [ ] ID-221
        Variable [ContextUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L36) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L36

-   [ ] ID-222
        Function [ReentrancyGuardUpgradeable.\_\_ReentrancyGuard_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L44-L46

-   [ ] ID-223
        Variable [AccessControlUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259

-   [ ] ID-224
        Parameter [SyntheXPool.exchange(address,address,address,uint256,uint256).\_toAmount](contracts/SyntheXPool.sol#L259) is not in mixedCase

contracts/SyntheXPool.sol#L259

-   [ ] ID-225
        Parameter [AddressStorage.getAddress(bytes32).\_key](contracts/utils/AddressStorage.sol#L30) is not in mixedCase

contracts/utils/AddressStorage.sol#L30

-   [ ] ID-226
        Parameter [SyntheX.distributeAccountReward(address,address,address).\_tradingPool](contracts/SyntheX.sol#L518) is not in mixedCase

contracts/SyntheX.sol#L518

-   [ ] ID-227
        Parameter [SyntheX.setCollateralCap(address,uint256).\_collateral](contracts/SyntheX.sol#L441) is not in mixedCase

contracts/SyntheX.sol#L441

-   [ ] ID-228
        Parameter [SyntheX.setPoolSpeed(address,address,uint256).\_rewardToken](contracts/SyntheX.sol#L469) is not in mixedCase

contracts/SyntheX.sol#L469

-   [ ] ID-229
        Parameter [SyntheX.initialize(address,address).\_addressStorage](contracts/SyntheX.sol#L45) is not in mixedCase

contracts/SyntheX.sol#L45

-   [ ] ID-230
        Parameter [SyntheXPool.burn(address,uint256).\_amountUSD](contracts/SyntheXPool.sol#L233) is not in mixedCase

contracts/SyntheXPool.sol#L233

-   [ ] ID-231
        Parameter [SyntheX.updateReward(address,address).\_account](contracts/SyntheX.sol#L486) is not in mixedCase

contracts/SyntheX.sol#L486

-   [ ] ID-232
        Parameter [AddressStorage.setAddress(bytes32,address).\_key](contracts/utils/AddressStorage.sol#L34) is not in mixedCase

contracts/utils/AddressStorage.sol#L34

-   [ ] ID-233
        Function [OwnableUpgradeable.\_\_Ownable_init()](node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L29-L31) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L29-L31

-   [ ] ID-234
        Contract [console](node_modules/hardhat/console.sol#L4-L1532) is not in CapWords

node_modules/hardhat/console.sol#L4-L1532

-   [ ] ID-235
        Parameter [SyntheX.getUserPoolDebtUSD(address,address).\_tradingPool](contracts/SyntheX.sol#L780) is not in mixedCase

contracts/SyntheX.sol#L780

-   [ ] ID-236
        Parameter [SyntheX.getUserPoolDebtUSD(address,address).\_account](contracts/SyntheX.sol#L780) is not in mixedCase

contracts/SyntheX.sol#L780

-   [ ] ID-237
        Parameter [SyntheXPool.mintSynth(address,address,uint256).\_user](contracts/SyntheXPool.sol#L219) is not in mixedCase

contracts/SyntheXPool.sol#L219

-   [ ] ID-238
        Variable [OwnableUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L94) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L94

-   [ ] ID-239
        Variable [UUPSUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L107) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L107

-   [ ] ID-240
        Parameter [SyntheXPool.burnSynth(address,address,uint256).\_synth](contracts/SyntheXPool.sol#L246) is not in mixedCase

contracts/SyntheXPool.sol#L246

-   [ ] ID-241
        Parameter [TokenUnlocker.unlock(bytes32).\_requestId](contracts/token/TokenUnlocker.sol#L126) is not in mixedCase

contracts/token/TokenUnlocker.sol#L126

-   [ ] ID-242
        Variable [EIP712.\_TYPE_HASH](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L37) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L37

-   [ ] ID-243
        Parameter [SyntheX.disableCollateral(address).\_collateral](contracts/SyntheX.sol#L431) is not in mixedCase

contracts/SyntheX.sol#L431

-   [ ] ID-244
        Variable [PausableUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L116) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L116

-   [ ] ID-245
        Parameter [SyntheX.disableTradingPool(address).\_tradingPool](contracts/SyntheX.sol#L402) is not in mixedCase

contracts/SyntheX.sol#L402

-   [ ] ID-246
        Function [ERC20Upgradeable.\_\_ERC20_init_unchained(string,string)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L59-L62) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L59-L62

-   [ ] ID-247
        Parameter [SyntheX.liquidate(address,address,address,uint256,address).\_outAsset](contracts/SyntheX.sol#L298) is not in mixedCase

contracts/SyntheX.sol#L298

-   [ ] ID-248
        Variable [ERC1967UpgradeUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L211) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L211

-   [ ] ID-249
        Parameter [ERC20X.updateFlashFee(uint256).\_flashLoanFee](contracts/ERC20X.sol#L25) is not in mixedCase

contracts/ERC20X.sol#L25

-   [ ] ID-250
        Variable [TokenUnlocker.SEALED_SYN](contracts/token/TokenUnlocker.sol#L21) is not in mixedCase

contracts/token/TokenUnlocker.sol#L21

-   [ ] ID-251
        Function [ERC20Upgradeable.\_\_ERC20_init(string,string)](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L55-L57) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L55-L57

-   [ ] ID-252
        Function [ReentrancyGuardUpgradeable.\_\_ReentrancyGuard_init()](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L40-L42) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L40-L42

-   [ ] ID-253
        Parameter [SyntheX.exchange(address,address,address,uint256).\_synthFrom](contracts/SyntheX.sol#L268) is not in mixedCase

contracts/SyntheX.sol#L268

-   [ ] ID-254
        Function [ERC165Upgradeable.\_\_ERC165_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L27-L28) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L27-L28

-   [ ] ID-255
        Function [ContextUpgradeable.\_\_Context_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L21-L22

-   [ ] ID-256
        Parameter [SyntheX.exitPool(address).\_tradingPool](contracts/SyntheX.sol#L78) is not in mixedCase

contracts/SyntheX.sol#L78

-   [ ] ID-257
        Parameter [StakingRewards.initialize(address,address).\_stakingToken](contracts/token/StakingRewards.sol#L39) is not in mixedCase

contracts/token/StakingRewards.sol#L39

-   [ ] ID-258
        Variable [EIP712.\_CACHED_THIS](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L33) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L33

-   [ ] ID-259
        Parameter [SyntheX.exchange(address,address,address,uint256).\_synthTo](contracts/SyntheX.sol#L268) is not in mixedCase

contracts/SyntheX.sol#L268

-   [ ] ID-260
        Function [UUPSUpgradeable.\_\_UUPSUpgradeable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L26-L27) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L26-L27

-   [ ] ID-261
        Parameter [MockPriceFeed.setPrice(int256,uint8).\_\_decimals](contracts/mock/MockPriceFeed.sol#L14) is not in mixedCase

contracts/mock/MockPriceFeed.sol#L14

-   [ ] ID-262
        Variable [ERC20Upgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L400) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol#L400

-   [ ] ID-263
        Parameter [PriceOracle.setFeed(address,address).\_feed](contracts/PriceOracle.sol#L20) is not in mixedCase

contracts/PriceOracle.sol#L20

-   [ ] ID-264
        Variable [ReentrancyGuardUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L80) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol#L80

-   [ ] ID-265
        Variable [ERC20Permit.\_PERMIT_TYPEHASH_DEPRECATED_SLOT](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L37) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L37

-   [ ] ID-266
        Parameter [SyntheX.initialize(address,address).\_syn](contracts/SyntheX.sol#L45) is not in mixedCase

contracts/SyntheX.sol#L45

-   [ ] ID-267
        Parameter [TokenUnlocker.setLockPeriod(uint256).\_lockPeriod](contracts/token/TokenUnlocker.sol#L70) is not in mixedCase

contracts/token/TokenUnlocker.sol#L70

-   [ ] ID-268
        Function [IERC20Permit.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L59) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol#L59

-   [ ] ID-269
        Parameter [SyntheX.setPoolSpeed(address,address,uint256).\_speed](contracts/SyntheX.sol#L469) is not in mixedCase

contracts/SyntheX.sol#L469

-   [ ] ID-270
        Parameter [SyntheX.issue(address,address,uint256).\_synth](contracts/SyntheX.sol#L196) is not in mixedCase

contracts/SyntheX.sol#L196

-   [ ] ID-271
        Variable [StakingRewards.\_totalSupply](contracts/token/StakingRewards.sol#L33) is not in mixedCase

contracts/token/StakingRewards.sol#L33

-   [ ] ID-272
        Parameter [SyntheX.getAdjustedUserTotalDebtUSD(address).\_account](contracts/SyntheX.sol#L757) is not in mixedCase

contracts/SyntheX.sol#L757

-   [ ] ID-273
        Function [AccessControlUpgradeable.\_\_AccessControl_init()](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L51-L52) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L51-L52

-   [ ] ID-274
        Parameter [SyntheX.addRewardToken(address).\_rewardToken](contracts/SyntheX.sol#L455) is not in mixedCase

contracts/SyntheX.sol#L455

-   [ ] ID-275
        Variable [EIP712.\_CACHED_CHAIN_ID](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L32) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L32

-   [ ] ID-276
        Parameter [SyntheX.burn(address,address,uint256).\_amount](contracts/SyntheX.sol#L236) is not in mixedCase

contracts/SyntheX.sol#L236

-   [ ] ID-277
        Parameter [SyntheX.getAdjustedUserTotalCollateralUSD(address).\_account](contracts/SyntheX.sol#L710) is not in mixedCase

contracts/SyntheX.sol#L710

-   [ ] ID-278
        Parameter [SyntheX.healthFactor(address).\_account](contracts/SyntheX.sol#L652) is not in mixedCase

contracts/SyntheX.sol#L652

-   [ ] ID-279
        Function [ERC20Permit.DOMAIN_SEPARATOR()](node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L81-L83) is not in mixedCase

node_modules/@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol#L81-L83

-   [ ] ID-280
        Parameter [SyntheX.getUserTotalCollateralUSD(address).\_account](contracts/SyntheX.sol#L685) is not in mixedCase

contracts/SyntheX.sol#L685

-   [ ] ID-281
        Parameter [SyntheX.burn(address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L236) is not in mixedCase

contracts/SyntheX.sol#L236

-   [ ] ID-282
        Parameter [SyntheXPool.burnSynth(address,address,uint256).\_amount](contracts/SyntheXPool.sol#L246) is not in mixedCase

contracts/SyntheXPool.sol#L246

-   [ ] ID-283
        Variable [TokenUnlocker.SYN](contracts/token/TokenUnlocker.sol#L22) is not in mixedCase

contracts/token/TokenUnlocker.sol#L22

-   [ ] ID-284
        Parameter [MockPriceFeed.setPrice(int256,uint8).\_price](contracts/mock/MockPriceFeed.sol#L14) is not in mixedCase

contracts/mock/MockPriceFeed.sol#L14

-   [ ] ID-285
        Parameter [SyntheX.setSafeCRatio(uint256).\_safeCRatio](contracts/SyntheX.sol#L448) is not in mixedCase

contracts/SyntheX.sol#L448

-   [ ] ID-286
        Variable [ERC165Upgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L41) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L41

-   [ ] ID-287
        Function [OwnableUpgradeable.\_\_Ownable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L33-L35) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol#L33-L35

-   [ ] ID-288
        Variable [UUPSUpgradeable.\_\_self](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L29) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L29

-   [ ] ID-289
        Parameter [SyntheX.issue(address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L196) is not in mixedCase

contracts/SyntheX.sol#L196

-   [ ] ID-290
        Function [ERC1967UpgradeUpgradeable.\_\_ERC1967Upgrade_init()](node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L21-L22) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol#L21-L22

-   [ ] ID-291
        Parameter [SyntheX.setCollateralCap(address,uint256).\_maxDeposit](contracts/SyntheX.sol#L441) is not in mixedCase

contracts/SyntheX.sol#L441

-   [ ] ID-292
        Parameter [SyntheX.liquidate(address,address,address,uint256,address).\_account](contracts/SyntheX.sol#L298) is not in mixedCase

contracts/SyntheX.sol#L298

-   [ ] ID-293
        Parameter [SyntheXPool.removeSynth(address).\_synth](contracts/SyntheXPool.sol#L103) is not in mixedCase

contracts/SyntheXPool.sol#L103

-   [ ] ID-294
        Parameter [SyntheXPool.mintSynth(address,address,uint256).\_synth](contracts/SyntheXPool.sol#L219) is not in mixedCase

contracts/SyntheXPool.sol#L219

-   [ ] ID-295
        Parameter [SyntheX.enterCollateral(address).\_collateral](contracts/SyntheX.sol#L96) is not in mixedCase

contracts/SyntheX.sol#L96

-   [ ] ID-296
        Function [UUPSUpgradeable.\_\_UUPSUpgradeable_init()](node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L23-L24) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol#L23-L24

-   [ ] ID-297
        Parameter [PriceOracle.getAssetPrices(address[]).\_assets](contracts/PriceOracle.sol#L64) is not in mixedCase

contracts/PriceOracle.sol#L64

-   [ ] ID-298
        Parameter [SyntheX.getLTV(address).\_account](contracts/SyntheX.sol#L669) is not in mixedCase

contracts/SyntheX.sol#L669

-   [ ] ID-299
        Parameter [PriceOracle.getAssetPrice(address).\_asset](contracts/PriceOracle.sol#L45) is not in mixedCase

contracts/PriceOracle.sol#L45

-   [ ] ID-300
        Parameter [SyntheXPool.mintSynth(address,address,uint256).\_amount](contracts/SyntheXPool.sol#L219) is not in mixedCase

contracts/SyntheXPool.sol#L219

-   [ ] ID-301
        Parameter [SyntheXPool.exchange(address,address,address,uint256,uint256).\_toSynth](contracts/SyntheXPool.sol#L259) is not in mixedCase

contracts/SyntheXPool.sol#L259

-   [ ] ID-302
        Parameter [SyntheX.getRewardsAccrued(address,address[]).\_account](contracts/SyntheX.sol#L610) is not in mixedCase

contracts/SyntheX.sol#L610

-   [ ] ID-303
        Parameter [SyntheX.issue(address,address,uint256).\_amount](contracts/SyntheX.sol#L196) is not in mixedCase

contracts/SyntheX.sol#L196

-   [ ] ID-304
        Variable [EIP712.\_HASHED_NAME](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L35) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L35

-   [ ] ID-305
        Variable [SyntheXStorage.\_\_gap](contracts/SyntheXStorage.sol#L86) is not in mixedCase

contracts/SyntheXStorage.sol#L86

-   [ ] ID-306
        Parameter [SyntheX.distributeAccountReward(address,address,address).\_account](contracts/SyntheX.sol#L518) is not in mixedCase

contracts/SyntheX.sol#L518

-   [ ] ID-307
        Parameter [SyntheXPool.burnSynth(address,address,uint256).\_user](contracts/SyntheXPool.sol#L246) is not in mixedCase

contracts/SyntheXPool.sol#L246

-   [ ] ID-308
        Parameter [SyntheX.setPoolSpeed(address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L469) is not in mixedCase

contracts/SyntheX.sol#L469

-   [ ] ID-309
        Parameter [PriceOracle.getFeed(address).\_token](contracts/PriceOracle.sol#L36) is not in mixedCase

contracts/PriceOracle.sol#L36

-   [ ] ID-310
        Function [PausableUpgradeable.\_\_Pausable_init()](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L34-L36) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L34-L36

-   [ ] ID-311
        Parameter [PriceOracle.setFeed(address,address).\_token](contracts/PriceOracle.sol#L20) is not in mixedCase

contracts/PriceOracle.sol#L20

-   [ ] ID-312
        Parameter [SyntheX.enableTradingPool(address,uint256).\_tradingPool](contracts/SyntheX.sol#L384) is not in mixedCase

contracts/SyntheX.sol#L384

-   [ ] ID-313
        Function [ContextUpgradeable.\_\_Context_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L18-L19) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol#L18-L19

-   [ ] ID-314
        Parameter [SyntheX.deposit(address,uint256).\_collateral](contracts/SyntheX.sol#L122) is not in mixedCase

contracts/SyntheX.sol#L122

-   [ ] ID-315
        Parameter [SyntheX.updateReward(address,address).\_tradingPool](contracts/SyntheX.sol#L486) is not in mixedCase

contracts/SyntheX.sol#L486

-   [ ] ID-316
        Parameter [SyntheX.exchange(address,address,address,uint256).\_amount](contracts/SyntheX.sol#L268) is not in mixedCase

contracts/SyntheX.sol#L268

-   [ ] ID-317
        Parameter [SyntheX.enableCollateral(address,uint256).\_volatilityRatio](contracts/SyntheX.sol#L414) is not in mixedCase

contracts/SyntheX.sol#L414

-   [ ] ID-318
        Parameter [SyntheX.deposit(address,uint256).\_amount](contracts/SyntheX.sol#L122) is not in mixedCase

contracts/SyntheX.sol#L122

-   [ ] ID-319
        Function [ERC165Upgradeable.\_\_ERC165_init()](node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L24-L25) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol#L24-L25

-   [ ] ID-320
        Variable [EIP712.\_CACHED_DOMAIN_SEPARATOR](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L31) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L31

-   [ ] ID-321
        Parameter [SyntheX.liquidate(address,address,address,uint256,address).\_tradingPool](contracts/SyntheX.sol#L298) is not in mixedCase

contracts/SyntheX.sol#L298

-   [ ] ID-322
        Parameter [TokenUnlocker.withdraw(uint256).\_amount](contracts/token/TokenUnlocker.sol#L81) is not in mixedCase

contracts/token/TokenUnlocker.sol#L81

-   [ ] ID-323
        Parameter [SyntheX.liquidate(address,address,address,uint256,address).\_inAsset](contracts/SyntheX.sol#L298) is not in mixedCase

contracts/SyntheX.sol#L298

-   [ ] ID-324
        Variable [EIP712.\_HASHED_VERSION](node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L36) is not in mixedCase

node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol#L36

-   [ ] ID-325
        Parameter [SyntheXPool.updateFee(uint256).\_fee](contracts/SyntheXPool.sol#L81) is not in mixedCase

contracts/SyntheXPool.sol#L81

-   [ ] ID-326
        Parameter [SyntheX.enableCollateral(address,uint256).\_collateral](contracts/SyntheX.sol#L414) is not in mixedCase

contracts/SyntheX.sol#L414

-   [ ] ID-327
        Parameter [SyntheX.exitCollateral(address).\_collateral](contracts/SyntheX.sol#L105) is not in mixedCase

contracts/SyntheX.sol#L105

-   [ ] ID-328
        Parameter [SyntheX.exchange(address,address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L268) is not in mixedCase

contracts/SyntheX.sol#L268

-   [ ] ID-329
        Parameter [SyntheXPool.exchange(address,address,address,uint256,uint256).\_fromSynth](contracts/SyntheXPool.sol#L259) is not in mixedCase

contracts/SyntheXPool.sol#L259

-   [ ] ID-330
        Function [PausableUpgradeable.\_\_Pausable_init_unchained()](node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L38-L40) is not in mixedCase

node_modules/@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol#L38-L40

-   [ ] ID-331
        Parameter [SyntheX.distributeAccountReward(address,address,address).\_rewardToken](contracts/SyntheX.sol#L518) is not in mixedCase

contracts/SyntheX.sol#L518

## redundant-statements

Impact: Informational
Confidence: High

-   [ ] ID-332
        Redundant expression "[amount](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L55)" in[ERC20FlashMint](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L19-L109)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L55

-   [ ] ID-333
        Redundant expression "[token](contracts/ERC20X.sol#L32)" in[ERC20X](contracts/ERC20X.sol#L9-L57)

contracts/ERC20X.sol#L32

-   [ ] ID-334
        Redundant expression "[token](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L54)" in[ERC20FlashMint](node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L19-L109)

node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol#L54

## reentrancy-unlimited-gas

Impact: Informational
Confidence: Medium

-   [ ] ID-335
        Reentrancy in [SyntheX.withdraw(address,uint256)](contracts/SyntheX.sol#L162-L188):
        External calls: - [address(msg.sender).transfer(\_amount)](contracts/SyntheX.sol#L174)
        State variables written after the call(s): - [supply.totalDeposits = supply.totalDeposits.sub(\_amount)](contracts/SyntheX.sol#L184)
        Event emitted after the call(s): - [Withdraw(msg.sender,\_collateral,\_amount)](contracts/SyntheX.sol#L187)

contracts/SyntheX.sol#L162-L188

## similar-names

Impact: Informational
Confidence: Medium

-   [ ] ID-336
        Variable [SyntheX.enableTradingPool(address,uint256).\_tradingPool](contracts/SyntheX.sol#L384) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L384

-   [ ] ID-337
        Variable [ISyntheX.enterPool(address).\_tradingPool](contracts/interfaces/ISyntheX.sol#L10) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L10

-   [ ] ID-338
        Variable [SyntheX.addRewardToken(address).\_rewardToken](contracts/SyntheX.sol#L455) is too similar to [SyntheXStorage.rewardTokens](contracts/SyntheXStorage.sol#L72)

contracts/SyntheX.sol#L455

-   [ ] ID-339
        Variable [SyntheX.exitCollateral(address).\_collateral](contracts/SyntheX.sol#L105) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L105

-   [ ] ID-340
        Variable [ISyntheX.deposit(address,uint256).\_collateral](contracts/interfaces/ISyntheX.sol#L14) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L14

-   [ ] ID-341
        Variable [ISyntheX.burn(address,address,uint256).\_tradingPool](contracts/interfaces/ISyntheX.sol#L17) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L17

-   [ ] ID-342
        Variable [SyntheX.setPoolSpeed(address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L469) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L469

-   [ ] ID-343
        Variable [SyntheX.setCollateralCap(address,uint256).\_collateral](contracts/SyntheX.sol#L441) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L441

-   [ ] ID-344
        Variable [SyntheX.disableCollateral(address).\_collateral](contracts/SyntheX.sol#L431) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L431

-   [ ] ID-345
        Variable [SyntheX.getUserPoolDebtUSD(address,address).\_tradingPool](contracts/SyntheX.sol#L780) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L780

-   [ ] ID-346
        Variable [ISyntheX.withdraw(address,uint256).\_collateral](contracts/interfaces/ISyntheX.sol#L15) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L15

-   [ ] ID-347
        Variable [SyntheX.distributeAccountReward(address,address,address).\_rewardToken](contracts/SyntheX.sol#L518) is too similar to [SyntheXStorage.rewardTokens](contracts/SyntheXStorage.sol#L72)

contracts/SyntheX.sol#L518

-   [ ] ID-348
        Variable [ISyntheX.setPoolSpeed(address,address,uint256).\_tradingPool](contracts/interfaces/ISyntheX.sol#L19) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L19

-   [ ] ID-349
        Variable [SyntheX.enableCollateral(address,uint256).\_collateral](contracts/SyntheX.sol#L414) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L414

-   [ ] ID-350
        Variable [SyntheX.enterCollateral(address).\_collateral](contracts/SyntheX.sol#L96) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L96

-   [ ] ID-351
        Variable [ISyntheX.getUserPoolDebtUSD(address,address).\_tradingPool](contracts/interfaces/ISyntheX.sol#L51) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L51

-   [ ] ID-352
        Variable [ISyntheX.exitPool(address).\_tradingPool](contracts/interfaces/ISyntheX.sol#L11) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L11

-   [ ] ID-353
        Variable [ISyntheX.exitCollateral(address).\_collateral](contracts/interfaces/ISyntheX.sol#L13) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L13

-   [ ] ID-354
        Variable [SyntheX.exchange(address,address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L268) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L268

-   [ ] ID-355
        Variable [SyntheX.exitPool(address).\_tradingPool](contracts/SyntheX.sol#L78) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L78

-   [ ] ID-356
        Variable [ISyntheX.enterCollateral(address).\_collateral](contracts/interfaces/ISyntheX.sol#L12) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L12

-   [ ] ID-357
        Variable [ISyntheX.issue(address,address,uint256).\_tradingPool](contracts/interfaces/ISyntheX.sol#L16) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L16

-   [ ] ID-358
        Variable [ISyntheX.exchange(address,address,address,uint256).\_tradingPool](contracts/interfaces/ISyntheX.sol#L18) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L18

-   [ ] ID-359
        Variable [ISyntheX.setCollateralCap(address,uint256).\_collateral](contracts/interfaces/ISyntheX.sol#L30) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L30

-   [ ] ID-360
        Variable [SyntheX.updatePoolRewardIndex(address,address).\_rewardToken](contracts/SyntheX.sol#L497) is too similar to [SyntheXStorage.rewardTokens](contracts/SyntheXStorage.sol#L72)

contracts/SyntheX.sol#L497

-   [ ] ID-361
        Variable [SyntheX.distributeAccountReward(address,address,address).\_tradingPool](contracts/SyntheX.sol#L518) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L518

-   [ ] ID-362
        Variable [SyntheX.updatePoolRewardIndex(address,address).\_tradingPool](contracts/SyntheX.sol#L497) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L497

-   [ ] ID-363
        Variable [SyntheX.issue(address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L196) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L196

-   [ ] ID-364
        Variable [SyntheX.setPoolSpeed(address,address,uint256).\_rewardToken](contracts/SyntheX.sol#L469) is too similar to [SyntheXStorage.rewardTokens](contracts/SyntheXStorage.sol#L72)

contracts/SyntheX.sol#L469

-   [ ] ID-365
        Variable [ISyntheX.enableCollateral(address,uint256).\_collateral](contracts/interfaces/ISyntheX.sol#L27) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L27

-   [ ] ID-366
        Variable [SyntheX.updateReward(address,address).\_tradingPool](contracts/SyntheX.sol#L486) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L486

-   [ ] ID-367
        Variable [SyntheX.enterPool(address).\_tradingPool](contracts/SyntheX.sol#L69) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L69

-   [ ] ID-368
        Variable [ISyntheX.setPoolSpeed(address,address,uint256).\_rewardToken](contracts/interfaces/ISyntheX.sol#L19) is too similar to [SyntheXStorage.rewardTokens](contracts/SyntheXStorage.sol#L72)

contracts/interfaces/ISyntheX.sol#L19

-   [ ] ID-369
        Variable [ISyntheX.liquidate(address,address,address,uint256,address).\_tradingPool](contracts/interfaces/ISyntheX.sol#L20) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L20

-   [ ] ID-370
        Variable [ISyntheX.disableCollateral(address).\_collateral](contracts/interfaces/ISyntheX.sol#L28) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/interfaces/ISyntheX.sol#L28

-   [ ] ID-371
        Variable [SyntheX.disableTradingPool(address).\_tradingPool](contracts/SyntheX.sol#L402) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L402

-   [ ] ID-372
        Variable [ISyntheX.disableTradingPool(address).\_tradingPool](contracts/interfaces/ISyntheX.sol#L26) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L26

-   [ ] ID-373
        Variable [SyntheX.deposit(address,uint256).\_collateral](contracts/SyntheX.sol#L122) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L122

-   [ ] ID-374
        Variable [SyntheX.liquidate(address,address,address,uint256,address).\_tradingPool](contracts/SyntheX.sol#L298) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L298

-   [ ] ID-375
        Variable [ISyntheX.enableTradingPool(address,uint256).\_tradingPool](contracts/interfaces/ISyntheX.sol#L25) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/interfaces/ISyntheX.sol#L25

-   [ ] ID-376
        Variable [SyntheX.burn(address,address,uint256).\_tradingPool](contracts/SyntheX.sol#L236) is too similar to [SyntheXStorage.tradingPools](contracts/SyntheXStorage.sol#L51)

contracts/SyntheX.sol#L236

-   [ ] ID-377
        Variable [SyntheX.withdraw(address,uint256).\_collateral](contracts/SyntheX.sol#L162) is too similar to [SyntheXStorage.collaterals](contracts/SyntheXStorage.sol#L56)

contracts/SyntheX.sol#L162

## unused-state

Impact: Informational
Confidence: High

-   [ ] ID-378
        [AccessControlUpgradeable.\_\_gap](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259) is never used in [AccessControlUpgradeable](node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L50-L260)

node_modules/@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol#L259

## constable-states

Impact: Optimization
Confidence: High

-   [ ] ID-379
        [TokenUnlocker.unlockPeriod](contracts/token/TokenUnlocker.sol#L30) should be constant

contracts/token/TokenUnlocker.sol#L30

## immutable-states

Impact: Optimization
Confidence: High

-   [ ] ID-380
        [ERC20X.pool](contracts/ERC20X.sol#L11) should be immutable

contracts/ERC20X.sol#L11

-   [ ] ID-381
        [TokenUnlocker.SEALED_SYN](contracts/token/TokenUnlocker.sol#L21) should be immutable

contracts/token/TokenUnlocker.sol#L21

-   [ ] ID-382
        [TokenUnlocker.SYN](contracts/token/TokenUnlocker.sol#L22) should be immutable

contracts/token/TokenUnlocker.sol#L22

-   [ ] ID-383
        [ERC20X.addressStorage](contracts/ERC20X.sol#L12) should be immutable

contracts/ERC20X.sol#L12
