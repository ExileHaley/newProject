// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {TokenV2} from "../src/TokenV2.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
// import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";

// contract TokenV2Test is Test{
//     TokenV2 public tokenV2;

//     address public owner;
//     address public user;
//     address public white;
//     address public initialRecipient;
//     address public exceedTaxWallet;

//     address public uniswapV2Router;
//     address public usdt;
//     address public DEAD;

//     uint256 mainnetFork;

//     function setUp() public {
//         mainnetFork = vm.createFork(vm.envString("RPC_URL"));
//         vm.selectFork(mainnetFork);

//         uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
//         usdt = address(0x55d398326f99059fF775485246999027B3197955);
//         DEAD = address(0x000000000000000000000000000000000000dEaD);
        
//         owner = address(0x1);
//         user = address(0x2);
//         white = address(0x3);
//         initialRecipient = address(0x4);
//         exceedTaxWallet = address(0x5);

//         vm.startPrank(owner);
//         tokenV2 = new TokenV2("Token", "TKN", initialRecipient, exceedTaxWallet);
//         address[] memory whitelist = new address[](1);
//         whitelist[0] = white;
//         tokenV2.setTaxExemption(whitelist, true);
//         vm.stopPrank();
//         whitelist_addLiquidity();
//     }

//     function whitelist_addLiquidity() public {
//         vm.startPrank(initialRecipient);
//         tokenV2.transfer(white, 10000000e18);
//         vm.stopPrank();
//         assertEq(tokenV2.balanceOf(white), 10000000e18);

//         vm.startPrank(white);
//         deal(usdt, white, 10000000e18);
//         tokenV2.approve(uniswapV2Router, 10000000e18);
//         IERC20(usdt).approve(uniswapV2Router, 10000000e18);
       
//         IUniswapV2Router02(uniswapV2Router).addLiquidity(
//             usdt, 
//             address(tokenV2), 
//             10000000e18, 
//             10000000e18, 
//             0, 
//             0, 
//             white, 
//             block.timestamp + 10
//         );
//         vm.stopPrank();

//         assertEq(tokenV2.balanceOf(address(tokenV2)), 0);
//         assertEq(tokenV2.balanceOf(tokenV2.pancakePair()), 10000000e18);
//         assertEq(IERC20(usdt).balanceOf(tokenV2.pancakePair()), 10000000e18);
//         assertGt(IERC20(tokenV2.pancakePair()).balanceOf(white), 0);
//         console.log("Liquidity original owner:", tokenV2.lpOriginalOwner(white));
//         // console.log("reserve0:", tokenV2.lastReserve0());
//         // console.log("reserve1:", tokenV2.lastReserve1());
//         (uint res0, uint res1, )  = IUniswapV2Pair(tokenV2.pancakePair()).getReserves();
//         console.log("res0:", res0);
//         console.log("res1:", res1);
//     }

//     function test_not_whitelist_addLiquidity() public {
//         vm.startPrank(owner);
//         tokenV2.setAtTheOpeningOrder();
//         vm.stopPrank();

//         vm.startPrank(initialRecipient);
//         tokenV2.transfer(user, 100e18);
//         vm.stopPrank();

//         vm.startPrank(user);
//         // uint256 amountUsdt = tokenV2.getAmountOutUSDT(100e18);
//         deal(usdt, user, 100e18);
//         tokenV2.approve(uniswapV2Router, 100e18);
//         IERC20(usdt).approve(uniswapV2Router, 100e18);
//         IUniswapV2Router02(uniswapV2Router).addLiquidity(
//             usdt, 
//             address(tokenV2), 
//             100e18, 
//             100e18, 
//             0, 
//             0, 
//             user, 
//             block.timestamp + 10
//         );

//         vm.stopPrank();
//     }

//     function test_whitelist_removeLiquidity() public {
//         uint256 lpBalance = IERC20(tokenV2.pancakePair()).balanceOf(white);
//         vm.startPrank(white);
//         IERC20(tokenV2.pancakePair()).approve(uniswapV2Router, lpBalance);
//         IUniswapV2Router02(uniswapV2Router).removeLiquidity(
//             usdt, 
//             address(tokenV2), 
//             lpBalance, 
//             0, 
//             0, 
//             white, 
//             block.timestamp + 10
//         );
//         vm.stopPrank();
//         assertGt(tokenV2.balanceOf(white), 0);
//     }

