// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import { CFArt } from "../src/CFArt.sol";
import {Regulation} from "../src/Regulation.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployCfArt is Script{
    Regulation public regulation;
    NFTStaking public nftStaking;
    CFArt      public cfArt;

    function setUp() public {
        regulation = Regulation(payable(0x11F586dc8cD7E0a9a505EDdd07d9Ac3fA57eb9f3));
        nftStaking = NFTStaking(payable(0xA848a7fB6e86eD236Aa2F11C7D9ADD4C1F354f6f));
    }

    function run() public {
        vm.startBroadcast();
        //部署cfArt
        cfArt = new CFArt();
        cfArt.setUrl("https://cf-nft.s3.ap-east-1.amazonaws.com/nft_json/");
        cfArt.setConfig(address(regulation));

        Regulation regulationImpl = new Regulation();
        bytes memory data0 = "";
        regulation.upgradeToAndCall(address(regulationImpl), data0);

        NFTStaking nftStakingImpl = new NFTStaking();
        bytes memory data1 = "";
        nftStaking.upgradeToAndCall(address(nftStakingImpl), data1);

        regulation.setCfArt(address(cfArt));
        nftStaking.setCfArt(address(cfArt));

        vm.stopBroadcast();
        console.log("#### cfArt address:",address(cfArt));

    }

}