// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CF} from "../src/CF.sol";
contract DeployCf is Script {
    CF      public cf;
    address recipient;
    address tokenRecipient;
    address regulation;
    address marketing;
    
    function setUp() public {
        tokenRecipient = address(0x50a67E10075Ccb0899Ddb00f8ACe00A30cAEb1b6);
        recipient = address(0xCc946894c70469Af085669ccB7Ab8EA21ecA6d47);
        marketing = address(0xCc946894c70469Af085669ccB7Ab8EA21ecA6d47);
        regulation = address(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0);
    }

    function run() public {
        vm.startBroadcast();
        cf = new CF(marketing, regulation, tokenRecipient);
        vm.stopBroadcast();
        // 输出部署地址
        console.log("CF Token:",address(cf));
    }
}