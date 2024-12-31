// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {NFTStaking} from "../src/NFTStaking.sol";
// import {CFArt} from "../src/CFArt.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// contract NFTStakingTest is Test{
//     NFTStaking public nftStaking;
//     CFArt      public cfArt;

//     address    usdt;
//     address    admin;
//     address    user;
//     uint256 mainnetFork;

//     function setUp() public {
//         mainnetFork = vm.createFork(vm.envString("rpc_url"));
//         vm.selectFork(mainnetFork);
//         usdt = address(0x55d398326f99059fF775485246999027B3197955);
//         // cftArt = CFArt(0x17d6eE5c3a60f3a42B9c2799B6E27da441a8A2F6);
        

//         admin = vm.addr(1);
//         user  = vm.addr(2);
//         vm.startPrank(admin);

//         cfArt = new CFArt();

//         NFTStaking nftStakingImpl = new NFTStaking();
//         //deploy proxy of deposit
//         ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
//             address(nftStakingImpl), 
//             abi.encodeCall(
//                 nftStakingImpl.initialize, 
//                 (address(cfArt), usdt, admin)
//             ));
//         nftStaking = NFTStaking(payable(nftStakingProxy));
//         // nftStaking.setAddress(_cf, _dead, _uniswapV2Factory);
//         nftStaking.setMultiple(3);
//         vm.stopPrank();
//     }

//     function test_stake() internal {
//         //admin mint nft
//         vm.startPrank(admin);
//         cfArt.batchMint(user, 2);
//         vm.stopPrank();
//         //user stake nft
//         vm.startPrank(user);
//         //approve
//         cfArt.setApprovalForAll(address(nftStaking), true);
//         //create token id array
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 1;
//         tokenIds[1] = 2;
//         nftStaking.stakeNFT(tokenIds);
//         (uint256[] memory _tokenIds,) = nftStaking.getUserInfo(user);
//         assertEq(_tokenIds.length, 2);
//         vm.stopPrank();
//     }

//     function test_unstake() public {
//         test_stake();
//         vm.startPrank(user);
//         nftStaking.unstakeNFT();
//         (uint256[] memory _tokenIds,) = nftStaking.getUserInfo(user);
//         assertEq(_tokenIds.length, 0);
//         vm.stopPrank();
//     }

//     function test_userIncome() public {
//         test_stake();
//         vm.startPrank(admin);
//         nftStaking.updatePool(1e18);
//         vm.stopPrank();
//         assertEq(nftStaking.getUserIncome(user),1e18);

//     }

//     function test_claim() public {
//         test_stake();
//         vm.startPrank(admin);
//         nftStaking.updatePool(1e18);
//         vm.stopPrank();

//         vm.startPrank(user);
//         deal(usdt, address(nftStaking), 1e18);
//         nftStaking.claim();
//         assertEq(nftStaking.getUserIncome(user),0);
//         vm.stopPrank();
//     }


//     function test_stakeAndStake() public {
//         test_stake();

//         vm.startPrank(admin);
//         nftStaking.updatePool(1e18);
//         cfArt.batchMint(user, 2);
//         vm.stopPrank();

//         vm.startPrank(user);
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 3;
//         tokenIds[1] = 4;
//         nftStaking.stakeNFT(tokenIds);
//         vm.stopPrank();        

//         (uint256[] memory _tokenIds,) = nftStaking.getUserInfo(user);
//         assertEq(_tokenIds.length, 4);
//         assertEq(nftStaking.getUserIncome(user),1e18);

//         vm.startPrank(admin);
//         nftStaking.updatePool(1e18);
//         vm.stopPrank();

//         assertEq(nftStaking.getUserIncome(user),2e18);
//     }

//     function test_claimAndReStake() public {
//         test_claim();

//         vm.startPrank(admin);
//         cfArt.batchMint(user, 2);
//         vm.stopPrank();

//         vm.startPrank(user);
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 3;
//         tokenIds[1] = 4;
//         nftStaking.stakeNFT(tokenIds);
//         vm.stopPrank();          

//         vm.startPrank(admin);
//         nftStaking.updatePool(1e18);
//         vm.stopPrank();

//         assertEq(nftStaking.getUserIncome(user),1e18);
//     }

//     function test_unstakeAndReStake() public {
//         test_unstake();
        
//         vm.startPrank(admin);
//         cfArt.batchMint(user, 2);
//         vm.stopPrank();

//         vm.startPrank(user);
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 3;
//         tokenIds[1] = 4;
//         nftStaking.stakeNFT(tokenIds);
//         vm.stopPrank();  

//         assertEq(nftStaking.getUserIncome(user),0);

//         vm.startPrank(admin);
//         nftStaking.updatePool(1e18);
//         vm.stopPrank();
//         console.log("current perStakingReward:",nftStaking.perStakingReward());
//         assertEq(nftStaking.getUserIncome(user),1e18);
//     }

//     function test_maxReward() public {
//         test_claim();

//         vm.startPrank(admin);
//         cfArt.batchMint(user, 2);
//         vm.stopPrank();

//         vm.startPrank(user);
//         uint256[] memory tokenIds = new uint256[](2);
//         tokenIds[0] = 3;
//         tokenIds[1] = 4;
//         nftStaking.stakeNFT(tokenIds);
//         vm.stopPrank();  

//         vm.startPrank(admin);
//         nftStaking.updatePool(60001e18);
//         vm.stopPrank();
//         console.log("User income:",nftStaking.getUserIncome(user));
//         // assertEq(nftStaking.getUserIncome(user),5999e18);
//     }



// }