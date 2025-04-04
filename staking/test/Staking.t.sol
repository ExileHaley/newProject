// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Staking} from "../src/Staking.sol";
import {IERC20} from "../src/interface/IERC20.sol";
import {IUniswapV2Router02} from "../src/interface/IUniswapV2Router02.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingTest is Test{

    Token public token;
    Staking public staking;

    address public usdt;
    address public uniswapV2Factory;
    address public uniswapV2Router;
    address public owner;


    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //初始化地址
        {
            token = Token(0x033E8FF9f37a786CDe1a6E7c96Dbb58e598E0962);
            usdt = address(0x55d398326f99059fF775485246999027B3197955);
            uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
            uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            owner = address(0xF5b6eFEB8A0CB3b2c4dA8A8F99eDD4AAFe8580ca);
        }

        //使用owner部署token合约以及staking合约
        vm.startPrank(owner);

        //部署质押合约
        {
            Staking stakingImpl = new Staking();
            //deploy proxy of staking
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl), 
                abi.encodeCall(
                    stakingImpl.initialize, 
                    (address(token), token.pancakePair())
                )
            );
            staking = Staking(payable(address(stakingProxy)));  
        }
        //配置代币
        token.setStaking(address(staking));

        vm.stopPrank();

        //断言配置信息
        assertEq(staking.usdt(), usdt);
        assertEq(staking.uniswapV2Factory(), uniswapV2Factory);
        assertEq(staking.token(), address(token));
        assertEq(staking.lp(), token.pancakePair());
        assertEq(staking.index(), 1);

    }

    function test_addLiquidity() public {
        console.log("Alreay liquidity usdt:", IERC20(usdt).balanceOf(token.pancakePair()));
        console.log("Alreay liquidity token:", token.balanceOf(token.pancakePair()));

        address user = vm.addr(0x1);
        deal(address(token), user, 1000e18);
        deal(usdt, user, 30000e18);

        vm.warp(block.timestamp + 3600);

        vm.startPrank(user);
        IERC20(usdt).approve(address(staking), 100000000e18);
        IERC20(address(token)).approve(address(staking), 100000000e18);
        staking.provide(1e18);
        vm.stopPrank();
        (, uint256 userLpBalance, uint256 time,,) = staking.stakingLiquidityInfo(user);
        uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(address(staking));
        assertGt(lpBalance, 0);
        assertEq(userLpBalance, lpBalance);
        assertEq(staking.totalStakingLiquidity(), lpBalance);
        assertEq(time, block.timestamp);

        console.log("After add liquidity:",IERC20(token.pancakePair()).balanceOf(address(staking)));
    }

    function test_removeLiquidity() public {
        address user = vm.addr(0x1);
        deal(address(token), user, 1000e18);
        deal(usdt, user, 30000e18);

        vm.warp(block.timestamp + 3600);

        vm.startPrank(user);
        IERC20(usdt).approve(address(staking), 100000000e18);
        IERC20(address(token)).approve(address(staking), 100000000e18);
        staking.provide(1e18);
        (uint256 usdtBalance, uint256 userLpBalance, uint256 time,uint256 pending,) = staking.stakingLiquidityInfo(user);
        console.log("First addLiquidity usdt result:", usdtBalance);
        console.log("First addLiquidity user lp result:", userLpBalance);
        console.log("First addLiquidity time result:", time);
        console.log("First addLiquidity pending result:", pending);
        vm.warp(block.timestamp + 60);

        staking.removeLiquidity();
        (uint256 usdtBalance1, uint256 userLpBalance1, uint256 time1,uint256 pending1,) = staking.stakingLiquidityInfo(user);
        console.log("Remove Liquidity usdt result:", usdtBalance1);
        console.log("Remove Liquidity user lp result:", userLpBalance1);
        console.log("Remove Liquidity time result:", time1);
        console.log("Remove Liquidity pending result:", pending1);
        console.log("perStakingReward:", staking.perStakingReward());
        vm.stopPrank();
    }
    function test_getUserLiquidityIncome() public {
        address user = vm.addr(0x1);
        deal(address(token), user, 1000e18);
        deal(usdt, user, 30000e18);

        vm.warp(block.timestamp + 3600);

        vm.startPrank(user);
        IERC20(usdt).approve(address(staking), 100000000e18);
        IERC20(address(token)).approve(address(staking), 100000000e18);
        staking.provide(1e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 60);
        (uint256 usdtBalance,,,,) = staking.stakingLiquidityInfo(user);
        uint256 secondTokenReward = staking.getUsdtForTokenAmount(usdtBalance) * 5 / 1000 / 86400;
        console.log("compute income:", secondTokenReward * 60);
        console.log("60s reward:", staking.getLiquidityTruthIncome(user));
        
        staking.claimLiquidity(user, staking.getLiquidityTruthIncome(user));
        console.log("After claim:", staking.getLiquidityTruthIncome(user));

        vm.startPrank(user);
        IERC20(usdt).approve(address(staking), 100000000e18);
        IERC20(address(token)).approve(address(staking), 100000000e18);
        staking.provide(1e18);
        vm.stopPrank();
        console.log("reStaking reward:", staking.getLiquidityTruthIncome(user));
    }

    function test_staking() public {
        address user = vm.addr(0x1);
        deal(address(token), user, 2000e18);
        vm.startPrank(user);
        IERC20(address(token)).approve(address(staking), 100000e18);
        //第一次质押
        staking.staking(1000e18);
        uint256[] memory validOrders = staking.getValidOrder(user);
        (address holder,uint256 tokenAmount, uint256 time, bool extracted) = staking.stakingSingleOrderInfo(validOrders[0]);
        assertEq(holder, user);
        assertEq(tokenAmount, 1000e18);
        assertEq(time, block.timestamp);
        assertEq(extracted, false);
        //第二次质押
        staking.staking(1000e18);
        uint256[] memory validOrders0 = staking.getValidOrder(user);
        (address holder0,uint256 tokenAmount0, uint256 time0, bool extracted0) = staking.stakingSingleOrderInfo(validOrders0[1]);
        assertEq(holder0, user);
        assertEq(tokenAmount0, 1000e18);
        assertEq(time0, block.timestamp);
        assertEq(extracted0, false);
        assertEq(validOrders0.length, 2);
        vm.stopPrank();
    }

    function test_withdraw() public {
        address user = vm.addr(0x1);
        deal(address(token), user, 2000e18);
        vm.startPrank(user);
        IERC20(address(token)).approve(address(staking), 100000e18);
        staking.staking(2000e18);
        vm.warp(block.timestamp + 1 days);
        // assertEq(staking.getUserSingleIncome(1), 220e18);
        assertEq(staking.getOrderStatus(1), 9 days);
    
        vm.warp(block.timestamp + 10 days);
        assertEq(staking.getUserSingleIncome(1), 2200e18);
        assertEq(staking.getOrderStatus(1), 0);
        
        //判断全局数组
        (address holder,uint256 tokenAmount,, bool extracted) = staking.stakingSingleOrderInfo(1);
        assertEq(holder, user);
        assertEq(tokenAmount, 2000e18);
        assertEq(extracted, false);

        //提取后状态判断
        staking.withdraw(1);
        assertEq(IERC20(address(token)).balanceOf(user), 2200e18);
        (,,, bool extracted0) = staking.stakingSingleOrderInfo(1);
        assertEq(extracted0, true);
        
        vm.expectRevert(bytes("Already extracted"));
        staking.withdraw(1);
        vm.stopPrank();
    }

}