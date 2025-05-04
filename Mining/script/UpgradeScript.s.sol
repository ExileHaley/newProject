// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Mining} from "../src/Mining.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    Mining public mining;

    function setUp() public {
        mining = Mining(payable(0x75a79Ef6bb812af0FA8a59b40EBcdFc05cB4c092));
    }

    function run() public {
        vm.startBroadcast();

        Mining miningImpl = new Mining();
        bytes memory data= "";
        mining.upgradeToAndCall(address(miningImpl), data);
        vm.stopBroadcast();
        

    }
}
