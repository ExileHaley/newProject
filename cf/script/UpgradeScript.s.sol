// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Regulation public regulation;
    address public cfArt;
    address public usdt;
    address public recipient;

    function setUp() public {
        regulation = Regulation(payable(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0));
        cfArt = address(0x14C5DF0fB04b07d63CfC55983A8393D7581907ae);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        recipient = address(0xCc946894c70469Af085669ccB7Ab8EA21ecA6d47);
    }

    function run() public{
        vm.startBroadcast();

        Regulation regulationImpl = new Regulation();
        bytes memory data= "";
        Regulation(payable(regulation)).upgradeToAndCall(address(regulationImpl), data);
        regulation.setConfig(cfArt, usdt, recipient);
        vm.stopBroadcast();
    }
}

