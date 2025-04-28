// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";

contract TokenTest is Test{
    Token public token;

    address public owner;
    address public user;
    address public white;

    address public initialRecipient;
    address public exceedTaxWallet;

    address public uniswapV2Router;
    address public usdt;
    address public DEAD;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        DEAD = address(0x000000000000000000000000000000000000dEaD);
        
        owner = address(0x1);
        user = address(0x2);
        white = address(0x3);
        initialRecipient = address(0x4);
        exceedTaxWallet = address(0x5);

        vm.startPrank(owner);
        token = new Token("Token", "TKN", initialRecipient, exceedTaxWallet);
        address[] memory whitelist = new address[](1);
        whitelist[0] = white;
        token.setTaxExemption(whitelist, true);
        vm.stopPrank();
    }

    function test_whitelist_addLiquidity() public {
        vm.startPrank(initialRecipient);
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

        // assertEq(token.balanceOf(address(token)), 0);
        // assertEq(token.balanceOf(token.pancakePair()), 10000000e18);
        // assertEq(IERC20(usdt).balanceOf(token.pancakePair()), 10000000e18);
        // assertGt(IERC20(token.pancakePair()).balanceOf(white), 0);
    }

    function test_noWhitelist_addLiquidity() public {

        vm.startPrank(initialRecipient);
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
        assertEq(token.balanceOf(token.pancakePair()), 9700000e18);
        assertEq(IERC20(usdt).balanceOf(token.pancakePair()), 10000000e18);
        assertEq(token.balanceOf(user), 0);
        assertEq(IERC20(usdt).balanceOf(user), 0);
        assertEq(token.balanceOf(DEAD), 100000e18);
        assertEq(token.balanceOf(address(token)), 200000e18);
        assertEq(token.txFee(), 200000e18);
    }

    function test_noWhite_buy() public {
        test_whitelist_addLiquidity();
        deal(usdt, user, 100e18);

        vm.startPrank(user);
        IERC20(usdt).approve(uniswapV2Router, 100e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            100e18,
            0,
            path,
            user,
            block.timestamp + 10
        );
        vm.stopPrank();

        assertGt(token.balanceOf(user), 0);
        assertEq(IERC20(usdt).balanceOf(user), 0);
        assertGt(token.balanceOf(exceedTaxWallet), 0);
        assertGt(token.balanceOf(address(token)), 0);
        assertGt(token.txFee(), 0);
        assertGt(token.usdtCost(user), 0);
        // console.log("Usdt cost record:", token.usdtCost(user));
    }

    function test_whitelist_buy() public {
        test_whitelist_addLiquidity();
        deal(usdt, white, 5000e18);

        vm.startPrank(white);
        IERC20(usdt).approve(uniswapV2Router, 5000e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            5000e18,
            0,
            path,
            white,
            block.timestamp + 10
        );
        vm.stopPrank();

        assertGt(token.balanceOf(white), 0);
        assertEq(IERC20(usdt).balanceOf(white), 0);
    }

    function test_profitTax() public {
        test_whitelist_addLiquidity();

        deal(usdt, user, 115e18);
        vm.startPrank(user);
        IERC20(usdt).approve(uniswapV2Router, 115e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            115e18,
            0,
            path,
            user,
            block.timestamp + 10
        );
        vm.stopPrank();
        console.log("Usdt cost record:", token.usdtCost(user));
        console.log("Token balance of user:", token.balanceOf(user));

        vm.startPrank(white);
        deal(usdt, white, 10000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);
        address[] memory path2 = new address[](2);
        path2[0] = usdt;
        path2[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            10000e18,
            0,
            path2,
            white,
            block.timestamp + 10
        );
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(uniswapV2Router, 103e18);
        address[] memory path3 = new address[](2);
        path3[0] = address(token);
        path3[1] = usdt;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            103e18,
            0,
            path3,
            user,
            block.timestamp + 10
        );
        vm.stopPrank();
        assertGt(token.balanceOf(address(token)), 206e16);
        console.log("--------------------------------------------------------------");
        console.log("token balance of token address:", token.balanceOf(address(token)));
        console.log("--------------------------------------------------------------");
        
    }

    function test_calculateTaxes() public{
        test_whitelist_addLiquidity();
        
        vm.startPrank(initialRecipient);
        token.transfer(user, 200e18);
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(uniswapV2Router, 200e18);

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = usdt;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            100e18,
            0,
            path,
            user,
            block.timestamp + 10
        ); 

     
        vm.warp(block.timestamp + 30 minutes);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            100e18,
            0,
            path,
            user,
            block.timestamp + 10
        );

        assertEq(token.balanceOf(DEAD), 2e18);
        assertEq(token.balanceOf(address(token)), 4e18);
        assertEq(token.txFee(), 4e18);
        assertEq(token.balanceOf(exceedTaxWallet), 7e18);

        vm.stopPrank();
    }

    function test_swap_and_addLiquidity() public {
 
        test_noWhitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        token.transfer(user, 10000e18);
        vm.stopPrank();

        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        token.transfer(white, 1e18);
        vm.stopPrank();

        address user10 = address(0x10);

        vm.startPrank(white);
        token.transfer(user10, token.balanceOf(white));
        vm.stopPrank();

        address[] memory holders = token.getHolders();
        assertEq(holders[0], user);
        assertEq(holders[1], white);

        console.log("Balance of user:", token.balanceOf(user));
        console.log("Balance of white:", token.balanceOf(white));
        console.log("Balance of token address:", token.balanceOf(address(token)));
        console.log("Balance of txFee:", token.txFee());

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


        console.log("Balance of user after swap:", token.balanceOf(user));
        console.log("Balance of white after swap:", token.balanceOf(white));

        console.log("Balance of token address after swap:", token.balanceOf(address(token)));
        console.log("Balance of txFee after swap:", token.txFee());
        
        console.log("LP balance of dead:",IERC20(token.pancakePair()).balanceOf(DEAD));
        vm.startPrank(user10);
        token.transfer(initialRecipient, 1e18);
        vm.stopPrank();
        console.log("LP balance of dead after transfer:",IERC20(token.pancakePair()).balanceOf(DEAD));

    }

    function test_process() public {
        test_noWhitelist_addLiquidity();
        //user
        vm.startPrank(initialRecipient);
        token.transfer(user, 1e18);
        vm.stopPrank();

        test_whitelist_addLiquidity();
        //white
        vm.startPrank(initialRecipient);
        token.transfer(white, 1e18);
        vm.stopPrank();


        address user1 = address(0xA);
        //white
        vm.startPrank(white);
        token.transfer(user1, token.balanceOf(white));
        vm.stopPrank();
        //user
        vm.startPrank(user);
        token.transfer(user1, token.balanceOf(user));
        vm.stopPrank();
        assertEq(token.balanceOf(white), 0);
        assertEq(token.balanceOf(user), 0);

        address[] memory holders = token.getHolders();
        assertEq(holders[0], user);
        assertEq(holders[1], white);
        //user1
        vm.startPrank(user1);
        deal(usdt, user1, 1000e18);
        IERC20(usdt).approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18,
            0,
            path,
            user1,
            block.timestamp + 10
        );


        // token.testProfitFee();
        uint256 tokenAmount = token.balanceOf(user1);
        token.approve(uniswapV2Router, tokenAmount);
        address[] memory path2 = new address[](2);
        path2[0] = address(token);
        path2[1] = usdt;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path2,
            user1,
            block.timestamp + 10
        );

        console.log("Balance of token address after swap process:", token.balanceOf(address(token)));
        console.log("Balance of txFee after swap process:", token.txFee());
        vm.stopPrank();
        

        vm.startPrank(initialRecipient);
        token.transfer(user1, 1e18);
        vm.stopPrank();

        console.log("Balance of token address after transfer process:", token.balanceOf(address(token)));

        console.log("Balance of txFee after transfer process:", token.txFee());
        console.log("Balance of white after transfer process:", token.balanceOf(white));
        console.log("Balance of user after transfer process:", token.balanceOf(user));
    }

    function test_whitelist_removeLiquidity() public {
        test_whitelist_addLiquidity();

        vm.startPrank(white);
        console.log("Balance of wehite before remove:", token.balanceOf(white));

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
        console.log("Balance of wehite afetr remove:", token.balanceOf(white));
        console.log("Balance usdt of wehite afetr remove:", IERC20(usdt).balanceOf(white));
    }

    function test_noWhitelist_removeLiquidity() public {
        // test_not_whitelist_addLiquidity();
        test_noWhitelist_addLiquidity();
        // assertEq(token.balanceOf(user), 0);
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
        assertGt(token.balanceOf(user), 0);
        assertGt(IERC20(usdt).balanceOf(user), 0);
        vm.stopPrank();
    }

}