// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPythPriceOracle2.sol";
import "../../synthex/SyntheX.sol";
import "@aave/core-v3/contracts/dependencies/chainlink/AggregatorInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import "hardhat/console.sol";

/**
 * @title PriceOracle
 * @author Aave
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the Aave governance
 */
contract PythPriceOracle is IPythPriceOracle2 {
  SyntheX public immutable synthex;

  IPyth pyth;

  mapping(address => bytes32) private assetsSources;

  IPriceOracleGetter private _fallbackOracle;
  address public immutable override BASE_CURRENCY;
  uint public immutable override BASE_CURRENCY_UNIT;
  /**
   * @dev Only asset listing or pool admin can call functions marked by this modifier.
   */
  modifier onlyAssetListingOrPoolAdmins() {
    require(
            synthex.isL1Admin(msg.sender),
            Errors.CALLER_NOT_L1_ADMIN
        );
    _;
  }

  /**
   * @notice Constructor
   * @param _synthex The address of the new System
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   * @param fallbackOracle The address of the fallback oracle to use if the data of an
   *        aggregator is not consistent
   * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
   * @param baseCurrencyUnit The unit of the base currency
   */
  constructor(
    SyntheX _synthex,
    IPyth _pyth,
    address[] memory assets,
    bytes32[] memory sources,
    address fallbackOracle,
    address baseCurrency,
    uint baseCurrencyUnit
  ) {
    synthex = _synthex;
    pyth = _pyth;
    _setFallbackOracle(fallbackOracle);
    _setAssetsSources(assets, sources);
    BASE_CURRENCY = baseCurrency;
    BASE_CURRENCY_UNIT = baseCurrencyUnit;
    emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
  }

  /// @inheritdoc IPythPriceOracle2
  function setAssetSources(address[] calldata assets, bytes32[] calldata sources)
    external
    override
    onlyAssetListingOrPoolAdmins
  {
    _setAssetsSources(assets, sources);
  }

  /// @inheritdoc IPythPriceOracle2
  function setFallbackOracle(address fallbackOracle)
    external
    override
    onlyAssetListingOrPoolAdmins
  {
    _setFallbackOracle(fallbackOracle);
  }

  /**
   * @notice Internal function to set the sources for each asset
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  function _setAssetsSources(address[] memory assets, bytes32[] memory sources) internal {
    require(assets.length == sources.length, Errors.INVALID_ARGUMENT);
    for (uint256 i = 0; i < assets.length; i++) {
      assetsSources[assets[i]] = sources[i];
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  /**
   * @notice Internal function to set the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function _setFallbackOracle(address fallbackOracle) internal {
    _fallbackOracle = IPriceOracleGetter(fallbackOracle);
    emit FallbackOracleUpdated(fallbackOracle);
  }

  /// @inheritdoc IPythPriceOracleGetter2
  function getAssetPrice(address asset, bytes[] memory pythUpdateData) public override returns (uint) {
    uint updateFee = pyth.getUpdateFee(pythUpdateData);
    pyth.updatePriceFeeds{value: updateFee}(pythUpdateData);

    bytes32 source = assetsSources[asset];

    if (asset == BASE_CURRENCY) {
      return BASE_CURRENCY_UNIT;
    } else if (source == bytes32(0)) {
      console.log("No source");
      return _fallbackOracle.getAssetPrice(asset);
    } else {
      console.log(uint(source));
      console.log(address(pyth));
      PythStructs.Price memory currentBasePrice = pyth.getPriceUnsafe(source);
      console.log(uint(int(currentBasePrice.price)));
      uint256 price = convertToUint(currentBasePrice, 8);
      if (price > 0) {
        return price;
      } else {
        return _fallbackOracle.getAssetPrice(asset);
      }
    }
  }

    function convertToUint(
        PythStructs.Price memory price,
        uint8 targetDecimals
    ) private pure returns (uint256) {
      if (price.price < 0 || price.expo > 0 || price.expo < -255) {
        revert();
      }
      uint8 priceDecimals = uint8(uint32(-1 * price.expo));
      if (targetDecimals - priceDecimals >= 0) {
        return
          uint(uint64(price.price)) *
          10 ** uint32(targetDecimals - priceDecimals);
      } else {
        return
          uint(uint64(price.price)) /
          10 ** uint32(priceDecimals - targetDecimals);
      }
    }

  /// @inheritdoc IPythPriceOracle2
  function getAssetsPrices(address[] calldata assets, bytes[] memory pythUpdateData)
    external
    override
    returns (uint[] memory)
  {
    uint[] memory prices = new uint[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i], pythUpdateData);
    }
    return prices;
  }

  /// @inheritdoc IPythPriceOracle2
  function getSourceOfAsset(address asset) external view override returns (bytes32) {
    return assetsSources[asset];
  }

  /// @inheritdoc IPythPriceOracle2
  function getFallbackOracle() external view returns (address) {
    return address(_fallbackOracle);
  }
}