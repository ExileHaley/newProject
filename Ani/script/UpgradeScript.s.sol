// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract UpgradeScript is Script {
    Staking public staking;

    function setUp() public {
        staking = Staking(payable(0xE4000b57f1f6350ba62F628A8845FACF6Af50dC8));
    }

    function run() public {
        vm.startBroadcast();

        Staking stakingImpl = new Staking();
        bytes memory data= "";
        staking.upgradeToAndCall(address(stakingImpl), data);
        staking.setPerTokenPerSecondFP();
        vm.stopBroadcast();

    }
}