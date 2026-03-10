// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IFlashLoanReceiver} from '../interfaces/IFlashLoanReceiver.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {SimpleMockOracle} from '../../contracts/mymock/SimpleMock.sol';
import {ILendingPoolAddressesProvider} from 'test/interfaces/ILendingPoolAddressesProvider.sol';
interface IMockDex {
  function executeArbitrageProfit(address token, uint256 amount) external;
}
contract FlashLoanArbitrage is IFlashLoanReceiver {
  ILendingPool public immutable pool;
  address public immutable owner;
  SimpleMockOracle public oracle;
  bool public simulateFailure = false;

  address public mockDex;

  event Log(string message, uint256 value);
  event ArbitrageProfit(uint256 profit);

  constructor(address _pool, SimpleMockOracle _oracle) {
    require(_pool != address(0), 'Invalid pool');
    pool = ILendingPool(_pool);
    oracle = _oracle;
    owner = msg.sender;
    mockDex = msg.sender;
  }

  function setMockDex(address _dex) external {
    mockDex = _dex;
  }

  function executeArbitrage(address asset, uint256 amount, uint256 _marketPrice) external {
    // Обновляем цену в оракле для создания возможности арбитража
    // Например, Оракул говорит: 1 USDC = 1.05 ETH (завышено), а на рынке 1.00
    oracle.setAssetPrice(asset, _marketPrice);

    address[] memory assets = new address[](1);
    assets[0] = asset;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    // Запускаем флэш-займ
    pool.flashLoan(address(this), assets, amounts, modes, address(this), '', 0);
  }

  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    require(msg.sender == address(pool), 'Caller must be pool');

    for (uint256 i = 0; i < assets.length; i++) {
      address asset = assets[i];
      uint256 amount = amounts[i];
      uint256 premium = premiums[i];
      uint256 totalOwed = amount + premium;

      uint256 balanceBeforeSwap = IERC20(asset).balanceOf(address(this));
      emit Log('Received from Pool', balanceBeforeSwap);
      //  ЛОГИКА АРБИТРАЖА (СВАП)
      // В реальности здесь: uniswapRouter.swap(...)
      // Мы эмулируем это, вызывая наш "MockDEX", который переведет нам прибыль

      if (!simulateFailure) {
        // Эмулируем успешный арбитраж:
        // Мы берем amount токенов, "продаем" их и получаем back amount + profit
        // Для этого мы вызываем функцию на mockDex, которая сделает нам transfer прибыли

        uint256 expectedProfit = (amount * 5) / 1000; // 0.5% профит от суммы займа

        // Вызываем "DEX", чтобы он перевел нам прибыль.
        // В тесте мы перехватим этот вызов через vm.prank и сделаем deal.
        // Это критически важно: перевод происходит ВНУТРИ контекста флэш-займа.
        try IMockDex(mockDex).executeArbitrageProfit(asset, expectedProfit) {} catch {}
        uint256 balanceAfterSwap = IERC20(asset).balanceOf(address(this));
        emit Log('Balance after Swap (Arbitrage)', balanceAfterSwap);
        emit ArbitrageProfit(balanceAfterSwap - balanceBeforeSwap);
      }

      // 2. ВОЗВРАТ СРЕДСТВ (REPAY)
      uint256 finalBalance = IERC20(asset).balanceOf(address(this));

      // Проверка: у нас должно хватить средств на возврат (долг + комиссия)
      require(finalBalance >= totalOwed, 'Insufficient funds to repay flashloan');

      IERC20(asset).approve(address(pool), 0);
      IERC20(asset).approve(address(pool), totalOwed);

      emit Log('Repaying Amount', totalOwed);
      emit Log('Remaining Profit', finalBalance - totalOwed);
    }

    return true;
  }

  function ADDRESSES_PROVIDER() external view override returns (ILendingPoolAddressesProvider) {
    return ILendingPoolAddressesProvider(pool.getAddressesProvider());
  }

  function LENDING_POOL() external view override returns (ILendingPool) {
    return pool;
  }

  function setSimulateFailure(bool _status) external {
    require(msg.sender == owner, 'Only owner');
    simulateFailure = _status;
  }
}
