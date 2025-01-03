// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CF} from "../src/CF.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {IUniswapV2Router} from "../src/interface/IUniswapV2Router.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CFTest is Test{
    CF public cf;
    NFTStaking public nftStaking;

    address public white0;
    address public cfReceiver;
    address public marketing;
    address public usdt;
    address public uniswapV2Router;
    address public regulation;
    address public test_buyAndSell;


    //随意初始化
    address public cfArt;
    address public dead;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        cfArt = address(0x14C5DF0fB04b07d63CfC55983A8393D7581907ae);
        dead = address(0x000000000000000000000000000000000000dEaD);
        
        white0 = vm.addr(1);
        cfReceiver = vm.addr(2);
        marketing = vm.addr(3);
        regulation = vm.addr(4);
        test_buyAndSell = vm.addr(5);

        vm.startPrank(cfReceiver);

        cf = new CF(marketing, regulation, cfReceiver);

        NFTStaking nftStakingImpl = new NFTStaking();
        // 使用ERC1967代理合约
        ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
            address(nftStakingImpl), 
            abi.encodeCall(nftStakingImpl.initialize, (cfArt, address(cf), dead))
        );
        nftStaking = NFTStaking(payable(nftStakingProxy));

        cf.setNftStaking(address(nftStaking));
        vm.stopPrank();
        
        console.log("PancakePair address:",cf.pancakePair());

        assertEq(cf.balanceOf(white0), 0);
        assertEq(cf.balanceOf(marketing), 0);
        assertEq(cf.balanceOf(address(nftStaking)), 0);
    }

    function test_noWhite_addLiquidity() public {
        vm.startPrank(cfReceiver);
        deal(usdt, cfReceiver, 10000e18);
        cf.approve(uniswapV2Router, 100000000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            address(cf), 
            10000e18, 
            100000e18, 
            0, 
            0, 
            cfReceiver, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(cf.balanceOf(address(cf)), 3000e18);
        assertEq(cf.balanceOf(cf.pancakePair()), 97000e18);
        
    }

    function test_transfer() public {
        vm.startPrank(cfReceiver);
        cf.transfer(white0, 10000e18);
        vm.stopPrank();
        assertEq(cf.balanceOf(address(white0)), 10000e18);
    }

    function test_white_addLiquidity() public {

        vm.startPrank(cfReceiver);
        cf.transfer(white0, 100000e18);
        cf.setTaxExemption(white0, true);
        vm.stopPrank();
        assertEq(cf.balanceOf(address(white0)), 100000e18);

        vm.startPrank(white0);
        deal(usdt, white0, 10000e18);
        cf.approve(uniswapV2Router, 100000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000e18);

        IUniswapV2Router(uniswapV2Router).addLiquidity(
            usdt, 
            address(cf), 
            10000e18, 
            100000e18, 
            0, 
            0, 
            white0, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(cf.balanceOf(address(cf)), 0);
        assertEq(cf.balanceOf(cf.pancakePair()), 100000e18);

    }

    function test_buy_noWhite() public {
        test_white_addLiquidity();

        console.log("Before buy noWhite nftStaking`s cf:",cf.balanceOf(address(nftStaking)));
        console.log("Before buy noWhite nftStaking`s perReward:",nftStaking.perStakingReward());

        vm.startPrank(test_buyAndSell);
        deal(usdt, test_buyAndSell, 500e18);

        IERC20(usdt).approve(uniswapV2Router, 500e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(cf);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            500e18, 
            0, 
            path, 
            test_buyAndSell, 
            block.timestamp
        );

        vm.stopPrank();
        console.log("After buy noWhite nftStaking`s cf:",cf.balanceOf(address(nftStaking)));
        console.log("After buy noWhite nftStaking`s perReward:",nftStaking.perStakingReward());
    }

    function test_buy_white() public {
        
        vm.startPrank(cfReceiver);
        cf.setTaxExemption(white0, true);
        vm.stopPrank();

        test_white_addLiquidity();

        console.log("Before buy white nftStaking`s cf:",cf.balanceOf(address(nftStaking)));
        console.log("Before buy white nftStaking`s perReward:",nftStaking.perStakingReward());

        vm.startPrank(white0);
        deal(usdt, white0, 500e18);

        IERC20(usdt).approve(uniswapV2Router, 500e18);
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = address(cf);
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            500e18, 
            0, 
            path, 
            white0, 
            block.timestamp
        );

        vm.stopPrank();
        console.log("After buy white nftStaking`s cf:",cf.balanceOf(address(nftStaking)));
        console.log("After buy white nftStaking`s perReward:",nftStaking.perStakingReward());
        assertEq(cf.balanceOf(address(nftStaking)), 0);
    }

    function test_sell_noWhite() public {
        test_white_addLiquidity();
        vm.startPrank(cfReceiver);
        cf.transfer(test_buyAndSell, 1000e18);
        vm.stopPrank();

        console.log("Before sell noWhite marketing`s usdt:",IERC20(usdt).balanceOf(marketing));

        vm.startPrank(test_buyAndSell);
        cf.approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = address(cf);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18, 
            0, 
            path, 
            test_buyAndSell, 
            block.timestamp
        );
        vm.stopPrank();
        assertEq(cf.balanceOf(address(test_buyAndSell)), 0);

        console.log("test_buyAndSell`s usdt:",IERC20(usdt).balanceOf(test_buyAndSell));
        console.log("Before sell noWhite marketing`s usdt:",IERC20(usdt).balanceOf(marketing));
    }

    function test_sell_white() public {
        test_white_addLiquidity();
        vm.startPrank(cfReceiver);
        cf.transfer(white0, 1000e18);
        cf.setTaxExemption(white0, true);
        vm.stopPrank();

        console.log("Before sell white marketing`s usdt:",IERC20(usdt).balanceOf(marketing));

        vm.startPrank(white0);
        cf.approve(uniswapV2Router, 1000e18);
        address[] memory path = new address[](2);
        path[0] = address(cf);
        path[1] = usdt;
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            1000e18, 
            0, 
            path, 
            white0, 
            block.timestamp
        );
        vm.stopPrank();
        assertEq(cf.balanceOf(address(white0)), 0);

        console.log("white0`s usdt:",IERC20(usdt).balanceOf(white0));
        console.log("After sell white marketing`s usdt:",IERC20(usdt).balanceOf(marketing));

    }

    function test_cf_mint_permit() public {
        vm.expectRevert("ERC20: caller is not the regulation");
        cf.mint(test_buyAndSell, 10e18);
    }

    function test_nftStaking_update_permit() public {
        vm.expectRevert("Permit error.");
        nftStaking.updatePool(100e18);
    }


    // function test_transferAll() public {
    //     vm.startPrank(deployUser);
    //     uint256 amount = cf.balanceOf(deployUser);
    //     vm.expectRevert("ERC20: transfer amount exceeds balance");
    //     cf.transfer(walletStore, amount);
    //     vm.stopPrank();
    // }
    
    
}
