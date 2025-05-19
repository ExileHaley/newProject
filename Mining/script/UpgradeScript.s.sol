// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MiningV2} from "../src/MiningV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    MiningV2 public miningV2;

    function setUp() public {
        miningV2 = MiningV2(payable(0xFd5200423B254Ee2b2DCb58208CDAC62361fAF65));
    }

    function run() public {
        vm.startBroadcast();

        MiningV2 miningV2Impl = new MiningV2();
        bytes memory data= "";
        miningV2.upgradeToAndCall(address(miningV2Impl), data);
        vm.stopBroadcast();
        

    }
}
