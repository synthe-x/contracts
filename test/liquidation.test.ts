// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import main from '../scripts/main'
import { ETH_ADDRESS } from '../scripts/utils/const'
import { ERRORS } from '../scripts/utils/errors'

describe('Testing liquidation', function () {
  let synthex: any,
    oracle: any,
    sethPriceFeed: any,
    sbtcPriceFeed: any,
    pool: any,
    susd: any,
    sbtc: any,
    seth: any
  let owner: any, user1: any, user2: any, user3: any

  const setup = async () => {
    // Contracts are deployed using the first signer/account by default
    ;[owner, user1, user2, user3] = await ethers.getSigners()

    const deployments = await loadFixture(main)
    synthex = deployments.synthex
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

    await seth.connect(user1).mint(ethers.utils.parseEther('80'), user1.address, ethers.constants.AddressZero) // $ 80000
    await sbtc.connect(user2).mint(ethers.utils.parseEther('8'), user2.address, ethers.constants.AddressZero) // $ 80000
    await susd.connect(user3).mint(ethers.utils.parseEther('80000'), user3.address, ethers.constants.AddressZero) // $ 80000
  }

  describe('Liquidation @ 85', function () {
    before(async function () {
      await setup()
      // If we increase BTC price 1.25x, Total debt = 260000
      // Then User1 debt = 86666, User2 debt = 86666, User3 debt = 86666

      // increasing btc price to $12500
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('12500', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(85).div(100))

      expect(user2Liq[0]).to.be.lessThan(0);
    })

    it("should not be able to liquidate if health factor is above 85%", async function () {
      const initialLiq = await pool.getAccountLiquidity(user1.address);

      expect(initialLiq[2]/initialLiq[1]).to.be.closeTo(0.866666, 0.001)
      await expect(
        sbtc
          .connect(user2)
          .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS)
      ).to.be.revertedWith(ERRORS.ACCOUNT_BELOW_LIQ_THRESHOLD)
    });
  })

  describe('Liquidation @ 90', function () {
    before(async function () {
      await setup()
      // If we increase BTC price 1.5x, Total debt = 280000
      // Then User1 debt = 93333, User2 debt = 93333, User3 debt = 93333
      // increasing btc price to $15000
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('15000', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })

    it('user2 liquidates user1 with 1 BTC ($15000)', async function () {
      const initialLiq = await pool.getAccountLiquidity(user1.address);

      expect(initialLiq[2]/initialLiq[1]).to.be.closeTo(0.9333333, 0.000001)
      // liquidate 1 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS)

        
      // check health factor
      const liqNow = await pool.getAccountLiquidity(user1.address)
      expect(liqNow[2]/liqNow[1]).to.be.closeTo(initialLiq[2]/initialLiq[1], 0.001)

      // check if user2 got bonus
      expect(await pool.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.be.eq(ethers.utils.parseEther('11575').div(100))
    })

    it('user2 completely liquidates user1', async function () {
      const initialLiqBalance = await pool.accountCollateralBalance(user2.address, ETH_ADDRESS);

      // liquidate 6 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('6'), ETH_ADDRESS)

      // check health factor
      const liqNow = await pool.getAccountLiquidity(user1.address)
      expect(liqNow[2]).to.be.closeTo(0, 1e6)
      expect(liqNow[1]).to.be.closeTo(ethers.utils.parseEther('100'), ethers.utils.parseEther('100'))

      expect(await pool.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.be.closeTo(initialLiqBalance.add(ethers.utils.parseEther('83')), ethers.utils.parseEther("2"))
    })

    it('tries to liquidate again', async function () {
      // expect tx to revert
      await expect(
        sbtc
          .connect(user2)
          .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS),
      ).to.be.revertedWith(ERRORS.ACCOUNT_BELOW_LIQ_THRESHOLD)
    })
  })

  describe('Liquidation @ 99.5', function () {
    before(async function () {
      await setup()
      // If we increase BTC price 1.73x, Total debt = 298...
      // Then User1 debt = 995.., User2 debt = 995.., User3 debt = 995..

      // increasing btc price to $17300
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('17300', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })

    it('user2 liquidates user1 with 1 BTC ($15000)', async function () {
      const initialLiq = await pool.getAccountLiquidity(user1.address);

      expect(initialLiq[2]/initialLiq[1]).to.be.closeTo(0.995, 0.001)
      // liquidate 1 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS)

        
      // check health factor
      const liqNow = await pool.getAccountLiquidity(user1.address)
      expect(liqNow[2]/liqNow[1]).to.be.closeTo(initialLiq[2]/initialLiq[1], 0.001)

      // check if user2 got bonus
      expect(await pool.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.be.closeTo(ethers.utils.parseEther('11730').div(100), ethers.utils.parseEther('0.1'))
    })

    it('user2 completely liquidates user1', async function () {
      const initialLiqBalance = await pool.accountCollateralBalance(user2.address, ETH_ADDRESS);

      // liquidate 6 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('7'), ETH_ADDRESS)

      // check health factor
      const liqNow = await pool.getAccountLiquidity(user1.address)
      expect(liqNow[2]).to.be.closeTo(0, 1e6)
      expect(liqNow[1]).to.be.closeTo(ethers.utils.parseEther('100'), ethers.utils.parseEther('100'))

      expect(await pool.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.be.closeTo(initialLiqBalance.add(ethers.utils.parseEther('83')), ethers.utils.parseEther("2"))
    })

    it('expect dusted account', async function () {
      let accountLiq = await pool.getAccountLiquidity(user1.address);
      expect(accountLiq[1]).to.be.lessThan(ethers.utils.parseEther('0.00001'));
      expect(accountLiq[2]).to.be.lessThan(ethers.utils.parseEther('0.00001'));
    })
  })

  describe('Liquidation @ 100.5', function () {
    before(async function () {
      await setup()

      // If we increase BTC price 2x, Total debt = 320000
      // Then User1 debt = 106666, User2 debt = 106666, User3 debt = 106666

      // increasing btc price to $20000
      await sbtcPriceFeed.setPrice(ethers.utils.parseUnits('20000', 8), 8)

      // check health factor
      const user1Liq = await pool.getAccountLiquidity(user1.address);
      const user2Liq = await pool.getAccountLiquidity(user2.address);

      expect(user1Liq[0]).to.be.lessThan(0);
      expect(user1Liq[2].mul(ethers.constants.WeiPerEther).div(user1Liq[1])).to.be.greaterThan(ethers.constants.WeiPerEther.mul(9).div(10))

      expect(user2Liq[0]).to.be.lessThan(0);
    })

    it('user2 liquidates user1 with 1 BTC ($20000)', async function () {
      const initialLiq = await pool.getAccountLiquidity(user1.address);

      expect(initialLiq[2]/initialLiq[1]).to.be.closeTo(1.066666, 0.0001);
      // liquidate
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('1'), ETH_ADDRESS)

            
      // liquidator does not get bonus
      // liquidation value = collateral siezed value
      // remaining debt stays as bad debt
      const liqNow = await pool.getAccountLiquidity(user1.address)
      expect(liqNow[2]/liqNow[1]).to.be.greaterThan(initialLiq[2]/initialLiq[1])
      expect(await pool.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.be.equals(ethers.utils.parseEther('12000').div(100));
    })

    it('user2 completely liquidates user1', async function () {
      const initialLiqBalance = await pool.accountCollateralBalance(user2.address, ETH_ADDRESS);

      // liquidate 6 BTC
      await sbtc
        .connect(user2)
        .liquidate(user1.address, ethers.utils.parseEther('7'), ETH_ADDRESS)

      // check health factor
      const liqNow = await pool.getAccountLiquidity(user1.address);
      // bad debt should be 100000 - 106666 = 6666
      expect(liqNow[2]).to.be.closeTo(ethers.utils.parseEther("20000").div("3"), ethers.utils.parseEther('0.01'));
      expect(liqNow[1]).to.be.closeTo(0, ethers.utils.parseEther('1'))

      expect(await pool.accountCollateralBalance(user2.address, ETH_ADDRESS)).to.be.closeTo(initialLiqBalance.add(ethers.utils.parseEther('82')), ethers.utils.parseEther("2"))
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
