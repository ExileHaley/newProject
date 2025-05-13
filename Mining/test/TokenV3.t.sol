// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenV2} from "../src/TokenV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";

contract TokenV3Test is Test{
    TokenV2 public tokenV2;
    address public pair;
    address public user;
    address public uniswapV2Router;
    address public usdt;
    uint256 mainnetFork;

    function setUp() public {

        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);
        tokenV2 = TokenV2(0xE58ADC98e459Ce84FAC27BF450E0337afDa3995d);
        pair = tokenV2.pancakePair();
        
        user = address(0xF5b6eFEB8A0CB3b2c4dA8A8F99eDD4AAFe8580ca);


        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
    }
    
    function test_removeLiquidity() public {
        uint256 lpBalance = IUniswapV2Pair(pair).balanceOf(user);
        console.log("LP Balance of V3: ", lpBalance);
        vm.startPrank(user);
        IUniswapV2Pair(pair).approve(uniswapV2Router, lpBalance * 80 / 100);
        IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            address(tokenV2), 
            usdt, 
            lpBalance, 
            0, 
            0, 
            user, 
            block.timestamp+10
        );
        vm.stopPrank();
    }

}