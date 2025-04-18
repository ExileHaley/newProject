// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {IERC20} from "../src/interface/IERC20.sol";
import {IUniswapV2Router02} from "../src/interface/IUniswapV2Router02.sol";

contract TokenTest is Test {
    Token public token;

    address public owner;
    address public user;
    address public white;

    address public initialRecipient;
    address public exceedTaxWallet;

    address public nodeDividend;

    address public uniswapV2Router;
    address public WBNB;
    address public DEAD;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);

        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        DEAD = address(0x000000000000000000000000000000000000dEaD);
        
        owner = address(0x1);
        user = address(0x2);
        white = address(0x3);
        initialRecipient = address(0x4);
        exceedTaxWallet = address(0x5);
        nodeDividend = address(0x7);


        vm.startPrank(owner);
        token = new Token("Token", "TKN", initialRecipient, exceedTaxWallet, nodeDividend);
        address[] memory whitelist = new address[](1);
        whitelist[0] = white;
        token.setTaxExemption(whitelist, true);
        vm.stopPrank();
    }


    function test_whitelist_addLiquidity() public {
        // Transfer Token to white address
        vm.startPrank(initialRecipient);
        token.transfer(white, 500000000e18);
        assertEq(token.balanceOf(white), 500000000e18);
        vm.stopPrank();

        // Provide ETH to white address
        vm.deal(white, 1000e18); // 给 white 地址足够的 ETH
        assertEq(white.balance, 1000e18);
        // Start prank as white
        vm.startPrank(white);
        token.approve(uniswapV2Router, 500000000e18);

        // Add liquidity to the pool
        IUniswapV2Router02(uniswapV2Router).addLiquidityETH{value: 100e18}(
            address(token), 
            500000000e18, 
            0, 
            0, 
            white, 
            block.timestamp
        );
        vm.stopPrank();

        // Assertions to check if liquidity is added
        assertEq(IERC20(WBNB).balanceOf(token.pancakePair()), 100e18);
        assertEq(token.balanceOf(token.pancakePair()), 500000000e18); // Ensure liquidity pool has Token
    }

    function test_not_whitelist_addLiquidity() public {
        vm.startPrank(initialRecipient);
        token.transfer(user, 10000000e18);
        vm.stopPrank();

        vm.startPrank(user);
        vm.deal(user, 1000e18);
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
        uint256 taxAmount = 10000000e18 * 3 / 100;
        uint256 toLpDividend = taxAmount * 70 / 100;
        uint256 toNodeDividend = taxAmount * 20 / 100;
        uint256 toDead = taxAmount * 10 / 100;
        assertEq(token.balanceOf(address(token)), toLpDividend);
        assertEq(token.balanceOf(nodeDividend), toNodeDividend);
        assertEq(token.balanceOf(DEAD), toDead);
        assertEq(token.balanceOf(token.pancakePair()), 10000000e18 - taxAmount); // Ensure liquidity pool has Token
    }

    function test_whitelist_buy() public {
        test_whitelist_addLiquidity();
        vm.deal(white, 10e18);

        vm.startPrank(white);
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(token);

        IUniswapV2Router02(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 10e18}(
            0, 
            path, 
            white, 
            block.timestamp
        );
        vm.stopPrank();
        assertEq(white.balance, 0);
        assertGt(token.balanceOf(white), 0);
    }

    function test_not_whitelist_buy() public {
        test_whitelist_addLiquidity();
        vm.deal(user, 10e18);

        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 10e18}(
            0, 
            path, 
            user, 
            block.timestamp
        );
        
        vm.stopPrank();

        assertEq(user.balance, 0);
        // assertGt(token.balanceOf(lpDividend), 0);
        assertGt(token.balanceOf(exceedTaxWallet), 0);
        assertGt(token.balanceOf(nodeDividend), 0);
        assertGt(token.balanceOf(DEAD), 0);
        assertGt(token.balanceOf(user), 0);
    }
    
    function test_not_whitelist_buy_with_exceedTax() public {
        test_whitelist_addLiquidity();
        vm.deal(user, 10e18);

        vm.startPrank(initialRecipient);
        token.transfer(user, 10000000e18);
        vm.stopPrank();

        vm.startPrank(user);
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(token);
        IUniswapV2Router02(uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: 10e18}(
            0, 
            path, 
            user, 
            block.timestamp
        );
        
        vm.stopPrank();

        assertEq(user.balance, 0);
        // assertGt(token.balanceOf(lpDividend), 0);
        assertGt(token.balanceOf(exceedTaxWallet), 0);
        assertGt(token.balanceOf(nodeDividend), 0);
        assertGt(token.balanceOf(DEAD), 0);
        assertGt(token.balanceOf(user), 0);
    }

    function test_not_whitelist_sell_with_exceedTax10() public {
        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        token.transfer(user, 10000e18);
        vm.stopPrank();

        vm.warp(block.timestamp +  14 hours);
        vm.startPrank(user);
        token.approve(uniswapV2Router, 10000e18);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = WBNB;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            10000e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
        uint256 totalTaxAmount = 10000e18 * 10 / 100;
        uint256 baseTaxAmount = 10000e18 * 3 / 100;
        // uint256 toLpDividend = baseTaxAmount * 70 / 100;
        uint256 toNodeDividend = baseTaxAmount * 20 / 100;
        uint256 toDead = baseTaxAmount * 10 / 100;
        // assertEq(token.balanceOf(lpDividend), toLpDividend);
        assertEq(token.balanceOf(nodeDividend), toNodeDividend);
        assertEq(token.balanceOf(DEAD), toDead);
        assertEq(token.balanceOf(exceedTaxWallet), totalTaxAmount - baseTaxAmount);
        assertGt(user.balance, 0);
    }

    function test_not_whitelist_sell_with_exceedTax15() public {
        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        token.transfer(user, 10000e18);
        vm.stopPrank();

        vm.startPrank(user);
        token.approve(uniswapV2Router, 10000e18);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = WBNB;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            10000e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
        uint256 totalTaxAmount = 10000e18 * 15 / 100;
        uint256 baseTaxAmount = 10000e18 * 3 / 100;
        // uint256 toLpDividend = baseTaxAmount * 70 / 100;
        uint256 toNodeDividend = baseTaxAmount * 20 / 100;
        uint256 toDead = baseTaxAmount * 10 / 100;
        // assertEq(token.balanceOf(lpDividend), toLpDividend);
        assertEq(token.balanceOf(nodeDividend), toNodeDividend);
        assertEq(token.balanceOf(DEAD), toDead);
        assertEq(token.balanceOf(exceedTaxWallet), totalTaxAmount - baseTaxAmount);
        assertGt(user.balance, 0);
    }

    function test_not_whitelist_sell_with_exceedTax3() public {
        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        token.transfer(user, 10000e18);
        vm.stopPrank();

        vm.warp(block.timestamp +  24 hours);
        vm.startPrank(user);
        token.approve(uniswapV2Router, 10000e18);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = WBNB;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            10000e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
        uint256 baseTaxAmount = 10000e18 * 3 / 100;
        // uint256 toLpDividend = baseTaxAmount * 70 / 100;
        uint256 toNodeDividend = baseTaxAmount * 20 / 100;
        uint256 toDead = baseTaxAmount * 10 / 100;
        // assertEq(token.balanceOf(lpDividend), toLpDividend);
        assertEq(token.balanceOf(nodeDividend), toNodeDividend);
        assertEq(token.balanceOf(DEAD), toDead);
        assertEq(token.balanceOf(exceedTaxWallet), 0);
        assertGt(user.balance, 0);
    }

    function test_burn_percent() public {
        test_whitelist_addLiquidity();
        console.log("Before transfer lastBurnTime: ", token.lastBurnTime());
        uint256 pairSupply = token.balanceOf(token.pancakePair());
        uint256 burnAmount = pairSupply * 1 / 100;

        vm.startPrank(initialRecipient);
        token.transfer(user, 10000e18);
        console.log("After transfer lastBurnTime: ", token.lastBurnTime());
        vm.warp(block.timestamp + 6 hours);
        console.log("Warp 6 hours time: ", block.timestamp);
        token.transfer(user, 10000e18);
        assertEq(token.balanceOf(token.pancakePair()), pairSupply - burnAmount);


        uint256 newPairSupply = token.balanceOf(token.pancakePair());
        uint256 newBurnAmount = newPairSupply * 1 / 100;
        vm.warp(block.timestamp + 6 hours);
        console.log("Warp 12 hours time: ", block.timestamp);
        token.transfer(user, 10000e18);
        assertEq(token.balanceOf(token.pancakePair()), newPairSupply - newBurnAmount);


        console.log("Before 25 hours time:", block.timestamp);
        uint256 newPairSupply24 = token.balanceOf(token.pancakePair());
        uint256 newBurnAmount24 = newPairSupply24 * 4 / 100;
        vm.warp(block.timestamp + 25 hours);
        console.log("Warp 25 hours time: ", block.timestamp);
        token.transfer(user, 10000e18);
        assertEq(token.balanceOf(token.pancakePair()), newPairSupply24 - newBurnAmount24);

        vm.stopPrank();

    }

    function test_whitelist_removeLiquidity() public {
        test_whitelist_addLiquidity();

        vm.startPrank(white);
        uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(white);
        IERC20(token.pancakePair()).approve(uniswapV2Router, lpBalance);
        IUniswapV2Router02(uniswapV2Router).removeLiquidityETHSupportingFeeOnTransferTokens(
            address(token), 
            lpBalance, 
            0, 
            0, 
            white, 
            block.timestamp
        );
        vm.stopPrank();
        assertGt(token.balanceOf(white), 0);
        assertGt(white.balance, 0);
    }

    function test_not_whitelist_removeLiquidity() public {
        test_not_whitelist_addLiquidity();

        vm.startPrank(user);
        uint256 lpBalance = IERC20(token.pancakePair()).balanceOf(user);
        IERC20(token.pancakePair()).approve(uniswapV2Router, lpBalance);
        IUniswapV2Router02(uniswapV2Router).removeLiquidityETHSupportingFeeOnTransferTokens(
            address(token), 
            lpBalance, 
            0, 
            0, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
        assertGt(token.balanceOf(user), 0);
        assertGt(user.balance, 0);
    }

    function test_process() public {

        test_whitelist_addLiquidity();
        vm.startPrank(initialRecipient);
        token.transfer(white, 1e18);
        token.transfer(user, 10000e18);
        vm.stopPrank();
        
        vm.startPrank(user);
        token.approve(uniswapV2Router, 10000e18);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = WBNB;
        IUniswapV2Router02(uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            10000e18, 
            0, 
            path, 
            user, 
            block.timestamp
        );
        vm.stopPrank();
        uint256 fee = 10000e18 * 3 / 100 * 70 / 100;
        address[] memory holders = token.getHolders();
        console.log("holders address length:", holders.length);
        assertEq(holders.length, 1);

        vm.startPrank(initialRecipient);
        token.transfer(user, 1e18);
        vm.stopPrank();
      
        assertGt(token.balanceOf(white), fee);

    }

    function test_claim() public {
        vm.startPrank(initialRecipient);
        token.transfer(address(token), 1e18);
        vm.stopPrank();

        vm.startPrank(owner);
        console.log("Before transfer balance of user:",token.balanceOf(user));
        token.claim(user);
        console.log("After transfer balance of user:",token.balanceOf(user));
        vm.stopPrank();
    }

    function test_updateStatus() public {
        test_whitelist_addLiquidity();
        vm.startPrank(white);
        token.updateMyStatus();
        address[] memory holders = token.getHolders();
        assertEq(holders.length, 1);
        console.log("Holder address:", holders[0]);
        vm.stopPrank();
    }

}
