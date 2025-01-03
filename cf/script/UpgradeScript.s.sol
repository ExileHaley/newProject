// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Regulation public regulation;
    NFTStaking public nftStaking;

    address public cf;
    address public dead;
    address public uniswapV2Factory;

    function setUp() public {
        regulation = Regulation(payable(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0));
        nftStaking = NFTStaking(payable(0x2B82e39d41E3BDcaFcB2Cc6FD5D936C2B9Ffb515));

        cf = address(0xC3214Da07B8985878f2F3590a01a7D4202Caf01d);
        dead = address(0x000000000000000000000000000000000000dEaD);
        uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    }

    function run() public{
        vm.startBroadcast();
        //regulation 
        Regulation regulationImpl = new Regulation();
        bytes memory data0 = "";
        regulation.upgradeToAndCall(address(regulationImpl), data0);
        regulation.setCf(cf, dead);

        //nft staking
        NFTStaking nftStakingImpl = new NFTStaking();
        bytes memory data1 = "";
        nftStaking.upgradeToAndCall(address(nftStakingImpl), data1);
        nftStaking.setAddress(cf, dead, uniswapV2Factory);
        nftStaking.setMultiple(5);

        vm.stopBroadcast();
    }
}

