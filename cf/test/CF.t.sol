// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CF} from "../src/CF.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";

contract CFTest is Test{

    CF public cf;

    address public deployUser;
    address public walletStore;
    address public usdt;
    address public uniswapV2Router;

    address public nftStaking;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        deployUser = vm.addr(1);
        walletStore = vm.addr(2);
        nftStaking = vm.addr(4);

        console.log("deployUser address:",deployUser);
        console.log("walletStore address:",walletStore);
        console.log("nftStaking address:",nftStaking);
        

        vm.startPrank(deployUser);
        cf = new CF(walletStore);
        cf.setNftStaking(nftStaking);
        // cf.transfer(walletStore, 800000e18);
        vm.stopPrank();
        console.log("PancakePair address:",cf.pancakePair());
        addLiquidity();
    }

    function addLiquidity() internal {
        vm.startPrank(deployUser);
        deal(usdt, deployUser, 10000e18);
        cf.approve(uniswapV2Router, 100000000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            address(cf), 
            10000e18, 
            100000e18, 
            0, 
            0, 
            deployUser, 
            block.timestamp + 10
        );
        vm.stopPrank();
        assertEq(cf.balanceOf(address(cf)), 3000e18);
        assertEq(cf.balanceOf(cf.pancakePair()), 97000e18);
        assertEq(cf.balanceOf(address(deployUser)), 900000e18);
        assertEq(cf.totalSupply(), 1000000e18);
    }

    function test_transfer() public {
        test_buy();
        vm.startPrank(deployUser);
        cf.transfer(walletStore, 10000e18);
        vm.stopPrank();
        // assertEq(cf.balanceOf(address(deployUser)), 890000e18);
        assertEq(cf.balanceOf(address(walletStore)), 10000e18);
        console.log("nftStaking`s usdt after buy and transfer:",IERC20(usdt).balanceOf(nftStaking));
    }

    function test_buy() public {
        vm.startPrank(deployUser);
        deal(usdt, deployUser, 500e18);

        IERC20(usdt).approve(uniswapV2Router, 500e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(cf);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            500e18, 
            0, 
            path, 
            deployUser, 
            block.timestamp
        );

        vm.stopPrank();
        console.log("deployUser`s usdt:",cf.balanceOf(deployUser));
        console.log("nftStaking`s usdt after buy:",IERC20(usdt).balanceOf(nftStaking));
    }

    function test_sell() public {

        vm.startPrank(walletStore);
        cf.approve(uniswapV2Router, 500e18);
        vm.stopPrank();

        vm.startPrank(deployUser);
        cf.transfer(walletStore, 500e18);
        cf.approve(uniswapV2Router, 100e18);
        address[] memory path = new address[](2);
        path[0] = address(cf);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            100e18, 
            0, 
            path, 
            deployUser, 
            block.timestamp
        );
        vm.stopPrank();
        assertEq(cf.balanceOf(address(walletStore)), 0);
        console.log("Wallet`s usdt:",IERC20(usdt).balanceOf(walletStore));
    }

    function test_transferAll() public {
        vm.startPrank(deployUser);
        uint256 amount = cf.balanceOf(deployUser);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        cf.transfer(walletStore, amount);
        vm.stopPrank();
    }
    
    
}
