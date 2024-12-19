// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Regulation} from "../src/Regulation.sol";

import {IRegulation} from "../src/interfaces/IRegulation.sol";
import {SignatureInfo} from "../src/libraries/SignatureInfo.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract RegulationTest is Test {
    Regulation public regulation;
    address owner;
    address token;
    address recipient;
    uint256 mainnetFork;

    address ADMIN;
    uint256 ADMIN_PRIVATE_KEY;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("rpc_url"));
        vm.selectFork(mainnetFork);
        recipient = address(0xA5a28c00f8caCe967C2737ddFb1101Ee951B7d36);
        token = address(0xF7d6243b937136d432AdBc643f311b5A9436b0B0);
        owner = vm.addr(1);
        ADMIN_PRIVATE_KEY = 0xA11CE;
        ADMIN = vm.addr(ADMIN_PRIVATE_KEY);

        vm.startPrank(owner);

        Regulation regulationImpl = new Regulation();

        //deploy proxy of deposit
        ERC1967Proxy regulationProxy = new ERC1967Proxy(
            address(regulationImpl), 
            abi.encodeCall(
                regulationImpl.initialize, 
                (ADMIN, token, recipient)
            ));
        regulation = Regulation(payable(regulationProxy));

        vm.stopPrank();

        vm.startPrank(recipient);
        IERC20(token).approve(address(regulation), 1000000000e18);
        vm.stopPrank();
    }

    function testCanSwitchForks() public view{
        assertEq(vm.activeFork(), mainnetFork);
    }

    function test_deposit() public {
        address user = vm.addr(2);
        vm.startPrank(user);
        deal(token, user, 100e18);
        IERC20(token).approve(address(regulation), 100e18);
        // 预期 Transfer 事件的触发
        vm.expectEmit(false, false, false, false);
        emit IRegulation.Recharge("test", token, user, 100e18, block.timestamp);

        regulation.deposit("test", 100e18);

        assertEq(IERC20(token).balanceOf(address(regulation)), 100e18);
        assertEq(IERC20(token).balanceOf(address(user)), 0);

        vm.stopPrank();
    }

    function _prepareSignature(
        string memory _mark,
        address _token, 
        address _recipient,
        uint256 _amount,
        uint256 _nonce,
        uint256 _signerPrivateKey
    ) internal view returns (
        SignatureInfo.SignMessage memory signMsg, 
        uint8 v, bytes32 r, bytes32 s) 
    {
        // Data content
        signMsg = SignatureInfo.SignMessage({
            mark: _mark,
            token: _token,
            recipient: _recipient,
            amount: _amount,
            nonce: _nonce,
            deadline: block.timestamp + 60,
            v: 0,
            r: bytes32(0),
            s: bytes32(0)
        });

        // Get hash
        bytes32 signMsgHash = regulation.getSignMsgHash(signMsg);
        (v, r, s) = vm.sign(_signerPrivateKey, signMsgHash);

        // Update content
        signMsg.v = v;
        signMsg.r = r;
        signMsg.s = s;
    }


    function test_signatureVerification() public view {
        (SignatureInfo.SignMessage memory signMsg,,,) = _prepareSignature("test", token, owner, 100e18, regulation.nonce(),ADMIN_PRIVATE_KEY); 
        // Call contract's signature checking function
        bool isSignatureValid = regulation.checkerSignMsgSignature(signMsg);

        // Assert signature is valid
        assertTrue(isSignatureValid, "FAILED_TO_CHECK_SIGNATURE.");
    }

    function test_withdrawWithSignature() public {
        address user1 = vm.addr(3);
        deal(token, address(regulation), 100e18);
        (SignatureInfo.SignMessage memory signMsg,,,) = _prepareSignature("test", token, user1, 100e18, regulation.nonce(),ADMIN_PRIVATE_KEY);
        vm.startPrank(user1);

        vm.expectEmit(false, false, false, false);
        emit IRegulation.Withdraw("test", token, user1, 100e18, block.timestamp);

        regulation.withdrawWithSignature(signMsg);
        assertEq(regulation.nonce(), 1);
        assertEq(IERC20(token).balanceOf(user1), 100e18);
        assertEq(IERC20(token).balanceOf(address(regulation)), 0);
        vm.stopPrank();
    }

}
