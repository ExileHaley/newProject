// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {Staking} from "../src/Staking.sol";
import {Swap} from "../src/Swap.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    Token public token;
    Staking public staking;
    Swap    public swap;

    address marketing;
    address original;
    address treasury;
    address usdtRecipient;

    function setUp() public {
        token = Token(0x033E8FF9f37a786CDe1a6E7c96Dbb58e598E0962);

        // marketing = address(0xE4Beb2AC20B77c1761A69B78594e56aEcc59DB60);
        // original = address(0x29b41F3262cf340c2813d6259F765224A40f3E5d);
        // treasury = address(0x2bD18503A5Ca590Cf8877E6d0d0cb8121d81Bf31);
        usdtRecipient = address(0xe99E757C4D97c4aF38a723eF6A34b35945745276);
    }

    function run() public {
        vm.startBroadcast();
        //部署代币
        // token = new Token(marketing, treasury, original, "Token", "TKN");
        //部署swap
        swap = new Swap(address(token), usdtRecipient);
        {
            Staking stakingImpl = new Staking();
            //deploy proxy of staking
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl), 
                abi.encodeCall(
                    stakingImpl.initialize, 
                    (address(token), token.pancakePair())
                )
            );
            staking = Staking(payable(address(stakingProxy))); 
        }
        token.setStaking(address(staking));
        vm.stopBroadcast();
        console.log("token adddress:", address(token));
        console.log("staking adddress:", address(staking));
        console.log("swap adddress:", address(swap));
    }
}
