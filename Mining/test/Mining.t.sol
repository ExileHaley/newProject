// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {Token} from "../src/Token.sol";
// import {Mining} from "../src/Mining.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
// import {IMining} from "../src/interfaces/IMining.sol";

// contract MiningTest is Test, IMining{
//     Token public token;
//     Mining public mining;

//     address public owner;
//     address public initialRecipient;
//     address public initialInviter;
//     address public exceedTaxWallet;
//     address public user;
//     address public usdt;
//     address public uniswapV2Router;

//     uint256 mainnetFork;

//     function setUp() public {

//         mainnetFork = vm.createFork(vm.envString("RPC_URL"));
//         vm.selectFork(mainnetFork);

//         // init address
//         {
//             owner = address(0x1);
//             initialRecipient = address(0x2);
//             initialInviter = address(0x3);
//             exceedTaxWallet = address(0x4);
//             user = address(0x5);
//             usdt = address(0x55d398326f99059fF775485246999027B3197955);
//             uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
//         }

//         vm.startPrank(owner);
//         // deploy token
//         token = new Token("TEST", "TES", initialRecipient, exceedTaxWallet);
//         // deploy mining
//         {
//             Mining miningImpl = new Mining();
//             //deploy proxy of staking
//             ERC1967Proxy miningProxy = new ERC1967Proxy(
//                 address(miningImpl), 
//                 abi.encodeCall(
//                     miningImpl.initialize, 
//                     (address(token), token.pancakePair())
//                 )
//             );
//             mining = Mining(payable(address(miningProxy))); 
//         }
//         token.setMining(address(mining));
//         vm.stopPrank();

//         vm.startPrank(initialRecipient);
//         token.transfer(user, 1000e18);
//         vm.stopPrank();

//         addLiquidity();
//     }

//     function addLiquidity() internal {
//         vm.startPrank(initialRecipient);
//         deal(usdt, initialRecipient, 10000000e18);
//         token.approve(uniswapV2Router, 10000000e18);
//         IERC20(usdt).approve(uniswapV2Router, 10000000e18);
        
//         IUniswapV2Router02(uniswapV2Router).addLiquidity(
//             usdt, 
//             address(token), 
//             10000000e18, 
//             10000000e18, 
//             0, 
//             0, 
//             initialRecipient, 
//             block.timestamp + 10
//         );
//         vm.stopPrank();

//         assertEq(token.balanceOf(token.pancakePair()), 10000000e18);
//     }

//     function test_transfer(address sender, address recipient, uint256 amount) internal{
//         vm.startPrank(sender);
//         token.transfer(recipient, amount);
//         vm.stopPrank();
//     }

//     function test_bindInviter(address _user, address _inviter) internal{
//         vm.startPrank(_user);
//         mining.bindInviter(_inviter);
//         vm.stopPrank();
//     }

//     function test_staking_for_specify(address _user, uint256 _amount) internal{
//         vm.startPrank(_user);
//         token.approve(address(mining), _amount);
//         mining.staking(_amount);
//         vm.stopPrank();
//     }

//     function test_staking_reward() public {
//         test_transfer(initialRecipient, initialInviter, 1e18);
//         test_bindInviter(user, initialInviter);
//         test_staking_for_specify(initialInviter, 1e18);
//         test_staking_for_specify(user, 1000e18);
//         //user info
//         (address _inviter,,,,uint256[] memory _validOrderIndexes,uint256[] memory _orderIndexes,,) = mining.getUserInfo(user);
//         assertEq(_inviter, initialInviter);
//         assertEq(_validOrderIndexes.length, 1);
//         assertEq(_orderIndexes.length, 1);

//         //assert order info
//         (address holder, uint256 amount, uint256 stakingTime, bool isExtracted) = mining.stakingOrderInfo(_orderIndexes[0]);
//         assertEq(holder, user);
//         assertEq(amount, 1000e18);
//         assertEq(stakingTime, block.timestamp);
//         assertEq(isExtracted, false);

//         //assert inviter award
//         (,uint256 _award,,,,,address[] memory _invitees,AwardRecord[] memory _awardRecords) = mining.getUserInfo(initialInviter);
//         assertEq(_award, 1000e18 * 10 / 100);
//         assertEq(_invitees.length, 1);
//         assertEq(_awardRecords.length, 1);

//         //award record
//         assertEq(_awardRecords[0].stakingAmount, 1000e18);
//         assertEq(_awardRecords[0].awardAmount, 1000e18 * 10 / 100);
//         assertEq(_awardRecords[0].invitee, user);
//         assertEq(_awardRecords[0].isLevelAward, false);
//         assertEq(_awardRecords[0].awardTime, block.timestamp);

//     }

//     function test_getOrderRealTimeYield() public {
//         test_staking_for_specify(user, 1000e18);

//         vm.warp(block.timestamp + 1 days);
//         uint256 _realTimeYield = mining.getOrderRealTimeYield(0);
//         uint256 _expectedYield = uint256(1300e18) / 30 days * 1 days;
//         assertEq(_realTimeYield, _expectedYield);

