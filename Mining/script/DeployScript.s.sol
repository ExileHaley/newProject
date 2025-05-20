// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenV2} from "../src/TokenV2.sol";
import {MiningV2} from "../src/MiningV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployScript is Script {
    TokenV2 public tokenV2;
    MiningV2 public miningV2;

    // address public initialRecipient;
    // address public exceedTaxWallet;
    address public permit;

    function setUp() public {
        tokenV2 = TokenV2(0xf5869fFf5a90f3e37283e2FE12a818631059AeB6);
        // initialRecipient = address(0xdd62810b86c7b0cA2C1C219DA7B3bB1Fc49bAb3C);
        // exceedTaxWallet = address(0x31b33Ce446A54a5DC4BbfB253861bA3bb485dA97);
        permit = address(0xCD6464332A1AB9e5bcBF069cC9FaF63056BA6dD0);
    }

    function run() public {
        vm.startBroadcast();

        // tokenV2 = new TokenV2("SMT","SMT", initialRecipient, exceedTaxWallet);

        // deploy mining
        {
            MiningV2 miningV2Impl = new MiningV2();
            //deploy proxy of staking
            ERC1967Proxy miningV2Proxy = new ERC1967Proxy(
                address(miningV2Impl), 
                abi.encodeCall(
                    miningV2Impl.initialize, 
                    (address(tokenV2), tokenV2.pancakePair(), permit)
                )
            );
            miningV2 = MiningV2(payable(address(miningV2Proxy))); 
        }

        // tokenV2.setMining(address(miningV2));

        vm.stopBroadcast();
        
        console.log("tokenV2 address: ", address(tokenV2));
        console.log("lp address: ", tokenV2.pancakePair());
        console.log("mining address: ", address(miningV2));
    }


}
