// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {Mining} from "../src/Mining.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployScript is Script {
    Token public token;
    Mining public mining;

    address public initialRecipient;
    address public exceedTaxWallet;

    function setUp() public {
        // token = Token();
        initialRecipient = address(0xdd62810b86c7b0cA2C1C219DA7B3bB1Fc49bAb3C);
        exceedTaxWallet = address(0x31b33Ce446A54a5DC4BbfB253861bA3bb485dA97);
    }

    function run() public {
        vm.startBroadcast();

        token = new Token("SMT","SMT", initialRecipient, exceedTaxWallet);

        // deploy mining
        {
            Mining miningImpl = new Mining();
            //deploy proxy of staking
            ERC1967Proxy miningProxy = new ERC1967Proxy(
                address(miningImpl), 
                abi.encodeCall(
                    miningImpl.initialize, 
                    (address(token), token.pancakePair())
                )
            );
            mining = Mining(payable(address(miningProxy))); 
        }

        token.setMining(address(mining));

        vm.stopBroadcast();
        
        console.log("token address: ", address(token));
        console.log("lp address: ", token.pancakePair());
        console.log("mining address: ", address(mining));
    }


}
