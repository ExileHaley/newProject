// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Mamba} from "../src/Mamba.sol";

contract DeployMamba is Script {
    Mamba public mamba;
    address marketing;
    address initialRecipient;
    address[] whites = [0x000000000000000000000000000000000000dEaD];

    function setUp() public {
        marketing = 0x000000000000000000000000000000000000dEaD;
        initialRecipient = 0x000000000000000000000000000000000000dEaD;
    }

    function run() public {
        vm.startBroadcast();

        mamba = new Mamba(marketing, initialRecipient);

        for(uint i=0; i<whites.length; i++){
            mamba.setTaxExemption(whites[i], true);
        }

        vm.stopBroadcast();
        console.log("Mamba address:", address(mamba));
        console.log("Pancake pair address:", mamba.pancakePair());
    }
}
