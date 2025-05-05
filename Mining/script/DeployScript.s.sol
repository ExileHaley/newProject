// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {MiningV1} from "../src/MiningV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployScript is Script {
    Token public token;
    MiningV1 public miningV1;

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
            MiningV1 miningV1Impl = new MiningV1();
            //deploy proxy of staking
            ERC1967Proxy miningV1Proxy = new ERC1967Proxy(
                address(miningV1Impl), 
                abi.encodeCall(
                    miningV1Impl.initialize, 
                    (address(token), token.pancakePair())
                )
            );
            miningV1 = MiningV1(payable(address(miningV1Proxy))); 
        }

        token.setMining(address(miningV1));

        vm.stopBroadcast();
        
        console.log("token address: ", address(token));
        console.log("lp address: ", token.pancakePair());
        console.log("mining address: ", address(miningV1));
    }


}
