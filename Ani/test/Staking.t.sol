// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract StakingTest is Test{
    Staking public staking;

    address public aniToken;
    address public agiToken;

    address public owner;
    address public admin;
    address public user1;
    address public user2;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);

        aniToken = address(0x77e066D53529d4104b4b98a5aE3668155601F4dA);
        agiToken = address(0xc2Da04c41519dda050ce2e05e28F8AeB74A4B52d);
        owner = address(0x1);
        admin = address(0x2);
        user1 = address(0x3);
        user2 = address(0x4);

        vm.startPrank(owner);
        Staking stakingImpl = new Staking();
        ERC1967Proxy stakingProxy = new ERC1967Proxy(
            address(stakingImpl), 
            abi.encodeCall(
                stakingImpl.initialize, 
                (aniToken, agiToken, admin)
            ));
        staking = Staking(payable(stakingProxy));
        vm.stopPrank();

        deal(aniToken, user1, 100000 * 1e18);
        deal(aniToken, user2, 100000 * 1e18);
        deal(agiToken, address(staking), 1000 * 1e18);
    }

    function test_stake_success() public {
        vm.startPrank(user1);
        uint256 orderId = staking.nextOrderId();
        console.log("Balance ani Of user1",IERC20(aniToken).balanceOf(user1));
        IERC20(aniToken).approve(address(staking), 10000 * 1e18);
        staking.stake(10000 * 1e18, Staking.Period.ONE_DAY);
        (address holder,uint256 aniAmount,uint256 time,uint256 withdrawn,Staking.Period period,bool extracted) = staking.stakingOrderInfo(orderId);
        assertEq(holder, user1);
        assertEq(aniAmount, 10000 * 1e18);
        assertEq(time, block.timestamp);
        assertEq(withdrawn, 0);
        assertEq(uint8(period), 1);
        assertEq(extracted, false);
        assertEq(staking.stakingOrdersIds(user1, 0), orderId);
        vm.stopPrank();
    }

    function _stakeAs(address user, uint256 amount, Staking.Period period) internal returns (uint256 orderId) {
        vm.startPrank(user);
        IERC20(aniToken).approve(address(staking), amount);
        orderId = staking.nextOrderId();
        staking.stake(amount, period);
        vm.stopPrank();
    }

    function test_claimEarnings_and_getPending() public {
        uint256 orderId = _stakeAs(user1, 10000 * 1e18, Staking.Period.ONE_DAY);

        // 刚质押，时间刚开始，pending 应该为0
        uint256 pending0 = staking.getOrderPending(orderId);
        assertEq(pending0, 0);

        // 快进1小时，计算预期收益，取 pending
        vm.warp(block.timestamp + 3600); 

        uint256 pending = staking.getOrderPending(orderId);
        assert(pending > 0);

        // user1 claim收益
        vm.startPrank(user1);
        staking.claimEarnings(orderId);
        vm.stopPrank();

        // claim后pending应变为0或接近0
        uint256 pendingAfterClaim = staking.getOrderPending(orderId);
        assertEq(pendingAfterClaim, 0);
    }

    function test_withdraw_afterMaturity() public {
        uint256 orderId = _stakeAs(user1, 10000 * 1e18, Staking.Period.ONE_DAY);

        // 快进1天加1秒，超过质押周期，才能withdraw
        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(user1);
        uint256 aniBefore = IERC20(aniToken).balanceOf(user1);
        uint256 agiBefore = IERC20(agiToken).balanceOf(user1);

        staking.withdraw(orderId);

        uint256 aniAfter = IERC20(aniToken).balanceOf(user1);
        uint256 agiAfter = IERC20(agiToken).balanceOf(user1);

        // 本金回来了
        assertEq(aniAfter - aniBefore, 10000 * 1e18);
        // 同时自动领取了收益，收益量 > 0
        assert(agiAfter > agiBefore);

        vm.stopPrank();
    }

    function test_getUserPending_and_getActiveOrderIndexes() public {
        uint256 orderId1 = _stakeAs(user1, 10000 * 1e18, Staking.Period.ONE_DAY);
        uint256 orderId2 = _stakeAs(user1, 20000 * 1e18, Staking.Period.SEVEN_DAYS);

        // 快进2小时，计算总pending
        vm.warp(block.timestamp + 7200);

        uint256 totalPending = staking.getUserPending(user1);
        assert(totalPending > 0);

        uint256[] memory activeOrders = staking.getActiveOrderIndexes(user1);
        // 应该包含两个未提取的订单
        assertEq(activeOrders.length, 2);
        assertEq(activeOrders[0], orderId1);
        assertEq(activeOrders[1], orderId2);

        // 提取第一个订单本金
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(user1);
        staking.withdraw(orderId1);
        vm.stopPrank();

        // 现在只剩下一个未提取订单
        uint256[] memory activeAfterWithdraw = staking.getActiveOrderIndexes(user1);
        assertEq(activeAfterWithdraw.length, 1);
        assertEq(activeAfterWithdraw[0], orderId2);
    }

    function test_noRewardsAfterPeriodEnd() public {
        uint256 orderId = _stakeAs(user1, 10000 * 1e18, Staking.Period.ONE_DAY);

        // 快进超过1天质押周期，比如1天+1小时
        vm.warp(block.timestamp + 1 days + 3600);

        // 计算pending，理论上只算到质押结束时刻，不算超出部分
        uint256 pending = staking.getOrderPending(orderId);

        // 记录当前pending
        assert(pending > 0);

        // 再快进1天，超过总周期后，不应该再增加pending
        vm.warp(block.timestamp + 2 days);

        uint256 pendingAfter = staking.getOrderPending(orderId);
        // 依然是之前的pending，没有增加
        assertEq(pendingAfter, pending);
    }


    function test_partialClaim_updatesWithdrawnEarnings() public {
        uint256 orderId = _stakeAs(user1, 10000 * 1e18, Staking.Period.ONE_DAY);

        // 快进半天
        vm.warp(block.timestamp + 12 hours);

        uint256 pending1 = staking.getOrderPending(orderId);
        assert(pending1 > 0);

        vm.startPrank(user1);
        staking.claimEarnings(orderId);  // 领取半天的收益
        vm.stopPrank();

        // 立即查询pending，应该接近0
        uint256 pendingAfterClaim = staking.getOrderPending(orderId);
        assertEq(pendingAfterClaim, 0);

        // 再快进6小时，总时间达到18小时
        vm.warp(block.timestamp + 6 hours);

        // 计算剩余pending，应该是18小时对应的总收益 - 已领取的收益
        uint256 pending2 = staking.getOrderPending(orderId);
        assert(pending2 > 0);
        assert(pending2 < pending1 * 2); // 肯定不会超过两倍
    }

    function test_getActiveOrderIndexes_forMultipleOrders() public {
        uint256 orderId1 = _stakeAs(user1, 10000 * 1e18, Staking.Period.ONE_DAY);
        uint256 orderId2 = _stakeAs(user1, 20000 * 1e18, Staking.Period.SEVEN_DAYS);

        // 初始两个订单都未提现本金，都是有效订单
        uint256[] memory activeOrders = staking.getActiveOrderIndexes(user1);
        assertEq(activeOrders.length, 2);

        // 快进超过1天，提现第一个订单本金
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(user1);
        staking.withdraw(orderId1);
        vm.stopPrank();

        // 第一个订单被标记为extracted，应从有效订单排除
        uint256[] memory activeAfterWithdraw = staking.getActiveOrderIndexes(user1);
        assertEq(activeAfterWithdraw.length, 1);
        assertEq(activeAfterWithdraw[0], orderId2);

        // 再快进超过7天，提现第二个订单本金
        vm.warp(block.timestamp + 7 days + 1);
        vm.startPrank(user1);
        staking.withdraw(orderId2);
        vm.stopPrank();

        // 没有有效订单了
        uint256[] memory activeAfterAllWithdraw = staking.getActiveOrderIndexes(user1);
        assertEq(activeAfterAllWithdraw.length, 0);
    }

}