// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {CFArt} from "../src/CFArt.sol";
import {CF} from "../src/CF.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTStakingTest is Test{
    NFTStaking public nftStaking;
    CFArt      public cfArt;
    CF         public cf;

    address    owner;
    address    dead;
    address    user;
    address    marketing;

    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        dead = address(0x000000000000000000000000000000000000dEaD);

        owner = vm.addr(1);
        user  = vm.addr(2);
        marketing = vm.addr(3);

        vm.startPrank(owner);
        cfArt = new CFArt();

        cf = new CF(marketing, owner);

        NFTStaking nftStakingImpl = new NFTStaking();
        //deploy proxy of deposit
        ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
            address(nftStakingImpl), 
            abi.encodeCall(
                nftStakingImpl.initialize, 
                (address(cfArt), address(cf), dead)
            ));
        nftStaking = NFTStaking(payable(nftStakingProxy));

        

        vm.stopPrank();
    }

    function test_stake() internal {
        //admin mint nft
        vm.startPrank(owner);
        cfArt.batchMint(user, 2);
        vm.stopPrank();
        //user stake nft
        vm.startPrank(user);
        //approve
        cfArt.setApprovalForAll(address(nftStaking), true);
        //create token id array
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        nftStaking.stakeNFT(tokenIds);
        (uint256[] memory _tokenIds,) = nftStaking.getUserInfo(user);
        assertEq(_tokenIds.length, 2);
        vm.stopPrank();
    }

    function test_unstake() public {
        test_stake();
        vm.startPrank(user);
        nftStaking.unstakeNFT();
        (uint256[] memory _tokenIds,) = nftStaking.getUserInfo(user);
        assertEq(_tokenIds.length, 0);
        vm.stopPrank();
    }

    function test_userIncome() public {
        test_stake();
        vm.startPrank(address(cf));
        nftStaking.updatePool(1e18);
        vm.stopPrank();
        assertEq(nftStaking.getUserIncome(user),1e18);

    }

    function test_claim() public {
        test_stake();
        vm.startPrank(address(cf));
        nftStaking.updatePool(1e18);
        vm.stopPrank();

        vm.startPrank(owner);
        cf.transfer(address(nftStaking),1e18);
        vm.stopPrank();

        vm.startPrank(user);
        nftStaking.claim();
        assertEq(nftStaking.getUserIncome(user),0);
        vm.stopPrank();
    }


    function test_stakeAndStake() public {
        test_stake();

        vm.startPrank(address(cf));
        nftStaking.updatePool(1e18);
        vm.stopPrank();

        vm.startPrank(owner);
        cfArt.batchMint(user, 2);
        vm.stopPrank();

        vm.startPrank(user);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 3;
        tokenIds[1] = 4;
        nftStaking.stakeNFT(tokenIds);
        vm.stopPrank();        

        (uint256[] memory _tokenIds,) = nftStaking.getUserInfo(user);
        assertEq(_tokenIds.length, 4);
        assertEq(nftStaking.getUserIncome(user),1e18);

        vm.startPrank(address(cf));
        nftStaking.updatePool(1e18);
        vm.stopPrank();

        assertEq(nftStaking.getUserIncome(user),2e18);
    }

    function test_claimAndReStake() public {
        test_claim();

        vm.startPrank(owner);
        cfArt.batchMint(user, 2);
        vm.stopPrank();

        vm.startPrank(user);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 3;
        tokenIds[1] = 4;
        nftStaking.stakeNFT(tokenIds);
        vm.stopPrank();          

        vm.startPrank(address(cf));
        nftStaking.updatePool(1e18);
        vm.stopPrank();

        assertEq(nftStaking.getUserIncome(user),1e18);
    }

    function test_unstakeAndReStake() public {
        test_unstake();
        
        vm.startPrank(owner);
        cfArt.batchMint(user, 2);
        vm.stopPrank();

        vm.startPrank(user);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 3;
        tokenIds[1] = 4;
        nftStaking.stakeNFT(tokenIds);
        vm.stopPrank();  

        assertEq(nftStaking.getUserIncome(user),0);

        vm.startPrank(address(cf));
        nftStaking.updatePool(1e18);
        vm.stopPrank();
        console.log("current perStakingReward:",nftStaking.perStakingReward());
        assertEq(nftStaking.getUserIncome(user),1e18);
    }

    function test_maxReward() public {
        test_claim();

        vm.startPrank(owner);
        cfArt.batchMint(user, 2);
        vm.stopPrank();

        vm.startPrank(user);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 3;
        tokenIds[1] = 4;
        nftStaking.stakeNFT(tokenIds);
        vm.stopPrank();  
        
        vm.startPrank(address(cf));
        nftStaking.updatePool(1000000000000e18);
        vm.stopPrank();
        console.log("User income:",nftStaking.getUserIncome(user));
        // assertEq(nftStaking.getUserIncome(user),5999e18);
    }



}