// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStaking} from "../src/interfaces/IStaking.sol";

contract StakingTest is Test, IStaking {
    Staking public staking;
    address public love;
    address public best;
    address public initialInviter;

    address public user;
    address public user1;
    address public user2;
    address public owner;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);

        //address for mainnet
        {
            love = address(0xf453560309713fE5480474432f0af56b15Dd51D0);
            best = address(0xDf71a9F5d2DD419f43b1C05Ce33B74F39De8eB12);
        }
        //create addr
        {
            initialInviter = address(0x4);
            user = address(0x1);
            user1 = address(0x2);
            user2 = address(0x3);
            owner = address(0x5);
        }
        //deploy contract
        vm.startPrank(owner);

        Staking stakingImpl = new Staking();
            //deploy proxy of staking
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl), 
                abi.encodeCall(
                    stakingImpl.initialize, 
                    (initialInviter, love, best)
                )
            );
        staking = Staking(payable(address(stakingProxy))); 

        vm.stopPrank();
    }

    function test_bindInviter(address _inviter, address _user) internal {
        vm.startPrank(_user);
        staking.bindInviter(_inviter);
        vm.stopPrank();
    }

    function test_staking() public {
        test_bindInviter(initialInviter, user);
        vm.startPrank(user);
        uint256 amount = 1 ether;
        deal(love, user, amount);
        IERC20(love).approve(address(staking), amount);
        staking.staking(Expired.EXPIRED30, amount);
        vm.stopPrank();
    }

    function test_stakingOrderInfo() public {
        test_staking();
        (Expired expired, address holder, uint256 amount, uint256 stakingTime, uint256 extracted, bool isRedeemed) = staking.stakingOrderInfo(1);
        assertEq(uint256(expired), 0);
        assertEq(holder, user);
        assertEq(amount, 1e18);
        assertEq(stakingTime, block.timestamp);
        assertEq(isRedeemed, false);
        assertEq(extracted, 0);

    }

    function test_getUserInfo() public {
        test_staking();
        // user info 
        (
            address _inviter,,
            uint256[] memory _validOrderIndexes,
            uint256[] memory _allOrderIndexes,,
        ) = staking.getUserInfo(user);
        assertEq(_inviter, initialInviter);
        assertEq(_validOrderIndexes.length, 1);
        assertEq(_allOrderIndexes.length, 1);
        // initialInviter info
        (
            ,uint256 _award,,,,
            AwardRecord[] memory _awardRecords
        ) = staking.getUserInfo(initialInviter);
        assertEq(_award, 1e18 * 8 / 100);
        assertEq(_awardRecords.length, 1);
    }

    

    function test_getOrderRealTimeYield() public {
        test_staking();
        vm.warp(block.timestamp + 1 days);
        uint256 realTimeYield = staking.getOrderRealTimeYield(1);
        uint256 expectedYield = uint256(1e18) * 100 / 30;
        assertEq(realTimeYield, expectedYield);

        vm.warp(block.timestamp + 40 days);
        uint256 realTimeYield2 = staking.getOrderRealTimeYield(1);
        uint256 expectedYield2 = uint256(1e18) * 100;
        assertEq(realTimeYield2, expectedYield2);
    }

    function test_getOrderCountdown() public {
        test_staking();
        uint256 countdown = staking.getOrderCountdown(1);
        assertEq(countdown, 30 days);

        vm.warp(block.timestamp + 31 days);
        uint256 countdown2 = staking.getOrderCountdown(1);
        assertEq(countdown2, 0);
    }

    function test_redeem() public {
        test_staking();
        vm.warp(block.timestamp + 31 days);
        // uint256 yieldAmount = staking.getOrderRealTimeYield(1);
        // assertEq(yieldAmount, 100e18);
        deal(best, address(staking), 100e18);
        vm.startPrank(user);
        staking.redeem(1);
        vm.stopPrank();

        (,,,, uint256 extracted, bool isRedeemed) = staking.stakingOrderInfo(1);

        assertEq(isRedeemed, true);
        assertEq(extracted, 100e18);
        assertEq(IERC20(best).balanceOf(address(staking)), 0);
        assertEq(IERC20(love).balanceOf(address(staking)), 0);
    }

    function test_redeem_expired90() public {
        
        vm.startPrank(user);
        deal(love, user, 1e18);
        IERC20(love).approve(address(staking), 1e18);
        staking.staking(Expired.EXPIRED90, 1e18);

        vm.warp(block.timestamp + 91 days);
        vm.expectRevert(bytes("Cannot redeem 90-day orders"));
        staking.redeem(1);

        deal(best, address(staking), 400e18);
        staking.claimOrder(1);
        assertEq(IERC20(best).balanceOf(user), 400e18);
        vm.stopPrank();

    }

    function test_claimOrder() public {
        test_staking();
        vm.warp(block.timestamp + 15 days);
        uint256 yieldAmount = staking.getOrderRealTimeYield(1);
        assertEq(yieldAmount, 50000000000000000000);
        deal(best, address(staking), 100e18);
        vm.startPrank(user);
        staking.claimOrder(1);
        assertEq(IERC20(best).balanceOf(user), 50e18);

        vm.expectRevert(bytes("No yield available"));
        staking.claimOrder(1);
        vm.stopPrank();
    }

    function test_claimAward() public {
        test_staking();
        (,uint256 _award,,,,) = staking.getUserInfo(initialInviter);
        vm.startPrank(initialInviter);
        staking.claimAward(_award);

        vm.expectRevert(bytes("Insufficient award balance"));
        staking.claimAward(1e18 * 8 / 100);
        vm.stopPrank();
    }
    
}
