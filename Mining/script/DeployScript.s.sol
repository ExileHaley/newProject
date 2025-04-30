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
    address public initialInviter;
    address public exceedTaxWallet;

    function setUp() public {
// 代币接收地址：0xdd62810b86c7b0cA2C1C219DA7B3bB1Fc49bAb3C
// 手续费超出地址：0x31b33Ce446A54a5DC4BbfB253861bA3bb485dA97
// 初始邀请人地址：0x5E0D2012955cEA355c9efc041c5ec40a6985849b
       
        initialRecipient = address(0xdd62810b86c7b0cA2C1C219DA7B3bB1Fc49bAb3C);
        initialInviter = address(0x5E0D2012955cEA355c9efc041c5ec40a6985849b);
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
                    (address(token), token.pancakePair(), initialInviter)
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
