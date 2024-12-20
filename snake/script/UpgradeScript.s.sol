// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Regulation public regulation;

    function setUp() public {
        //更新时作替换
        regulation = Regulation(payable(0xb7Ab1AA41C938F6c0a93c734743acD446757bc5a));
    }

    function run() public{
        vm.startBroadcast();
        Regulation regulationImpl = new Regulation();
        bytes memory data= "";
        regulation.upgradeToAndCall(address(regulationImpl), data);
        vm.stopBroadcast();
    }
}

