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

contract LendingTest is Test {
  ILendingPool pool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  IAToken aUSDT = IAToken(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811);
  IAToken aDAI = IAToken(0x028171bCA77440897B824Ca71D1c56caC55b68A3);
  IAToken aUSDC = IAToken(0xBcca60bB61934080951369a648Fb03DF4F96263C);
  IUSDT usdt = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  IUSDC usdc = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IDAI dai = IDAI(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  address user1 = makeAddr('user1');
  address user2 = makeAddr('user2');
  address user3 = makeAddr('user3');
  address liquidator = makeAddr('liquidator');

  function setUp() public {
    vm.createSelectFork(vm.envString('MAINNET_RPC_URL'));
    vm.rollFork(vm.envUint('MAINNET_BLOCK_NUMBER'));
    deal(address(usdt), user1, 50 * 10 ** 6);
    deal(address(usdc), user1, 25 * 10 ** 6);
    deal(address(dai), user1, 50 * 10 ** 18);
    deal(address(dai), user2, 40 * 10 ** 18);
    deal(address(usdc), user2, 50 * 10 ** 6);
    deal(address(dai), user3, 50 * 10 ** 18);
    deal(address(usdc), user3, 50 * 10 ** 6);
    deal(address(usdc), liquidator, 1000 * 10 ** 6);
  }
  function testDeposit() public {
    uint256 halfbalusdt = usdt.balanceOf(user1) - 25 * 10 ** 6;
    console.log('balance aUSDT', aUSDT.balanceOf(user1));
    console.log('balance userusdt', usdt.balanceOf(user1));
    vm.startPrank(user1);
    usdt.approve(address(pool), halfbalusdt);
    pool.deposit(address(usdt), halfbalusdt, address(user1), 0);
    uint256 balaaveafterfirstdep = aUSDT.balanceOf(user1);
    uint256 balusdtafterfd = usdt.balanceOf(user1);
    console.log('After first deposit:');
    console.log('balance aUSDT', balaaveafterfirstdep);
    console.log('balance usderusdt', balusdtafterfd);
    vm.stopPrank();
    vm.startPrank(user1);
    usdt.approve(address(pool), 25 * 10 ** 6);
    pool.deposit(address(usdt), 25 * 10 ** 6, address(user1), 0);
    console.log('After second deposit:');
    console.log('balance aUSDT', aUSDT.balanceOf(user1));
    console.log('balance usderusdt', usdt.balanceOf(user1));
    vm.stopPrank();
  }

  function testWithdraw() public {
    vm.startPrank(user1);
    usdt.approve(address(pool), 50);
    pool.deposit(address(usdt), 50, address(user1), 0);
    vm.stopPrank();
    console.log('Balances before withdraw:');
    console.log('balance usdt', usdt.balanceOf(user1));
    console.log('balance aUSDT', aUSDT.balanceOf(user1));
    vm.startPrank(user1);
    pool.withdraw(address(usdt), aUSDT.balanceOf(user1), address(user1));
    console.log('Balances after withdraw:');
    console.log('balance usdt', usdt.balanceOf(user1));
    console.log('balance aUSDT', aUSDT.balanceOf(user1));
  }

  function testBorrow() public {
    vm.startPrank(user1);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user1), 0);
    console.log('Balances before borrow:');
    console.log('balance dai', dai.balanceOf(user1) / 1e6);
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    pool.borrow(address(usdc), 15 * 10 ** 6, 2, 0, address(user1));
    console.log('Balances after borrow:');
    console.log('balance dai', dai.balanceOf(user1));
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    vm.stopPrank();
  }

  function testRepay() public {
    vm.startPrank(user1);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user1), 0);
    console.log('Balances before borrow:');
    console.log('balance dai', dai.balanceOf(user1) / 1e6);
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    pool.borrow(address(usdc), 15 * 10 ** 6, 2, 0, address(user1));
    console.log('Balances after borrow:');
    console.log('balance dai', dai.balanceOf(user1));
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    vm.stopPrank();
    vm.warp(block.timestamp + 1 days);
    vm.startPrank(user1);
    usdc.approve(address(pool), 15 * 10 ** 6);
    pool.repay(address(usdc), 15 * 10 ** 6, 2, address(user1));
    console.log('Balances after repay:');
    console.log('balance dai', dai.balanceOf(user1));
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
  }
  function testRepayv2() public {
    vm.startPrank(user1);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user1), 0);
    uint256 aDaiStart = aDAI.balanceOf(user1);
    console.log('Balances after deposit , before borrow:');
    console.log('balance dai', dai.balanceOf(user1));
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    uint256 balanceuser1usdcbefore = usdc.balanceOf(user1);
    pool.borrow(address(usdc), 25 * 10 ** 6, 2, 0, address(user1));
    console.log('Balances after borrow:');
    console.log('balance dai', dai.balanceOf(user1));
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    console.log('BEFORE TIME WARP');
    vm.warp(block.timestamp + 1 days);
    uint256 aDaiEnd = aDAI.balanceOf(user1);
    console.log('RESERVE STATE (AFTER WARP):');
    console.log('aDAI balance:  ', aDaiEnd);
    vm.startPrank(user1);
    usdc.approve(address(pool), type(uint256).max);
    pool.repay(address(usdc), type(uint256).max, 2, address(user1));
    console.log('Balances after repay:');
    console.log('balance dai', dai.balanceOf(user1));
    console.log('balance aDAI', aDAI.balanceOf(user1));
    console.log('balance usdc', usdc.balanceOf(user1));
    console.log('profit aDAI:', aDaiEnd - aDaiStart);
    console.log('withheld interest usdc: ', balanceuser1usdcbefore - usdc.balanceOf(user1));
    vm.stopPrank();
  }

  function testSwapBorrowRateModev1() public {
    vm.startPrank(user1);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user1), 0);

    usdc.approve(address(pool), type(uint256).max);
    pool.borrow(address(usdc), 25 * 10 ** 6, 1, 0, address(user1));

    (
      uint256 configuration,
      uint128 liquidityIndex,
      uint128 variableBorrowIndex,
      uint128 currentLiquidityRate,
      uint128 currentVariableBorrowRate,
      uint128 currentStableBorrowRate,
      uint40 lastUpdateTimestamp,
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress,
      address interestRateStrategyAddress,
      uint8 id
    ) = pool.getReserveData(address(usdc));

    console.log('Debug Addresses:');
    console.log('aToken:', aTokenAddress);
    console.log('Stable Debt Token:', stableDebtTokenAddress);
    console.log('Variable Debt Token:', variableDebtTokenAddress);

    uint256 stableDebtBefore = IERC20(stableDebtTokenAddress).balanceOf(user1);
    uint256 variableDebtBefore = IERC20(variableDebtTokenAddress).balanceOf(user1);
    console.log('Before Swap - Stable:', stableDebtBefore, 'Variable:', variableDebtBefore);

    vm.warp(block.timestamp + 365 days);
    pool.swapBorrowRateMode(address(usdc), 1);

    uint256 stableDebtAfter = IERC20(stableDebtTokenAddress).balanceOf(user1);
    uint256 variableDebtAfter = IERC20(variableDebtTokenAddress).balanceOf(user1);
    console.log('After Swap - Stable:', stableDebtAfter, 'Variable:', variableDebtAfter);
  }
  function testSwapBorrowRateModev2() public {
    vm.startPrank(user1);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user1), 0);

    usdc.approve(address(pool), type(uint256).max);
    pool.borrow(address(usdc), 25 * 10 ** 6, 2, 0, address(user1));

    (
      uint256 configuration,
      uint128 liquidityIndex,
      uint128 variableBorrowIndex,
      uint128 currentLiquidityRate,
      uint128 currentVariableBorrowRate,
      uint128 currentStableBorrowRate,
      uint40 lastUpdateTimestamp,
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress,
      address interestRateStrategyAddress,
      uint8 id
    ) = pool.getReserveData(address(usdc));

    console.log('Debug Addresses:');
    console.log('aToken:', aTokenAddress);
    console.log('Stable Debt Token:', stableDebtTokenAddress);
    console.log('Variable Debt Token:', variableDebtTokenAddress);

    uint256 stableDebtBefore = IERC20(stableDebtTokenAddress).balanceOf(user1);
    uint256 variableDebtBefore = IERC20(variableDebtTokenAddress).balanceOf(user1);
    console.log('Before Swap - Stable:', stableDebtBefore, 'Variable:', variableDebtBefore);

    vm.warp(block.timestamp + 365 days);
    pool.swapBorrowRateMode(address(usdc), 2);

    uint256 stableDebtAfter = IERC20(stableDebtTokenAddress).balanceOf(user1);
    uint256 variableDebtAfter = IERC20(variableDebtTokenAddress).balanceOf(user1);
    console.log('After Swap - Stable:', stableDebtAfter, 'Variable:', variableDebtAfter);
  }

  function testSetUserUseReserveAsCollateral() public {
    vm.startPrank(user1);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user1), 0);
    pool.setUserUseReserveAsCollateral(address(dai), false);
    usdc.approve(address(pool), type(uint256).max);
    pool.borrow(address(usdc), 25 * 10 ** 6, 1, 0, address(user1));
  }
  function testLiquidationCall() public {
    vm.startPrank(user3);
    dai.approve(address(pool), 50 * 10 ** 18);
    pool.deposit(address(dai), 50 * 10 ** 18, address(user3), 0);
    usdc.approve(address(pool), 50 * 10 ** 6);
    pool.borrow(address(usdc), 37 * 10 ** 6, 1, 0, address(user3));

    (, , , , , uint256 healthFactorBefore) = pool.getUserAccountData(user3);
    (, , uint256 totalDebtBefore, , , ) = pool.getUserAccountData(user3);
    vm.stopPrank();
    console.log('balance aDAI user3 before liq', aDAI.balanceOf(user3));
    console.log('balance aUSDC user3 before liq', aUSDC.balanceOf(user3));
    console.log('balance aDAI liquidator before liq', aDAI.balanceOf(liquidator));
    console.log('balance aUSDC  liquidator before liq', aUSDC.balanceOf(liquidator));
    console.log('balance dai liquidator before liq', dai.balanceOf(liquidator));
    console.log('healthFactor user3 before the price drop:', healthFactorBefore);
    address oracleAddr = address(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);
    address daiAddr = address(dai);
    address usdcAddr = address(usdc);
    SimpleMockOracle mock = new SimpleMockOracle();
    vm.etch(oracleAddr, address(mock).code);
    SimpleMockOracle controlledOracle = SimpleMockOracle(payable(oracleAddr));
    controlledOracle.setAssetPrice(daiAddr, 1 * 10 ** 18);
    controlledOracle.setAssetPrice(usdcAddr, 1 * 10 ** 18);
    console.log('Price after setup:', controlledOracle.getAssetPrice(daiAddr));
    controlledOracle.setAssetPrice(daiAddr, 0.1 * 10 ** 18);
    uint256 priceCrashed = controlledOracle.getAssetPrice(daiAddr);
    console.log('Price after crash:', priceCrashed);
    console.log('Price USDC after crash:', controlledOracle.getAssetPrice(usdcAddr));
    (, , , , , uint256 hfAfter) = pool.getUserAccountData(address(user3));
    vm.stopPrank();
    console.log('Health Factor:', hfAfter);

    vm.startPrank(liquidator);
    usdc.approve(address(pool), type(uint256).max);
    pool.liquidationCall(address(dai), address(usdc), address(user3), 10 * 10 ** 6, false);
    vm.stopPrank();
    (, , uint256 totalDebtAfter, , , ) = pool.getUserAccountData(user3);
    console.log('Total Debt Before:', totalDebtBefore);
    console.log('Total Debt After:', totalDebtAfter);
    console.log('balance aDAI user3 after liq', aDAI.balanceOf(user3));
    console.log('balance aUSDC user3 after liq', aUSDC.balanceOf(user3));
    console.log('balance aDAI liquidator after liq', aDAI.balanceOf(liquidator));
    console.log('balance aUSDC  liquidator after liq', aUSDC.balanceOf(liquidator));
    console.log('balance dai liquidator after liq', dai.balanceOf(liquidator));
  }

  function testFlashloan() public {
    console.log('=== Test: Profitable Flash Loan Arbitrage ===');

    // 1. Setup
    SimpleMockOracle mock = new SimpleMockOracle();
    FlashLoanArbitrage arbitrage = new FlashLoanArbitrage(address(pool), mock);

    // Начальный баланс контракта: 2 USDT
    uint256 initialBalance = 2 * 10 ** 6;
    deal(address(usdc), address(arbitrage), initialBalance);
    vm.deal(address(arbitrage), 0.5 ether); // ETH для газа

    uint256 flashAmount = 1000 * 10 ** 6; // 1000 USDT
    uint256 expectedPremium = (flashAmount * 9) / 10000; // ~0.09% комиссия Aave (примерно)
    uint256 expectedProfit = (flashAmount * 5) / 1000; // 0.5% симулированная прибыль

    console.log('Balance before:', usdc.balanceOf(address(arbitrage)));

    // 2. Выполняем флэш-займ
    // ВАЖНО: Внутри executeOperation сработает vm.prank и переведёт прибыль
    arbitrage.executeArbitrage(address(usdc), flashAmount, 1.00e18);

    // 3. Проверка результатов
    uint256 finalBalance = usdc.balanceOf(address(arbitrage));
    console.log('Balance after:', finalBalance);

    // Ожидаемый баланс = initialBalance - premium + profit
    uint256 expectedFinal = initialBalance - expectedPremium + expectedProfit;

    console.log('Expected profit:', expectedProfit);
    console.log('Expected premium cost:', expectedPremium);
    console.log('Expected final balance:', expectedFinal);

    assertTrue(finalBalance > initialBalance, 'Profitable arbitrage should increase balance');

    console.log('Success: Arbitrage generated profit!');
  }
}
