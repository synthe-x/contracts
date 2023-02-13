// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import main from '../scripts/main'
import { ETH_ADDRESS } from '../scripts/utils/const'

describe('Testing liquidation', function () {
  let synthex: any,
    syn: any,
    oracle: any,
    sethPriceFeed: any,
    sbtcPriceFeed: any,
    cryptoPool: any,
    eth: any,
    susd: any,
    sbtc: any,
    seth: any
  let owner: any, user1: any, user2: any, user3: any

  let liqHealthFactor = ethers.utils.parseEther('1.00')

  const setup = async () => {
    // Contracts are deployed using the first signer/account by default
    ;[owner, user1, user2, user3] = await ethers.getSigners()

    const deployments = await loadFixture(main)
    synthex = deployments.synthex
    syn = deployments.syn
    oracle = deployments.oracle
    cryptoPool = deployments.pools[0]
    sbtc = deployments.poolSynths[0][0]
    seth = deployments.poolSynths[0][1]
    susd = deployments.poolSynths[0][2]
    sbtcPriceFeed = deployments.poolSynthPriceFeeds[0][0]
    sethPriceFeed = deployments.poolSynthPriceFeeds[0][1]

    await synthex
      .connect(user1)
      .depositETH(ethers.utils.parseEther('100'), {
        value: ethers.utils.parseEther('100'),
      })
    await synthex
      .connect(user2)
      .depositETH(ethers.utils.parseEther('100'), {
        value: ethers.utils.parseEther('100'),
      })
    await synthex
      .connect(user3)
      .deposit(ETH_ADDRESS, ethers.utils.parseEther('100'), {
        value: ethers.utils.parseEther('100'),
      })

    await seth.connect(user1).mint(ethers.utils.parseEther('25')) // $ 25000
    await sbtc.connect(user2).mint(ethers.utils.parseEther('2.5')) // $ 25000
    await susd.connect(user3).mint(ethers.utils.parseEther('25000')) // $ 25000

    // increasing btc price to $80000
    await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('80000', 8), 8)

    // check health factor
    expect(await synthex.healthFactorOf(user1.address)).to.be.lessThan(
      ethers.utils.parseEther('1.00'),
    )
    expect(await synthex.healthFactorOf(user2.address)).to.be.lessThan(
      ethers.utils.parseEther('1.00'),
    )
    liqHealthFactor = await synthex.healthFactorOf(user1.address)
  }

  describe('Liquidation', function () {
    before(async function () {
      await setup()
    })

    it('user2 liquidates user1 with 0.05 BTC ($4000)', async function () {
      expect(await synthex.healthFactorOf(user1.address)).to.equal(
        liqHealthFactor,
      )
      // liquidate 0.05 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('0.05'), ETH_ADDRESS)

      // check health factor
      const liqHealthFactorNow = await synthex.healthFactorOf(user1.address)
      expect(liqHealthFactorNow).to.be.lessThan(ethers.utils.parseEther('1.00'))
      expect(liqHealthFactorNow).to.be.greaterThan(liqHealthFactor)
      liqHealthFactor = liqHealthFactorNow
      expect(await synthex.healthFactorOf(user2.address)).to.be.greaterThan(
        ethers.utils.parseEther('1.00'),
      )
    })

    it('user2 completely liquidates user1', async function () {
      // liquidate 1 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS)

      // check health factor
      const user1Liquidity = await synthex.getAccountLiquidity(user1.address)
      expect(user1Liquidity[1]).to.be.closeTo(0, 1e8)
      expect(await synthex.healthFactorOf(user1.address)).to.be.greaterThan(
        ethers.utils.parseEther('100'),
      )
      expect(await synthex.healthFactorOf(user2.address)).to.be.greaterThan(
        ethers.utils.parseEther('1.00'),
      )
    })

    it('tries to liquidate again', async function () {
      // expect tx to revert
      await expect(
        sbtc
          .connect(user2)
          .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS),
      ).to.be.revertedWith('Invalid tokenOut amount')
    })
  })

  describe('liquidation with multiple collateral types', async function () {
    before(async function () {
      await setup()
    })
  })

  describe('Liquidation penalty and fees', async function () {
    before(async function () {
      await setup()
    })
  })
})
