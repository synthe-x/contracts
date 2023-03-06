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
    pool: any,
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
    oracle = deployments.pools[0].oracle
    pool = deployments.pools[0].pool
    sbtc = deployments.pools[0].synths[0]
    seth = deployments.pools[0].synths[1]
    susd = deployments.pools[0].synths[2]
    sbtcPriceFeed = deployments.pools[0].synthPriceFeeds[0]
    sethPriceFeed = deployments.pools[0].synthPriceFeeds[1]

    await pool
      .connect(user1)
      .depositETH({
        value: ethers.utils.parseEther('100'),
      })
    await pool
      .connect(user2)
      .depositETH({
        value: ethers.utils.parseEther('100'),
      })
    await pool
      .connect(user3)
      .depositETH({
        value: ethers.utils.parseEther('100'),
      })

    await seth.connect(user1).mint(ethers.utils.parseEther('80')) // $ 80000
    await sbtc.connect(user2).mint(ethers.utils.parseEther('8')) // $ 80000
    await susd.connect(user3).mint(ethers.utils.parseEther('80000')) // $ 80000
  }

  describe('Liquidation @ 85', function () {
    beforeAll(async function () {
      await setup()
      // If we increase BTC price 1.25x, Total debt = 260000
      // Then User1 debt = 86666, User2 debt = 86666, User3 debt = 86666

      // increasing btc price to $12500
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('12500', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })
  })

  describe('Liquidation @ 90', function () {
    beforeAll(async function () {
      await setup()
      // If we increase BTC price 1.25x, Total debt = 260000
      // Then User1 debt = 86666, User2 debt = 86666, User3 debt = 86666

      // If we increase BTC price 1.5x, Total debt = 280000
      // Then User1 debt = 93333, User2 debt = 93333, User3 debt = 93333

      // If we increase BTC price 1.73x, Total debt = 298...
      // Then User1 debt = 995.., User2 debt = 995.., User3 debt = 995..

      // increasing btc price to $80000
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('80000', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
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

  describe('Liquidation @ 95', function () {
    beforeAll(async function () {
      await setup()
      // If we increase BTC price 1.25x, Total debt = 260000
      // Then User1 debt = 86666, User2 debt = 86666, User3 debt = 86666

      // If we increase BTC price 1.5x, Total debt = 280000
      // Then User1 debt = 93333, User2 debt = 93333, User3 debt = 93333

      // If we increase BTC price 1.73x, Total debt = 298...
      // Then User1 debt = 995.., User2 debt = 995.., User3 debt = 995..

      // increasing btc price to $80000
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('80000', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })
  })

  describe('Liquidation @ 99.5', function () {
    beforeAll(async function () {
      await setup()
      // If we increase BTC price 1.25x, Total debt = 260000
      // Then User1 debt = 86666, User2 debt = 86666, User3 debt = 86666

      // If we increase BTC price 1.5x, Total debt = 280000
      // Then User1 debt = 93333, User2 debt = 93333, User3 debt = 93333

      // If we increase BTC price 1.73x, Total debt = 298...
      // Then User1 debt = 995.., User2 debt = 995.., User3 debt = 995..

      // increasing btc price to $80000
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('80000', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })
  })

  describe('Liquidation @ 100.5', function () {
    beforeAll(async function () {
      await setup()
      // If we increase BTC price 1.25x, Total debt = 260000
      // Then User1 debt = 86666, User2 debt = 86666, User3 debt = 86666

      // If we increase BTC price 1.5x, Total debt = 280000
      // Then User1 debt = 93333, User2 debt = 93333, User3 debt = 93333

      // If we increase BTC price 1.73x, Total debt = 298...
      // Then User1 debt = 995.., User2 debt = 995.., User3 debt = 995..

      // increasing btc price to $80000
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('80000', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })
  })

  describe('liquidating multiple positions', async function () {
    before(async function () {
      await setup()
    })
  })

  describe('liquidation penalty and fees', async function () {
    before(async function () {
      await setup()
    })
  })
})