//     function test_not_whitelist_removeLiquidity() public {
//         test_not_whitelist_addLiquidity();

//         uint256 lpBalance = IERC20(tokenV2.pancakePair()).balanceOf(user);

//         vm.startPrank(user);
//         IERC20(tokenV2.pancakePair()).approve(uniswapV2Router, lpBalance);
//         IUniswapV2Router02(uniswapV2Router).removeLiquidity(
//             usdt, 
//             address(tokenV2), 
//             lpBalance, 
//             0, 
//             0, 
//             user, 
//             block.timestamp + 10
//         );
//         vm.stopPrank();
//     }

//     function test_lp_process() public {
//         console.log("token balance of add liquidity:", tokenV2.balanceOf(white));
//         // console.log("holders:",tokenV2.holders(0));
        

//         vm.startPrank(initialRecipient);
//         tokenV2.transfer(address(tokenV2), 1300e18);
//         tokenV2.transfer(white, 1e18);
//         vm.stopPrank();
//         address[] memory holders = tokenV2.getHolders();
//         console.log("holders length:", holders.length);

//         console.log("Token balance of white:", tokenV2.balanceOf(white));

//         vm.startPrank(white);
//         tokenV2.transfer(user, 1e18);
//         vm.stopPrank();

//         console.log("Token balance of white after process:", tokenV2.balanceOf(white));
//     }

//     function test_not_whitelist_buy_fee10() public {
//         console.log("Token balance of exceedTaxWallet before buy:",tokenV2.balanceOf(exceedTaxWallet));
//         console.log("Token balance of user before buy:",tokenV2.balanceOf(user));
//         console.log("Token balance of token contract before buy:",tokenV2.balanceOf(address(tokenV2)));
//         console.log("Token balance of dead before buy:",tokenV2.balanceOf(DEAD));

//         vm.startPrank(owner);
//         tokenV2.setAtTheOpeningOrder();
//         vm.stopPrank();

//         vm.startPrank(user);
//         deal(usdt, user, 500e18);
//         IERC20(usdt).approve(uniswapV2Router, 500e18);
//         address[] memory path = new address[](2);
//         path[0] = usdt;
//         path[1] = address(tokenV2);
//         IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
//             500e18,
//             0,
//             path,
//             user,
//             block.timestamp + 10
//         );
//         vm.stopPrank();

//         console.log("Token balance of exceedTaxWallet after buy:",tokenV2.balanceOf(exceedTaxWallet));
//         console.log("Token balance of user after buy:",tokenV2.balanceOf(user));
//         console.log("Token balance of token contract after buy:",tokenV2.balanceOf(address(tokenV2)));
//         console.log("Token balance of dead after buy:",tokenV2.balanceOf(DEAD));
//         console.log("Tx fee after buy:",tokenV2.txFee());
//     }

//     function test_transfer_addLiquidity() public {
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();
//         test_not_whitelist_buy_fee10();

//         uint256 lpBalance = IERC20(tokenV2.pancakePair()).balanceOf(DEAD);

//         console.log("Lp balance of dead before transfer:", lpBalance);
//         vm.startPrank(initialRecipient);
//         tokenV2.transfer(white, 100e18);
//         vm.stopPrank();
//         uint256 lpBalance0 = IERC20(tokenV2.pancakePair()).balanceOf(DEAD);
//         console.log("Lp balance of dead after transfer:", lpBalance0);
//     }

//     function test_transferLP_removeLiquidity() public {
//         vm.startPrank(owner);
//         tokenV2.setAtTheOpeningOrder();
//         vm.stopPrank();
        
//         vm.startPrank(white);
//         uint256 lpBalance = IERC20(tokenV2.pancakePair()).balanceOf(white);
//         console.log("Lp balance of white before transfer:", lpBalance);
//         IERC20(tokenV2.pancakePair()).transfer(user, lpBalance / 1000000);
//         vm.stopPrank();

//         vm.startPrank(user);
//         uint256 lpBalance0 = IERC20(tokenV2.pancakePair()).balanceOf(user);
//         console.log("LP balance of user:", lpBalance0);
//         IERC20(tokenV2.pancakePair()).approve(uniswapV2Router, lpBalance0);
//         IUniswapV2Router02(uniswapV2Router).removeLiquidity(
//             usdt, 
//             address(tokenV2), 
//             lpBalance0, 
//             0, 
//             0, 
//             user, 
//             block.timestamp + 10
//         );
//         vm.stopPrank();
//     }
// }