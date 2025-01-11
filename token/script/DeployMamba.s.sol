// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Mamba} from "../src/Mamba.sol";

contract DeployMamba is Script {
    Mamba public mamba;
    address marketing;
    address initialRecipient;
    address[] whites = [0xF5b6eFEB8A0CB3b2c4dA8A8F99eDD4AAFe8580ca];

    function setUp() public {
        marketing = 0xb91DfBfCA5E480634c38bBb0552Bb56431F21913;
        initialRecipient = 0xF5b6eFEB8A0CB3b2c4dA8A8F99eDD4AAFe8580ca;
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
