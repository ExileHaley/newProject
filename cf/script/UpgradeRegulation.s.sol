// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeRegulation is Script {
    Regulation public regulation;
    address cf;


    function setUp() public {
        regulation = Regulation(payable(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0));
        cf = address(0xA8c18Ea63386a0bbA6612A3479b723AFd9Cd02FB);
    }

    function run() public{
        vm.startBroadcast();
        Regulation regulationImpl = new Regulation();
        bytes memory data= "";
        regulation.upgradeToAndCall(address(regulationImpl), data);

        regulation.setCf(cf);
        vm.stopBroadcast();

    }
}
// forge script script/UpgradeRegulation.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=aa207569b21f1b15fd86c93bd7d64519db385f11c460ca7880174059a0532334