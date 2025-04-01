// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {IERC20} from "../src/interface/IERC20.sol";
import {IUniswapV2Router02} from "../src/interface/IUniswapV2Router02.sol";

contract TokenTest is Test{
    Token   public token;

    address public staking;
    address public owner;
    address public user;
    address public og;
    address public white;
    address public treasury;
    address public original;
    address public marketing;
    address public user1;

    address public uniswapV2Router;
    address public usdt;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);

        staking = vm.addr(1);
        owner = vm.addr(2);
        user = vm.addr(3);
        og = vm.addr(4);
        white = vm.addr(5);

        treasury = vm.addr(6);
        original = vm.addr(7);
        marketing = vm.addr(8);
        user1 = vm.addr(9);

        vm.startPrank(owner);
        token = new Token(marketing, treasury, original, "Token", "TKN");
        address[] memory whitelist = new address[](1);
        whitelist[0] = white;
        token.setTaxExemption(whitelist, true);
        address[] memory ogList = new address[](1);
        ogList[0] = og;
        token.setOgList(ogList, true);

        vm.stopPrank();

        assertEq(token.balanceOf(original), 100000000e18);
        assertEq(token.balanceOf(treasury), 3000000000e18);
    }
    
    function test_whitelist_addLiquidity() public {
        vm.startPrank(original);
        token.transfer(white, 10000000e18);
        vm.stopPrank();

        vm.startPrank(white);
        deal(usdt, white, 10000000e18);
        token.approve(uniswapV2Router, 10000000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000000e18);
        
        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            usdt, 
            address(token), 
            10000000e18, 
            10000000e18, 
            0, 
            0, 
            white, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(token.balanceOf(address(token)), 0);
        assertEq(token.balanceOf(token.pancakePair()), 10000000e18);

    }

    function test_not_whitelist_addLiquidity() public {
        vm.startPrank(original);
        token.transfer(user, 10000000e18);
        vm.stopPrank();

        vm.startPrank(user);
        deal(usdt, user, 10000000e18);
        token.approve(uniswapV2Router, 10000000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000000e18);
        
        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            usdt, 
            address(token), 
            10000000e18, 
            10000000e18, 
            0, 
            0, 
            user, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(token.balanceOf(address(token)), 10000000e18 * 5 / 1000);
        assertEq(token.balanceOf(token.pancakePair()), 10000000e18 * 99 / 100);
    }

    function test_whitelist_buy() public {
        test_whitelist_addLiquidity();
        deal(usdt, white, 1000e18);
        vm.startPrank(white);
        IERC20(usdt).approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18,
            0,
            path,
            white,
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(IERC20(usdt).balanceOf(white), 0);
        assertGt(token.balanceOf(white), 0);
        // assertGt(left, right);(token.bananceOf(white), 1000e18);
    }

    function test_og_buy() public {
        test_whitelist_addLiquidity();
        deal(usdt, og, 1000e18);

        vm.startPrank(og);
        IERC20(usdt).approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18,
            0,
            path,
            og,
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(IERC20(usdt).balanceOf(og), 0);
        assertGt(token.balanceOf(og), 0);
    }

    function test_not_whitelist_buy() public {
        test_whitelist_addLiquidity();
        uint256 lpSupply = IERC20(token.pancakePair()).totalSupply();
        assertGt(lpSupply, 0);
        deal(usdt, user, 1000e18);

        vm.startPrank(original);
        token.transfer(user, 1e18);
        vm.stopPrank();
        assertGt(token.openingPoint(), 0);
        console.log("openingPoint", token.openingPoint());
        vm.warp(block.timestamp + 3600);
        console.log("warpTime", block.timestamp);

        vm.startPrank(user);
        IERC20(usdt).approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18,
            0,
            path,
            user,
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(IERC20(usdt).balanceOf(user), 0);
        assertGt(token.balanceOf(user), 0);
    }

    function test_whitelist_sell() public {
        test_not_whitelist_addLiquidity();
        vm.startPrank(original);
        token.transfer(white, 10000e18);
        vm.stopPrank();

        vm.startPrank(white);
        token.approve(uniswapV2Router, 10000e18);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = usdt;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            10000e18,
            0,
            path,
            white,
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(token.balanceOf(white), 0);
        assertGt(IERC20(usdt).balanceOf(white), 0);
    }
    function test_not_whitelist_sell() public {
        test_whitelist_addLiquidity();
        vm.startPrank(original);
        token.transfer(user, 10000e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 3600);
        vm.startPrank(user);
        token.approve(uniswapV2Router, 10000e18);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = usdt;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            10000e18,
            0,
            path,
            user,
            block.timestamp + 10
        );
        vm.stopPrank();
        assertGt(IERC20(usdt).balanceOf(user), 0);
    }

    function test_hour_burn() public {
        test_whitelist_addLiquidity();
        uint256 beforeBalance = token.balanceOf(token.pancakePair());

        
        vm.startPrank(original);
        token.transfer(user, 1e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 3600);

        vm.startPrank(original);
        token.transfer(user, 1e18);
        vm.stopPrank();

        uint256 afterBalance = token.balanceOf(token.pancakePair());
        assertEq(beforeBalance, afterBalance + 50000e18);
        
    }

    function test_whitelist_transfer() public {
        vm.startPrank(original);
        token.transfer(white, 100e18);
        vm.stopPrank();

        vm.startPrank(white);
        token.transfer(user, 50e18);
        vm.stopPrank();

        assertEq(token.balanceOf(white), 50e18);
        assertEq(token.balanceOf(user), 50e18);
    }

    function test_not_whitelist_transfer() public {

        vm.startPrank(original);
        token.transfer(user, 100e18);
        vm.stopPrank();

        vm.startPrank(user);
        token.transfer(user1, 50e18);
        vm.stopPrank();

        assertEq(token.balanceOf(user), 50e18);
        assertEq(token.balanceOf(user1), 50e18);
    }

    function test_whitelist_removeLiquidity() public {
        test_whitelist_addLiquidity();

        vm.startPrank(white);
        uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(white);
        IERC20(token.pancakePair()).approve(uniswapV2Router, lpBalance);
        IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            usdt,
            address(token),
            lpBalance,
            0,
            0,
            white,
            block.timestamp + 10
        );
        vm.stopPrank();
    }

    function test_not_whitelist_removeLiquidity() public {
        test_not_whitelist_addLiquidity();
        vm.startPrank(original);
        token.transfer(user, 1e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 3600);
        vm.startPrank(user);
        uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(user);
        IERC20(token.pancakePair()).approve(uniswapV2Router, lpBalance);
        IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            usdt,
            address(token),
            lpBalance,
            0,
            0,
            user,
            block.timestamp + 10
        );
        vm.stopPrank();
    }
    
    function test_mint() public {
        vm.startPrank(owner);
        token.setStaking(staking);
        vm.stopPrank();

        vm.startPrank(staking);
        token.mint(user, 100e18);
        vm.stopPrank();
        assertEq(token.balanceOf(user), 100e18);
    }

    function test_valid_invite_noCover() public {
        address addrA = vm.addr(1);
        address addrB = vm.addr(2);
        address addrC = vm.addr(3);
        vm.startPrank(original);
        token.transfer(addrA, 100e18);
        vm.stopPrank();        

        vm.startPrank(addrA);
        token.transfer(addrB, 1e18);
        vm.stopPrank();

        (address pendingInvietr,,uint256 time) = token.invitationes(addrB);
        assertEq(pendingInvietr, addrA);
        assertGt(time, 0);

        vm.startPrank(addrB);
        token.transfer(addrA, 1e18);
        vm.stopPrank();

        (,address inviter,) = token.invitationes(addrB);
        assertEq(inviter, addrA);

        //确保不会覆盖
        vm.startPrank(original);
        token.transfer(addrC, 100e18);
        vm.stopPrank();   

        vm.startPrank(addrC);
        token.transfer(addrB, 1e18);
        vm.stopPrank();

        vm.startPrank(addrB);   
        token.transfer(addrC, 1e18);
        vm.stopPrank();

        (,address inviter1,) = token.invitationes(addrB);
        assertEq(inviter1, addrA);
    }

    function test_cover_of_valid_invite() public {

        address addrA = vm.addr(1);
        address addrB = vm.addr(2);
        address addrC = vm.addr(3);
        vm.startPrank(original);
        token.transfer(addrA, 100e18);
        token.transfer(addrC, 100e18);
        vm.stopPrank();        

        vm.startPrank(addrA);
        token.transfer(addrB, 1e18);
        vm.stopPrank();

        (address pendingInvietr,,uint256 time) = token.invitationes(addrB);
        assertEq(pendingInvietr, addrA);
        assertEq(time, block.timestamp);

        vm.warp(block.timestamp + 301);
        vm.startPrank(addrC);
        token.transfer(addrB, 1e18);
        vm.stopPrank();
        (address pendingInvietr1,,) = token.invitationes(addrB);
        assertEq(pendingInvietr1, addrC);
        

        vm.startPrank(addrB);
        token.transfer(addrC, 1e18);
        vm.stopPrank();

        (,address inviter,) = token.invitationes(addrB);
        assertEq(inviter, addrC);
    }

}