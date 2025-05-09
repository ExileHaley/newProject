// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {Token} from "../src/Token.sol";
// import {MiningV1} from "../src/MiningV1.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
// import {IMiningV1} from "../src/interfaces/IMiningV1.sol";

// contract MiningV1Test is Test, IMiningV1{
//     Token public token;
//     MiningV1 public miningV1;

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
//             MiningV1 miningV1Impl = new MiningV1();
//             //deploy proxy of staking
//             ERC1967Proxy miningV1Proxy = new ERC1967Proxy(
//                 address(miningV1Impl), 
//                 abi.encodeCall(
//                     miningV1Impl.initialize, 
//                     (address(token), token.pancakePair())
//                 )
//             );
//             miningV1 = MiningV1(payable(address(miningV1Proxy))); 
//         }
//         // token.setMining(address(mining));
//         vm.stopPrank();

//         // vm.startPrank(initialRecipient);
//         // token.transfer(user, 1000e18);
//         // vm.stopPrank();

//         // addLiquidity();
//     }

//     function test_miningV1_transfer(address sender, address recipient, uint256 amount) internal{
//         vm.startPrank(sender);
//         token.transfer(recipient, amount);
//         vm.stopPrank();
//     }

//     function test_miningV1_bindInviter(address _user, address _inviter) internal{
//         vm.startPrank(_user);
//         miningV1.bindInviter(_inviter);
//         vm.stopPrank();
//     }

//     function test_miningV1_staking_for_specify(address _user, uint256 _amount) internal{
//         vm.startPrank(_user);
//         token.approve(address(miningV1), _amount);
//         miningV1.staking(_amount);
//         vm.stopPrank();
//     }

//     function test_miningV1_staking_reward() public {
//         test_miningV1_transfer(initialRecipient, initialInviter, 1e18);
//         test_miningV1_bindInviter(user, initialInviter);
//         test_miningV1_transfer(initialRecipient, user, 1000e18);

//         test_miningV1_staking_for_specify(initialInviter, 1e18);
//         test_miningV1_staking_for_specify(user, 1000e18);

//         address _inviter = miningV1.inviter(user);
//         uint256 _award = miningV1.award(initialInviter);
//         assertEq(_inviter, initialInviter);
//         assertEq(_award, 1000e18 * 10 / 100);
//     }

//     //测试多层奖励
//     function test_miningV1_staking_hierarchy_award() public {

//         uint256 amount = 1000e18;
//         uint256 amountUser = 1e18;
//         address user1 = address(0x6);
//         address user2 = address(0x7);
//         address user3 = address(0x8);
//         address user4 = address(0x9);
//         address user5 = address(0x10);
//         address user6 = address(0x11);
//         address user7 = address(0x12);
//         address user8 = address(0x13);

//         test_miningV1_transfer(initialRecipient, initialInviter, amount);
//         test_miningV1_transfer(initialRecipient, user, amount);
//         test_miningV1_transfer(initialRecipient, user1, amount);
//         test_miningV1_transfer(initialRecipient, user2, amount);
//         test_miningV1_transfer(initialRecipient, user3, amount);
//         test_miningV1_transfer(initialRecipient, user4, amount);
//         test_miningV1_transfer(initialRecipient, user5, amountUser);
//         test_miningV1_transfer(initialRecipient, user6, amountUser);
//         test_miningV1_transfer(initialRecipient, user7, amountUser);
//         test_miningV1_transfer(initialRecipient, user8, amountUser);

        

//         test_miningV1_bindInviter(user, initialInviter);
//         test_miningV1_bindInviter(user1, user);
//         test_miningV1_bindInviter(user2, user1);
//         test_miningV1_bindInviter(user3, user2);
//         test_miningV1_bindInviter(user4, user3);

//         test_miningV1_bindInviter(user5, initialInviter);
//         test_miningV1_bindInviter(user6, initialInviter);
//         test_miningV1_bindInviter(user7, initialInviter);
//         test_miningV1_bindInviter(user8, initialInviter);


//         test_miningV1_staking_for_specify(initialInviter, amount);
//         test_miningV1_staking_for_specify(user, amount);
//         test_miningV1_staking_for_specify(user5, amountUser);
//         test_miningV1_staking_for_specify(user6, amountUser);
//         test_miningV1_staking_for_specify(user7, amountUser);
//         test_miningV1_staking_for_specify(user8, amountUser);

//         test_miningV1_staking_for_specify(user1, amount);
//         test_miningV1_staking_for_specify(user2, amount);
//         test_miningV1_staking_for_specify(user3, amount);
//         test_miningV1_staking_for_specify(user4, amount);
        

//         // (,,,,,,address[] memory _invitees,AwardRecord[] memory _awardRecords) = miningV1.getUserInfo(initialInviter);
//         // assertEq(_awardRecords.length, 9);
//         // assertEq(_invitees.length, 5);
        
//     }

//     function test_miningV1_staking_level() public {
//         address user9 = address(0x14);
//         address user10 = address(0x15);
        
//         test_miningV1_transfer(initialRecipient, user9, 10000e18);
//         test_miningV1_transfer(initialRecipient, user10, 10000e18);
        

//         test_miningV1_bindInviter(user9, initialInviter);
//         test_miningV1_bindInviter(user10, user9);
        
//         test_miningV1_staking_for_specify(user9, 10000e18);

//         (,uint256 awardAfterUser9,uint256 usdtValue,Level level,,,) = miningV1.getUserInfo(initialInviter);
//         assertEq(awardAfterUser9, 0);
//         assertEq(usdtValue, 10000e18);
//         assertEq(uint256(level), 1);
//         // assertEq(_awardRecordsAfterUser9.length, 0);

//         test_miningV1_staking_for_specify(user10, 10000e18);
//         (,uint256 awardAfterUser10,,,,,) = miningV1.getUserInfo(initialInviter);
//         assertEq(awardAfterUser10, 10000e18 * 2 / 1000);
//         // assertEq(_awardRecordsAfterUser10.length, 1);
//     }


// }

