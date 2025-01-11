// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Mamba} from "../src/Mamba.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router} from "../src/interfaces/IUniswapV2Router.sol";

contract MambaTest is Test{
    Mamba public mamba;

    address public whiteAddr;
    address public blackAddr;
    address public marketing;
    address public initialRecipient;
    address public user;
    address public dead;


    address public usdt;
    address public uniswapV2Router;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        dead = 0x000000000000000000000000000000000000dEaD;
        
        whiteAddr = vm.addr(1);
        blackAddr = vm.addr(2);
        marketing = vm.addr(3);
        initialRecipient = vm.addr(4);
        user = vm.addr(5);

        vm.startPrank(initialRecipient);
        mamba = new Mamba(marketing, initialRecipient);
        mamba.setTaxExemption(whiteAddr, true);
        vm.stopPrank();
        
        console.log("PancakePair address:",mamba.pancakePair());
        assertEq(mamba.balanceOf(initialRecipient), 1000000000e18);

        assertEq(mamba.timeRecord(), 0);   
    }

    function test_whitelist_addLiquidity() public {
        vm.startPrank(initialRecipient);
        mamba.transfer(whiteAddr, 100000e18);
        vm.stopPrank();

        assertEq(mamba.balanceOf(address(whiteAddr)), 100000e18);

        vm.startPrank(whiteAddr);
        deal(usdt, whiteAddr, 10000e18);
        mamba.approve(uniswapV2Router, 100000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            address(mamba), 
            10000e18, 
            100000e18, 
            0, 
            0, 
            whiteAddr, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(mamba.balanceOf(address(mamba)), 0);
        assertEq(mamba.balanceOf(mamba.pancakePair()), 100000e18);
        assertEq(mamba.taxRate(), 2000);
   
    }

    function test_noWhitelist_addLiquidity() public {
        vm.startPrank(initialRecipient);
        mamba.transfer(user, 100000e18);
        vm.stopPrank();

        assertEq(mamba.balanceOf(address(user)), 100000e18);

        vm.startPrank(user);
        deal(usdt, user, 10000e18);
        mamba.approve(uniswapV2Router, 100000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);
        IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            address(mamba), 
            10000e18, 
            100000e18, 
            0, 
            0, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(mamba.balanceOf(address(mamba)), 10000e18);
        assertEq(mamba.balanceOf(mamba.pancakePair()), 80000e18);
        assertEq(mamba.balanceOf(dead), 10000e18);

    }

    function test_noWhitelist_buy() public {
        test_whitelist_addLiquidity();

        vm.startPrank(user);
        deal(usdt, user, 500e18);

        IERC20(usdt).approve(uniswapV2Router, 500e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(mamba);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            500e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );

        vm.stopPrank();

        assertEq(mamba.freeze(user), true);
        assertEq(mamba.freeze(mamba.pancakePair()), false);
        assertEq(mamba.freeze(uniswapV2Router), false);
        assertEq(mamba.timeRecord(), block.timestamp);
        console.log("Dead address balance:", mamba.balanceOf(dead));
        console.log("Mamba address balance:", mamba.balanceOf(address(mamba)));
    }

    function test_whitelist_buy() public {
        test_whitelist_addLiquidity();

        vm.startPrank(whiteAddr);
        deal(usdt, whiteAddr, 500e18);

        IERC20(usdt).approve(uniswapV2Router, 500e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(mamba);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            500e18, 
            0, 
            path, 
            whiteAddr, 
            block.timestamp
        );

        vm.stopPrank();

        assertEq(mamba.freeze(whiteAddr), false);
        assertEq(mamba.freeze(mamba.pancakePair()), false);
        assertEq(mamba.freeze(uniswapV2Router), false);
        assertEq(mamba.timeRecord(), block.timestamp);
        console.log("Dead address balance:", mamba.balanceOf(dead));
        console.log("Mamba address balance:", mamba.balanceOf(address(mamba)));
    }

    function test_freeze_whitelist() public {
        test_whitelist_buy();
        vm.startPrank(whiteAddr);
        mamba.transfer(dead, 100e18);
        vm.stopPrank();

        assertEq(mamba.balanceOf(dead), 100e18);
    }

    function test_freeze_failed() public {
        test_noWhitelist_buy();
        vm.startPrank(user);
        vm.expectRevert("ERC20: Account has been frozen.");
        mamba.transfer(dead, 10e18);
        vm.stopPrank();
    }

    function test_noWhitelist_sell() public {
        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        mamba.transfer(user, 1000e18);
        vm.stopPrank();

        vm.startPrank(user);
        mamba.approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = address(mamba);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();

        assertEq(mamba.freeze(user), false);
        assertEq(mamba.freeze(mamba.pancakePair()), false);
        assertEq(mamba.freeze(uniswapV2Router), false);
        assertEq(mamba.timeRecord(), block.timestamp);
        console.log("No white sell dead balance:", mamba.balanceOf(dead));
    }


    function test_whitelist_sell() public {
        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        mamba.transfer(whiteAddr, 1000e18);
        vm.stopPrank();

        vm.startPrank(whiteAddr);
        mamba.approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = address(mamba);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18, 
            0, 
            path, 
            whiteAddr, 
            block.timestamp
        );
        vm.stopPrank();

        assertEq(mamba.freeze(whiteAddr), false);
        assertEq(mamba.freeze(uniswapV2Router), false);
        assertEq(mamba.freeze(mamba.pancakePair()), false);
        assertEq(mamba.timeRecord(), block.timestamp);
        console.log("white sell dead balance:", mamba.balanceOf(dead));
    }

    function test_taxRate_after_oneHours() public {
        test_whitelist_addLiquidity();
        assertEq(mamba.timeRecord(), 0);
        
        vm.startPrank(initialRecipient);
        mamba.transfer(dead, 100e18);
        assertEq(mamba.timeRecord(), block.timestamp);

        vm.warp(block.timestamp + 3600);
        mamba.transfer(dead, 100e18);
        assertEq(mamba.taxRate(), 200);
        vm.stopPrank();
        
    }
}