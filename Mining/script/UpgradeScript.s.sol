// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MiningV1} from "../src/MiningV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    MiningV1 public miningV1;

    function setUp() public {
        miningV1 = MiningV1(payable(0xA30D078dF0189Ae87B70c635b49424eb5525F031));
    }

    function run() public {
        vm.startBroadcast();

        MiningV1 miningV1Impl = new MiningV1();
        bytes memory data= "";
        miningV1.upgradeToAndCall(address(miningV1Impl), data);
        vm.stopBroadcast();
        

    }
}
