// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {CF} from "../src/CF.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    Regulation public regulation;
    NFTStaking public nftStaking;
    CF public cf;

    address public cfArt;
    address public dead;
    address public uniswapV2Factory;
    address public marketing;
    address public cfReceiver;

    uint256[] tokenIds = [348,349,350,350,351,352,353,354,355,356,357,358,359,361,362,363,364,366,367,368,369,370,371,372,373,374,375,376,377
,378,379,380,381,382,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411];

    function setUp() public {
        regulation = Regulation(payable(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0));
        

        cfArt = address(0x14C5DF0fB04b07d63CfC55983A8393D7581907ae);
        dead = address(0x000000000000000000000000000000000000dEaD);
        uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);


        //记得修改
        // marketing = address();
        // cfReceiver = address();
    }

    function run() public{
        vm.startBroadcast();
        //regulation 
        
        cf = new CF(marketing, address(regulation), cfReceiver);
        regulation.setCf(address(cf));

        //nft staking
        NFTStaking nftStakingImpl = new NFTStaking();
        // 使用ERC1967代理合约
        ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
            address(nftStakingImpl), 
            abi.encodeCall(nftStakingImpl.initialize, (cfArt, address(cf), dead))
        );
        nftStaking = NFTStaking(payable(nftStakingProxy));

        for(uint i=0; i<tokenIds.length; i++){
            nftStaking.initTokenIds(tokenIds[i]);
        }

       cf.setNftStaking(address(nftStaking));

        vm.stopBroadcast();
    }
}