//         vm.warp(block.timestamp + 29 days);
//         uint256 _realTimeYield30 = mining.getOrderRealTimeYield(0);
//         assertEq(_realTimeYield30, 1300e18);
//     }

//     function test_claim() public{
//         test_staking_for_specify(user, 1000e18);
//         vm.warp(block.timestamp + 30 days);

//         vm.startPrank(user);
//         mining.claimOrder(0);
//         (,,,,uint256[] memory _validOrderIndexes,uint256[] memory _orderIndexes,,) = mining.getUserInfo(user);
//         assertEq(_validOrderIndexes.length, 0);
//         assertEq(_orderIndexes.length, 1);
//         assertEq(token.balanceOf(user), 1300e18);
//         vm.expectRevert(bytes("Already claimed."));
//         mining.claimOrder(0);
//         vm.stopPrank();
//     }

//     //测试多层奖励
//     function test_staking_no_hierarchy_award() public {

//         uint256 amount = 1000e18;
//         uint256 amountUser = 1e18;
//         address user1 = vm.addr(0x6);
//         address user2 = vm.addr(0x7);
//         address user3 = vm.addr(0x8);
//         address user4 = vm.addr(0x9);
//         address user5 = vm.addr(0x10);
//         address user6 = vm.addr(0x11);
//         address user7 = vm.addr(0x12);
//         address user8 = vm.addr(0x13);
//         test_transfer(initialRecipient, initialInviter, amount);
//         test_transfer(initialRecipient, user1, amount);
//         test_transfer(initialRecipient, user2, amount);
//         test_transfer(initialRecipient, user3, amount);
//         test_transfer(initialRecipient, user4, amount);
//         test_transfer(initialRecipient, user5, amountUser);
//         test_transfer(initialRecipient, user6, amountUser);
//         test_transfer(initialRecipient, user7, amountUser);
//         test_transfer(initialRecipient, user8, amountUser);

        

//         test_bindInviter(user, initialInviter);
//         test_bindInviter(user1, user);
//         test_bindInviter(user2, user1);
//         test_bindInviter(user3, user2);
//         test_bindInviter(user4, user3);

//         test_bindInviter(user5, initialInviter);
//         test_bindInviter(user6, initialInviter);
//         test_bindInviter(user7, initialInviter);
//         test_bindInviter(user8, initialInviter);


//         test_staking_for_specify(initialInviter, amount);
//         test_staking_for_specify(user, amount);
//         test_staking_for_specify(user5, amountUser);
//         test_staking_for_specify(user6, amountUser);
//         test_staking_for_specify(user7, amountUser);
//         test_staking_for_specify(user8, amountUser);
//         // 194 150000000000000000
//         // 969 150000000000000000
//         test_staking_for_specify(user1, amount);
//         test_staking_for_specify(user2, amount);
//         test_staking_for_specify(user3, amount);
//         test_staking_for_specify(user4, amount);
        
//         (,,,,,,address[] memory _invitees,AwardRecord[] memory _awardRecords) = mining.getUserInfo(initialInviter);
//         // assertEq(expectedInitialInviter, _awardInitialInviter);
//         assertEq(_awardRecords.length, 9);
//         assertEq(_invitees.length, 5);
        
//     }



//     //测试级别奖励
//     function test_staking_level() public {
//         address user9 = vm.addr(0x14);
//         address user10 = vm.addr(0x15);
        
//         test_transfer(initialRecipient, user9, 10000e18);
//         test_transfer(initialRecipient, user10, 10000e18);
        

//         test_bindInviter(user9, initialInviter);
//         test_bindInviter(user10, user9);
        
//         test_staking_for_specify(user9, 10000e18);
//         (,uint256 awardAfterUser9,uint256 usdtValue,Level level,,,,AwardRecord[] memory _awardRecordsAfterUser9) = mining.getUserInfo(initialInviter);
//         assertEq(awardAfterUser9, 0);
//         assertEq(usdtValue, 10000e18);
//         assertEq(uint256(level), 1);
//         assertEq(_awardRecordsAfterUser9.length, 0);

//         test_staking_for_specify(user10, 10000e18);
//         (,uint256 awardAfterUser10,,,,,,AwardRecord[] memory _awardRecordsAfterUser10) = mining.getUserInfo(initialInviter);
//         assertEq(awardAfterUser10, 10000e18 * 2 / 1000);
//         assertEq(_awardRecordsAfterUser10.length, 1);
//     }



//     function test_claimAward() public {
//         address user11 = vm.addr(0x16);
//         test_transfer(initialRecipient, initialInviter, 1e18);
//         test_transfer(initialRecipient, user11, 1000e18);
//         test_bindInviter(user11, initialInviter);
//         test_staking_for_specify(initialInviter, 1e18);
//         test_staking_for_specify(user11, 1000e18);


//         vm.startPrank(initialInviter);
//         (,uint256 award,,,,,,) = mining.getUserInfo(initialInviter);
//         assertEq(award, 100e18);
//         mining.claimAward(100e18);
        
//         vm.expectRevert(bytes("No award to claim."));
//         mining.claimAward(50e18);
//         vm.stopPrank();
        
//     }

// }
