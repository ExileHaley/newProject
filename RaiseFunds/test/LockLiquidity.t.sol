// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {LockLiquidity} from "../src/LockLiquidity.sol";
import {IERC20} from "../src/interface/IERC20.sol";
import {IUniswapV2Router02} from "../src/interface/IUniswapV2Router02.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LockLiquidityTest is Test{
    Token public token;
    LockLiquidity public lockLiquidity;

    address public WBNB;
    address public uniswapV2Factory;
    address public uniswapV2Router;
    address public owner;
    address public lockOwner;
    address public user;

    address public initialRecipient;
    address public exceedTaxWallet;
    address public lpDividend;
    address public nodeDividend;
    address public dead;

    address public bnbRecipient;


    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        //初始化地址
        {
            WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
            uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
            uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            dead = address(0x000000000000000000000000000000000000dEaD);
            owner = address(0x1);
            lockOwner = address(0x2);
            user = address(0x3);
            initialRecipient = address(0x4);
            exceedTaxWallet = address(0x5);
            lpDividend = address(0x6);
            nodeDividend = address(0x7);
            bnbRecipient = address(0x8);
        }

        //使用owner部署token合约以及liquidity合约
        vm.startPrank(owner);
        //部署代币合约
        {
            token = new Token("Token", "TKN", initialRecipient, exceedTaxWallet, lpDividend, nodeDividend);
        }
        //部署liquidity合约
        {
            LockLiquidity lockLiquidityImpl = new LockLiquidity();
            //deploy proxy of staking
            ERC1967Proxy lockLiquidityProxy = new ERC1967Proxy(
                address(lockLiquidityImpl), 
                abi.encodeCall(
                    lockLiquidityImpl.initialize, 
                    (token.pancakePair(), address(token), lockOwner, bnbRecipient)
                )
            );
            lockLiquidity = LockLiquidity(payable(address(lockLiquidityProxy)));  
        }

        vm.stopPrank();

        //断言配置信息
        assertEq(token.balanceOf(initialRecipient), 1000000000e18);

        //添加流动性
        addLiquidity();
    }

    function addLiquidity() internal {
        vm.startPrank(initialRecipient);
        token.transfer(user, 10000000e18);
        vm.stopPrank();

        vm.startPrank(user);
        vm.deal(user, 100e18);
        token.approve(uniswapV2Router, 10000000e18);
        
        IUniswapV2Router02(uniswapV2Router).addLiquidityETH{value: 100e18}(
            address(token), 
            10000000e18, 
            0, 
            0, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
    }

    function test_lockLiquidity() public {
        uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(user);
        vm.startPrank(user);
        IERC20(token.pancakePair()).transfer(address(lockLiquidity), lpBalance);
        vm.stopPrank();

        vm.startPrank(lockOwner);
        address[] memory users = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        users[0] = user;
        amounts[0] = lpBalance;
        //断言触发事件
        vm.expectEmit(true, true, true, true);
        emit LockLiquidity.LockLiquidityCreated("FirstAdd", 1);

        lockLiquidity.lockLiquidity("FirstAdd", users, amounts);
        vm.stopPrank();
        
        assertEq(lockLiquidity.getUnlockedAmount(user), 0);

        (uint256 amount, uint256 time) = lockLiquidity.holderInfo(user);
        assertEq(amount, lpBalance);
        assertEq(time, block.timestamp);
    }

    function test_unlockLiquidity_with_removeFee() public {
        test_lockLiquidity();

        vm.startPrank(user);
        lockLiquidity.unlockLiquidity();
        vm.stopPrank();

        assertEq(token.balanceOf(user), 0);
        assertGt(user.balance, 0);
        
    }

    function test_unlockLiquidity() public {
        test_lockLiquidity();
        vm.warp(block.timestamp + 30 days);
        // uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(user);
        (uint256 amount,) = lockLiquidity.holderInfo(user);
        assertEq(lockLiquidity.getUnlockedAmount(user), amount);

        vm.startPrank(user);
        lockLiquidity.unlockLiquidity();
        vm.stopPrank();

        assertGt(token.balanceOf(user), 0);
        assertGt(user.balance, 0);
        (uint256 amount0, uint256 time) = lockLiquidity.holderInfo(user);
        assertEq(amount0, 0);
        assertEq(time, 0);
    }

    function test_raiseFunds() public {
        vm.startPrank(user);
        uint256 bnbBalance = bnbRecipient.balance;
        vm.deal(user, 10e18);
        vm.expectEmit(true, true, true, true);
        emit LockLiquidity.FundsRaised(user, 10e18);
        lockLiquidity.raiseFunds{value: 10e18}();
        vm.stopPrank();
        assertEq(user.balance, 0);
        assertEq(bnbRecipient.balance, 10e18 + bnbBalance);
        assertEq(lockLiquidity.raiseAmount(user), 10e18);
        assertEq(lockLiquidity.getRaiseAmount(user), 10e18);
        address[] memory funders = lockLiquidity.getFunders();
        assertEq(funders.length, 1);
        assertEq(funders[0], user);

    }

}