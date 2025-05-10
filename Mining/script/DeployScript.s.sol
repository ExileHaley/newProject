// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {MiningV2} from "../src/MiningV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployScript is Script {
    Token public token;
    MiningV2 public miningV2;

    address public initialRecipient;
    address public exceedTaxWallet;
    address public permit;
    address public usdtRecipient;

    function setUp() public {
        // token = Token();
        initialRecipient = address(0xdd62810b86c7b0cA2C1C219DA7B3bB1Fc49bAb3C);
        exceedTaxWallet = address(0x31b33Ce446A54a5DC4BbfB253861bA3bb485dA97);
        permit = address(0xCD6464332A1AB9e5bcBF069cC9FaF63056BA6dD0);
        //注意
        usdtRecipient = address(0xF5b6eFEB8A0CB3b2c4dA8A8F99eDD4AAFe8580ca);
    }

    function run() public {
        vm.startBroadcast();

        token = new Token("SMT","SMT", initialRecipient, exceedTaxWallet);

        // deploy mining
        {
            MiningV2 miningV2Impl = new MiningV2();
            //deploy proxy of staking
            ERC1967Proxy miningV2Proxy = new ERC1967Proxy(
                address(miningV2Impl), 
                abi.encodeCall(
                    miningV2Impl.initialize, 
                    (address(token), token.pancakePair(), permit, usdtRecipient)
                )
            );
            miningV2 = MiningV2(payable(address(miningV2Proxy))); 
        }

        token.setMining(address(miningV2));

        vm.stopBroadcast();
        
        console.log("token address: ", address(token));
        console.log("lp address: ", token.pancakePair());
        console.log("mining address: ", address(miningV2));
    }


}
