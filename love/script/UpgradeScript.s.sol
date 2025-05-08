// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Staking public staking;


    function setUp() public {
        staking = Staking(payable(0xf8886244a8C5eB6002C4f14fB93B10687824017a));
    }

    function run() public {
        vm.startBroadcast();

        Staking stakingImpl = new Staking();
        bytes memory data= "";
        staking.upgradeToAndCall(address(stakingImpl), data);

        vm.stopBroadcast();

    }
}
