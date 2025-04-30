// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Mining} from "../src/Mining.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IMining} from "../src/interfaces/IMining.sol";

contract MiningTest is Test, IMining{
    Token public token;
    Mining public mining;

    address public owner;
    address public initialRecipient;
    address public initialInviter;
    address public exceedTaxWallet;
    address public user;
    address public usdt;
    address public uniswapV2Router;

    uint256 mainnetFork;

    function setUp() public {

        mainnetFork = vm.createFork(vm.envString("RPC_URL"));
        vm.selectFork(mainnetFork);

        // init address
        {
            owner = address(0x1);
            initialRecipient = address(0x2);
            initialInviter = address(0x3);
            exceedTaxWallet = address(0x1111);
            user = address(0x4);
            usdt = address(0x55d398326f99059fF775485246999027B3197955);
            uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        }

        vm.startPrank(owner);
        // deploy token
        token = new Token("TEST", "TES", initialRecipient, exceedTaxWallet);
        // deploy mining
        {
            Mining miningImpl = new Mining();
            //deploy proxy of staking
            ERC1967Proxy miningProxy = new ERC1967Proxy(
                address(miningImpl), 
                abi.encodeCall(
                    miningImpl.initialize, 
                    (address(token), token.pancakePair(), initialInviter)
                )
            );
            mining = Mining(payable(address(miningProxy))); 
        }
        token.setMining(address(mining));
        vm.stopPrank();
        vm.startPrank(initialRecipient);
        token.transfer(user, 1000e18);
        vm.stopPrank();
        addLiquidity();
    }

    function addLiquidity() internal {
        vm.startPrank(initialRecipient);
        deal(usdt, initialRecipient, 10000000e18);
        token.approve(uniswapV2Router, 10000000e18);
        IERC20(usdt).approve(uniswapV2Router, 10000000e18);
        
        IUniswapV2Router02(uniswapV2Router).addLiquidity(
            usdt, 
            address(token), 
            10000000e18, 
            10000000e18, 
            0, 
            0, 
            initialRecipient, 
            block.timestamp + 10
        );
        vm.stopPrank();

        assertEq(token.balanceOf(token.pancakePair()), 10000000e18);
    }

    function test_bindInviter() public{
        vm.startPrank(user);
        mining.bindInviter(initialInviter);
        vm.stopPrank();
        
        (address _inviter,,,,,,,) = mining.getUserInfo(user);
        assertEq(_inviter, initialInviter);
    }

    function test_staking() public {
        test_bindInviter();
        vm.startPrank(user);
        token.approve(address(mining), 1000e18);
        mining.staking(1000e18);
        vm.stopPrank();
        //assert order index
        (,,,,uint256[] memory _validOrderIndexes,uint256[] memory _orderIndexes,,) = mining.getUserInfo(user);
        assertEq(_validOrderIndexes.length, 1);
        assertEq(_orderIndexes.length, 1);
        assertEq(mining.getStakingOrders().length,1);
        //assert order info
        (address holder, uint256 amount, uint256 stakingTime, bool isExtracted) = mining.stakingOrderInfo(0);
        assertEq(holder, user);
        assertEq(amount, 1000e18);
        assertEq(stakingTime, block.timestamp);
        assertEq(isExtracted, false);
        //assert inviter award
        (,uint256 _award,,,,,address[] memory _invitees,AwardRecord[] memory _awardRecords) = mining.getUserInfo(initialInviter);
        assertEq(_award, 1000e18 * 10 / 100);
        assertEq(_invitees.length, 1);
        assertEq(_awardRecords.length, 1);
        //award record
        assertEq(_awardRecords[0].stakingAmount, 1000e18);
        assertEq(_awardRecords[0].awardAmount, 1000e18 * 10 / 100);
        assertEq(_awardRecords[0].invitee, user);
        assertEq(_awardRecords[0].isLevelAward, false);
        assertEq(_awardRecords[0].awardTime, block.timestamp);
    }

    function test_getOrderRealTimeYield() public {
        test_staking();
        vm.warp(block.timestamp + 1 days);
        (uint256 _realTimeYield) = mining.getOrderRealTimeYield(0);
        uint256 _expectedYield = uint256(1300e18) / 30 days * 1 days;
        assertEq(_realTimeYield, _expectedYield);

        vm.warp(block.timestamp + 29 days);
        (uint256 _realTimeYield30) = mining.getOrderRealTimeYield(0);
        assertEq(_realTimeYield30, 1300e18);
    }

    function test_claim() public{
        test_staking();
        vm.startPrank(user);
        vm.warp(block.timestamp + 30 days);
        mining.claimOrder(0);
        (,,,,uint256[] memory _validOrderIndexes,uint256[] memory _orderIndexes,,) = mining.getUserInfo(user);
        assertEq(_validOrderIndexes.length, 0);
        assertEq(_orderIndexes.length, 1);
        assertEq(token.balanceOf(user), 1300e18);
        vm.expectRevert(bytes("Already claimed."));
        mining.claimOrder(0);
        vm.stopPrank();
    }

    function staking(address _user, uint256 amount) internal{
        vm.startPrank(_user);
        token.approve(address(mining), amount);
        mining.staking(amount);
        vm.stopPrank();
    }

    function bindInviter(address _user, address _inviter0) internal{
        vm.startPrank(_user);
        mining.bindInviter(_inviter0);
        vm.stopPrank();
        (address _inviter,,,,,,,) = mining.getUserInfo(_user);
        assertEq(_inviter, _inviter0);
    }

    //测试多层奖励
    function test_staking_no_hierarchy_award() public {
        address user1 = address(0x5);

        //user bind inviter and staking
        bindInviter(user, initialInviter);
        staking(user, 1000e18);

        vm.startPrank(initialRecipient);
        token.transfer(user1, 1000e18);
        vm.stopPrank();

        //user bind inviter and staking
        bindInviter(user1, user);
        staking(user1, 1000e18);

        (,uint256 _award,,,,,address[] memory _invitees,AwardRecord[] memory _awardRecords) = mining.getUserInfo(initialInviter);
        assertEq(_award, 1000e18 * 10 / 100);
        assertEq(_invitees.length, 1);
        assertEq(_invitees[0], user);
        assertEq(_awardRecords.length, 1);

    }

    function test_staking_with_hierarchy_award() public {
        address initialInviter0 = vm.addr(0x5);
        address initialInviter1 = vm.addr(0x6);
        address initialInviter2 = vm.addr(0x7);
        address initialInviter3 = vm.addr(0x8);
        address initialInviter4 = vm.addr(0x9);

        address user0 = vm.addr(0xA);
        address user1 = vm.addr(0xB);
        address user2 = vm.addr(0xC);
        address user3 = vm.addr(0xD);


        vm.startPrank(initialRecipient);
        token.transfer(initialInviter0, 1000e18);
        token.transfer(initialInviter1, 1000e18);
        token.transfer(initialInviter2, 1000e18);
        token.transfer(initialInviter3, 1000e18);
        token.transfer(initialInviter4, 1000e18);
        token.transfer(user0, 1000e18);
        token.transfer(user1, 1000e18);
        token.transfer(user2, 1000e18);
        token.transfer(user3, 1000e18);

        vm.stopPrank();

        //满足initialInviter邀请5个人的要求
        bindInviter(initialInviter0, initialInviter);
        bindInviter(initialInviter1, initialInviter);
        bindInviter(initialInviter2, initialInviter);
        bindInviter(initialInviter3, initialInviter);
        bindInviter(initialInviter4, initialInviter);
        (,,,,,,address[] memory _invitees,) = mining.getUserInfo(initialInviter);
        assertEq(_invitees.length, 0);
        staking(initialInviter0, 1000e18);
        staking(initialInviter1, 1000e18);
        staking(initialInviter2, 1000e18);
        staking(initialInviter3, 1000e18);
        staking(initialInviter4, 1000e18);
        (,,,,,,address[] memory _invitees0,) = mining.getUserInfo(initialInviter);
        assertEq(_invitees0.length, 5);
        (,uint256 award,,,,,,) = mining.getUserInfo(initialInviter);
        assertEq(award, 5000e18 * 10 / 100);

        //测试层级奖励
        bindInviter(user0, initialInviter);
        staking(user0, 1000e18);
        (,uint256 awardUser0,,,,,address[] memory _inviteesUser0,) = mining.getUserInfo(initialInviter);
        assertEq(_inviteesUser0.length, 6);
        assertEq(awardUser0, 6000e18 * 10 / 100);

        bindInviter(user1, user0);
        staking(user1, 1000e18);
        (,uint256 awardUser1,,,,,address[] memory _inviteesUser1,) = mining.getUserInfo(initialInviter);
        assertEq(_inviteesUser1.length, 6);
        uint256 awardAfterUser1 = 6000e18 * 10 / 100 + 1000e18 * 5 / 100;
        assertEq(awardUser1, awardAfterUser1);

        bindInviter(user2, user1);
        staking(user2, 1000e18);
        (,uint256 awardUser2,,,,,,) = mining.getUserInfo(initialInviter);
        uint256 awardAfterUser2 = awardAfterUser1 + 1000e18 * 25 / 1000;
        assertEq(awardUser2, awardAfterUser2);


        bindInviter(user3, user2);
        staking(user3, 1000e18);
        (,uint256 awardUser3,,,,,,) = mining.getUserInfo(initialInviter);
        // console.log("level", uint256(level));
        uint256 awardAfterUser3 = awardAfterUser2 + 1000e18 * 125 / 10000;
        assertEq(awardUser3, awardAfterUser3);
        
    }


    //测试级别奖励
    function test_staking_level() public {
        test_staking_with_hierarchy_award();

        address user4 = vm.addr(0xF);
        address user5 = vm.addr(0x10);

        vm.startPrank(initialRecipient);
        token.transfer(user4, 1000e18);
        token.transfer(user5, 1000e18);
        vm.stopPrank();
        
        bindInviter(user4, initialInviter);
        staking(user4, 1000e18);
        (,uint256 awardUser4,,Level levelAfterUser4,,,,) = mining.getUserInfo(initialInviter);
        console.log("levelAfterUser4", uint256(levelAfterUser4));
        (,,uint256 usdtValueAfter4,) = mining.userInfo(initialInviter);
        console.log("usdtValue after user4", usdtValueAfter4);
        // console.log("inviteeAfterUser4", inviteeAfterUser4.length);
        uint256 awardAfterUser1 = 1000e18 * 5 / 100;
        uint256 awardAfterUser2 = 1000e18 * 25 / 1000;
        uint256 awardAfterUser3 = 1000e18 * 125 / 10000;
        uint256 levelAwardAfter4 = 7000e18 * 10 / 100 + awardAfterUser1 + awardAfterUser2 + awardAfterUser3;
        assertEq(awardUser4, levelAwardAfter4);

        bindInviter(user5, initialInviter);
        staking(user5, 1000e18);
        (,uint256 awardUser5,,,,,,) = mining.getUserInfo(initialInviter);
 
        uint256 levelAwardAfter5 = levelAwardAfter4 + 1000e18 * 10 / 100 + 1000e18 * 2 / 1000;
        assertEq(awardUser5, levelAwardAfter5);
    }


    function test_staking_levelV1() public {

        address user6 = vm.addr(0x11);
        address user7 = vm.addr(0x12);

        address user8 = vm.addr(0x13);
        address user9 = vm.addr(0x14);
        address user10 = vm.addr(0x15);

        

        vm.startPrank(initialRecipient);
        token.transfer(user6, 10000e18);
        token.transfer(user7, 1000e18);
        token.transfer(user8, 10000e18);
        token.transfer(user9, 1000e18);
        token.transfer(user10, 1000e18);

        vm.stopPrank();

        bindInviter(user6, initialInviter);
        staking(user6, 10000e18);
        bindInviter(user7, initialInviter);
        staking(user7, 1000e18);
        (,uint256 awardUser7,,Level levelAfterUser7,,,,) = mining.getUserInfo(initialInviter);
        assertEq(uint256(levelAfterUser7), 1);
        assertEq(awardUser7, 11000e18 * 10 / 100 + 1000e18 * 2 / 1000);
        console.log("Award After User7", awardUser7);
        //1102        

        bindInviter(user8, user6);
        staking(user8, 10000e18);
        (,uint256 awardUser8,,,,,,) = mining.getUserInfo(initialInviter);
        console.log("Award After User8", awardUser8);
        //1622


        bindInviter(user9, user6);
        staking(user9, 1000e18);
        (,uint256 awardUser9,,Level levelOfInitialInviter,,,,) = mining.getUserInfo(initialInviter);
        console.log("Award After User9", awardUser9);
        console.log("LevelOfInitialInviter", uint256(levelOfInitialInviter));
        (,uint256 awardUser9ToUser6,,Level levelAfterUser9,,,,) = mining.getUserInfo(user6);
        assertEq(uint256(levelAfterUser9), 1);
        assertEq(awardUser9ToUser6, 11000e18 * 10 / 100 + 1000e18 * 2 / 1000);
        console.log("Award After User9 To User6", awardUser9ToUser6);
        //1672
       
        bindInviter(user10, user6);
        staking(user10, 1000e18);
        (,uint256 awardUser10,,,,,,) = mining.getUserInfo(user6);
        uint256 awardAfterUser10ToUser6 = 12000e18 * 10 / 100 + 1000e18 * 4 / 1000;
        assertEq(awardUser10, awardAfterUser10ToUser6);
        
        (,uint256 awardUser10ToInitialInviter,,,,,,) = mining.getUserInfo(initialInviter);
        console.log("Award After User10 To InitialInviter", awardUser10ToInitialInviter);

    }

    function test_staking_levelV2() public {

        address user11 = vm.addr(0x16);
        address user12 = vm.addr(0x17);

        address user13 = vm.addr(0x18);
        address user14 = vm.addr(0x19);

        vm.startPrank(initialRecipient);
        token.transfer(user11, 50000e18);
        token.transfer(user12, 1000e18);
        token.transfer(user13, 10000e18);
        token.transfer(user14, 1000e18);
        vm.stopPrank();

        bindInviter(user11, initialInviter);
        staking(user11, 50000e18);
        bindInviter(user12, initialInviter);
        staking(user12, 1000e18);
        (,uint256 awardUser12,,Level levelAfterUser12,,,,) = mining.getUserInfo(initialInviter);
        assertEq(uint256(levelAfterUser12), 2);
        uint256 awardAfterUser12ToInitialInviter = 51000e18 * 10 / 100 + 1000e18 * 4 / 1000;
        assertEq(awardUser12, awardAfterUser12ToInitialInviter);


        bindInviter(user13, user11);
        staking(user13, 10000e18);
        (,uint256 awardUser13,,,,,,) = mining.getUserInfo(initialInviter);
        uint256 awardAfterUser13ToInitialInviter = awardAfterUser12ToInitialInviter + 10000e18 * 4 / 1000 + 10000e18 * 5 / 100;
        assertEq(awardUser13, awardAfterUser13ToInitialInviter);
        console.log("Award to initialInviter after user13:",awardUser13);

        (,,,Level userLevel,,,,) = mining.getUserInfo(user11);
        console.log("user level", uint256(userLevel));
       
        bindInviter(user14, user11);
        staking(user14, 1000e18);
        uint256 awardAfterUser14ToInitialInviter = awardAfterUser13ToInitialInviter + 1000e18 * 2 / 1000 + 1000e18 * 5 / 100;
        (,uint256 awardUser14,,,,,,) = mining.getUserInfo(initialInviter);
        assertEq(awardUser14, awardAfterUser14ToInitialInviter);
        console.log("Award to initialInviter after user14:",awardUser14);


        (,uint256 awardUser14ToUser11,,,,,,) = mining.getUserInfo(user11);
        assertEq(awardUser14ToUser11, 11000e18 * 10 / 100 + 1000e18 * 2 / 1000);

    }

    function test_claimAward() public {
        address user15 = vm.addr(0x1A);
        vm.startPrank(initialRecipient);
        token.transfer(user15, 1000e18);
        vm.stopPrank();

        bindInviter(user15, initialInviter);
        staking(user15, 1000e18);

        vm.startPrank(initialInviter);
        mining.claimAward(50e18);
        (,uint256 award,,,,,,) = mining.getUserInfo(initialInviter);
        assertEq(award, 50e18);
        mining.claimAward(50e18);

        vm.expectRevert(bytes("No award to claim."));
        mining.claimAward(50e18);
        vm.stopPrank();
        
    }

}
