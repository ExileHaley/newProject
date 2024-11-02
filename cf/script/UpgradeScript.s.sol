// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Regulation public regulation;

    function setUp() public {
        regulation = Regulation(payable(0x7863bB375B1b21657378b24Aa361BC9C631E2559));
    }

    function run() public{
        vm.startBroadcast();

        Regulation regulationImpl = new Regulation();
        bytes memory data= "";
        Regulation(payable(regulation)).upgradeToAndCall(address(regulationImpl), data);
        vm.stopBroadcast();
    }
}

