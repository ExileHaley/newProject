// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    Regulation public regulation;

    address admin;
    address recipient;
    address token;


    function setUp() public {
        //更换
        admin = address(0x31C6820aa9066387d83A6607C6E6FD510904b72F);

        token = address(0xF7d6243b937136d432AdBc643f311b5A9436b0B0);
        recipient = address(0xA5a28c00f8caCe967C2737ddFb1101Ee951B7d36);
    }

    function run() public {
        vm.startBroadcast();

        // 部署实现合约
        Regulation regulationImpl = new Regulation();

        // 使用ERC1967代理合约
        ERC1967Proxy regulationProxy = new ERC1967Proxy(
            address(regulationImpl), 
            abi.encodeCall(regulationImpl.initialize, (admin, token, recipient))
        );

        // 将代理合约实例化为Regulation
        regulation = Regulation(payable(regulationProxy));


        vm.stopBroadcast();
        // 输出部署地址
        
        console.log("Regulation:", address(regulation));
        console.log("TestERC20:", address(testERC20));
    }

}
