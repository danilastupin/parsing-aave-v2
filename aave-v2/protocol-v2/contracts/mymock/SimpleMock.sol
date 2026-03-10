// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
contract SimpleMockOracle {
  mapping(address => uint256) public prices;

  event PriceUpdated(address indexed asset, uint256 oldPrice, uint256 newPrice);
  function owner() external view returns (address) {
    return msg.sender;
  }

  function getAssetPrice(address asset) external view returns (uint256) {
    uint256 price = prices[asset];
    require(price > 0, 'Oracle: price not set');
    return price;
  }

  function setAssetPrice(address asset, uint256 price) external {
    emit PriceUpdated(asset, prices[asset], price);
    prices[asset] = price;
  }
  function setPrices(address[] calldata assets, uint256[] calldata newPrices) external {
    require(assets.length == newPrices.length, 'Oracle: length mismatch');
    for (uint256 i = 0; i < assets.length; i++) {
      emit PriceUpdated(assets[i], prices[assets[i]], newPrices[i]);
      prices[assets[i]] = newPrices[i];
    }
  }
}
