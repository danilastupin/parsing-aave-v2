// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from 'forge-std/Test.sol';
import {ILendingPool} from './interfaces/ILendingPool.sol';
import {IAToken} from './interfaces/IAToken.sol';
import {IUSDT} from 'test/interfaces/IUSDT.sol';
import {IUSDC} from 'test/interfaces/IUSDC.sol';
import {IDAI} from 'test/interfaces/IDAI.sol';
import {IERC20} from 'test/interfaces/IERC20.sol';
import {IPriceOracle} from 'test/interfaces/IPriceOracle.sol';
import {SimpleMockOracle} from 'contracts/mymock/SimpleMock.sol';
import {ILendingPoolAddressesProvider} from 'test/interfaces/ILendingPoolAddressesProvider.sol';
import {IFlashLoanReceiver} from 'test/interfaces/IFlashLoanReceiver.sol';
import {FlashLoanArbitrage} from 'test/FlashLoanArbitrage/FlashLoanArbitrage.sol';
interface IMockDex {
  function executeArbitrageProfit(address token, uint256 amount) external;
}
contract LendingTest is Test, IMockDex {
  FlashLoanArbitrage arbitrageContract;
  SimpleMockOracle oracle;
  ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  IAToken aUSDC = IAToken(0xBcca60bB61934080951369a648Fb03DF4F96263C);
  IUSDC usdc = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  function setUp() public {
    vm.createSelectFork(vm.envString('MAINNET_RPC_URL'));
    vm.rollFork(vm.envUint('MAINNET_BLOCK_NUMBER'));
    oracle = new SimpleMockOracle();
    arbitrageContract = new FlashLoanArbitrage(address(pool), oracle);
    vm.deal(address(arbitrageContract), 1 ether);
  }
  function executeArbitrageProfit(address token, uint256 amount) external override {
    // Проверяем, что вызов пришел от нашего контракта арбитража
    require(msg.sender == address(arbitrageContract), 'Only arbitrage contract can call this');

    // ЭМУЛЯЦИЯ DEX:
    // В реальности DEX перевел бы токены. Здесь мы используем deal,
    // чтобы "сгенерировать" токены и перевести их контракту ПРЯМО СЕЙЧАС.
    // Это происходит ВНУТРИ транзакции флэш-займа.
    deal(
      address(usdc),
      address(arbitrageContract),
      usdc.balanceOf(address(arbitrageContract)) + amount
    );

    emit log_named_uint('MockDEX: Transferred profit to contract', amount);
  }
  function testFlashLoan() public {
    console.log('Start  Arbitrage Simulation');

    uint256 flashAmount = 1000 * 10 ** 6; // 1000 USDC
    uint256 initialBalance = usdc.balanceOf(address(arbitrageContract));

    console.log('1. Contract Balance BEFORE FlashLoan:', initialBalance);
    assertEq(initialBalance, 0, 'Contract should start with 0 USDC to prove the point');

    uint256 fakePrice = 1.05e18;

    // ЗАПУСК ФЛЭШ-ЗАЙМА
    // Внутри этого вызова произойдет цепочка:
    // Pool -> Contract.executeOperation() -> Contract calls THIS.executeArbitrageProfit() -> deal()
    arbitrageContract.executeArbitrage(address(usdc), flashAmount, fakePrice);
    //

    uint256 finalBalance = usdc.balanceOf(address(arbitrageContract));
    uint256 premium = (flashAmount * 9) / 10000; // ~0.09%
    uint256 expectedProfitGross = (flashAmount * 5) / 1000; // 0.5%
    uint256 expectedNetProfit = expectedProfitGross - premium;

    console.log('2. Contract Balance AFTER FlashLoan:', finalBalance);
    console.log('3. Gross Profit generated:', expectedProfitGross);
    console.log('4. Premium paid to Aave:', premium);
    console.log('5. Net Profit remaining:', finalBalance - initialBalance);

    // Баланс должен стать равным чистой прибыли (так как стартовый был 0)
    assertEq(finalBalance, expectedNetProfit, 'Final balance should equal net profit');

    // Самое главное: баланс должен быть БОЛЬШЕ начального (0)
    assertTrue(finalBalance > initialBalance, 'Arbitrage must generate profit using FlashLoan');
  }
}
