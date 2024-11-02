// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import {Test, console} from "forge-std/Test.sol";
// import {Regulation} from "../src/Regulation.sol";
// import {IRegulation} from "../src/interface/IRegulation.sol";
// import {SignatureInfo} from "../src/libraries/SignatureInfo.sol";
// import {CFArt} from "../src/CFArt.sol";

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


// contract RegulationTest is Test {
//     Regulation public regulation;
//     address admin;
//     address usdt;
//     uint256 mainnetFork;

//     address SIGNER;
//     uint256 SIGNER_PRIVATE_KEY;

//     function setUp() public {
//         mainnetFork = vm.createFork(vm.envString("rpc_url"));
//         vm.selectFork(mainnetFork);
//         usdt = address(0x55d398326f99059fF775485246999027B3197955);
//         admin = vm.addr(1);
//         SIGNER_PRIVATE_KEY = 0xA11CE;
//         SIGNER = vm.addr(SIGNER_PRIVATE_KEY);

//         vm.startPrank(admin);

//         Regulation regulationImpl = new Regulation();
//         CFArt cfArt = new CFArt();
//         //deploy proxy of deposit
//         ERC1967Proxy regulationProxy = new ERC1967Proxy(
//             address(regulationImpl), 
//             abi.encodeCall(
//                 regulationImpl.initialize, 
//                 (SIGNER, address(cfArt), usdt, SIGNER)
//             ));
//         regulation = Regulation(payable(regulationProxy));
        
//         vm.stopPrank();
//     }

//     function testCanSwitchForks() public view{
//         assertEq(vm.activeFork(), mainnetFork);
//     }

//     function test_deposit() public {
//         address user = vm.addr(2);
//         vm.startPrank(user);
//         deal(usdt, user, 100e18);
//         IERC20(usdt).approve(address(regulation), 100e18);
//         // 预期 Transfer 事件的触发
//         vm.expectEmit(false, false, false, false);
//         emit IRegulation.Recharge("001", "mint", usdt, user, 100e18, block.timestamp);

//         regulation.deposit("001", "mint", usdt, 100e18);
//         assertEq(IERC20(usdt).balanceOf(address(regulation)), 100e18);
//         assertEq(IERC20(usdt).balanceOf(address(user)), 0);
//         vm.stopPrank();
//     }

//     function _prepareSignature(
//         string memory _orderNum,
//         string memory _orderMark,
//         address _token, 
//         address _recipient,
//         uint256 _amount,
//         uint256 _nonce,
//         uint256 _signerPrivateKey
//     ) internal view returns (
//         SignatureInfo.SignMessage memory signMsg, 
//         uint8 v, bytes32 r, bytes32 s) 
//     {
//         // Data content
//         signMsg = SignatureInfo.SignMessage({
//             orderNum: _orderNum,
//             orderMark: _orderMark,
//             token: _token,
//             recipient: _recipient,
//             amount: _amount,
//             nonce: _nonce,
//             deadline: block.timestamp + 60,
//             v: 0,
//             r: bytes32(0),
//             s: bytes32(0)
//         });

//         // Get hash
//         bytes32 signMsgHash = regulation.getSignMsgHash(signMsg);
//         (v, r, s) = vm.sign(_signerPrivateKey, signMsgHash);

//         // Update content
//         signMsg.v = v;
//         signMsg.r = r;
//         signMsg.s = s;
//     }


//     function test_signatureVerification() public view {
//         (SignatureInfo.SignMessage memory signMsg,,,) = _prepareSignature("001", "mint", usdt, admin, 100e18, regulation.nonce(),SIGNER_PRIVATE_KEY); 
//         // Call contract's signature checking function
//         bool isSignatureValid = regulation.checkerSignMsgSignature(signMsg);

//         // Assert signature is valid
//         assertTrue(isSignatureValid, "FAILED_TO_CHECK_SIGNATURE.");
//     }

//     function test_withdrawWithSignature() public {
//         address user1 = vm.addr(3);
//         deal(usdt, address(regulation), 100e18);
//         (SignatureInfo.SignMessage memory signMsg,,,) = _prepareSignature("001", "mint", usdt, user1, 100e18, regulation.nonce(),SIGNER_PRIVATE_KEY);
//         vm.startPrank(user1);

//         vm.expectEmit(false, false, false, false);
//         emit IRegulation.Withdraw("001", "mint", usdt, user1, 100e18, 0, block.timestamp);

//         regulation.withdrawWithSignature(signMsg);
//         assertEq(regulation.nonce(), 1);
//         assertEq(IERC20(usdt).balanceOf(user1), 100e18);
//         assertEq(IERC20(usdt).balanceOf(address(regulation)), 0);
//         vm.stopPrank();
//     }


//     function test_nft() public {
//         vm.startPrank(admin);
//         CFArt cfArt = new CFArt();
//         regulation.setConfig(address(cfArt), usdt, SIGNER);
//         cfArt.setAdmin(address(regulation));
//         vm.stopPrank();
//         address user2 = vm.addr(4);
//         vm.startPrank(user2);
//         deal(usdt, user2, 300e18);
//         IERC20(usdt).approve(address(regulation), 300e18);
//         regulation.mintCfArt("1", 1);
//         assertEq(cfArt.balanceOf(user2), 1);
//         assertEq(cfArt.ownerOf(1),user2);
//         assertEq(IERC20(usdt).balanceOf(SIGNER), 300e18);
//         vm.stopPrank();
//     }
    
//     function test_nfts() public {
//         vm.startPrank(admin);
//         CFArt cfArt = new CFArt();
//         regulation.setConfig(address(cfArt), usdt, SIGNER);
//         cfArt.setAdmin(address(regulation));
//         vm.stopPrank();
//         address user2 = vm.addr(4);
//         vm.startPrank(user2);
//         deal(usdt, user2, 900e18);
//         IERC20(usdt).approve(address(regulation), 900e18);
//         regulation.mintCfArt("mint", 3);
//         assertEq(cfArt.balanceOf(user2), 3);
//         assertEq(cfArt.ownerOf(3),user2);
//         assertEq(IERC20(usdt).balanceOf(SIGNER), 900e18);
//         vm.stopPrank();
//     }

// }