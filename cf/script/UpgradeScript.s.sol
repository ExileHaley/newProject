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

    address[] whites = [0xa75585b4EDe92a4FE93AB695642Ab5473FC1A7cd,0x07946199c3012bd4b5e1c177582f90C3998dc439,0x7aA47d4117c1fa7dA2e2395202d278A9CF79a0bd,0xF4d5bad96FD8723bFF83fEf137e81E036566e966,0xE10f602c7130AB642eE1d2BA3B27B2D29E5611EC,0x8dA1C3e0CacCd35019F79c62250497177A306316,0x3dBD01582875582c8fC5A84Bb88f67F252Df40D3,0xa222946D7372e33F6c0Fe6c5811e9afb773fEbf0,0xBF836f83fbD6cb9c8FD8B3F47C84781A7EA3Fc03];

    function setUp() public {
        regulation = Regulation(payable(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0));
        

        cfArt = address(0x14C5DF0fB04b07d63CfC55983A8393D7581907ae);
        dead = address(0x000000000000000000000000000000000000dEaD);
        uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);


        //记得修改
        marketing = address(0xD3569A1eb9eE79404572c69a2cB76A885557FEa9);
        cfReceiver = address(0xb026640f5c9A8C39585f03Ed25b041f164eB1c47);
    }

    function run() public{
        vm.startBroadcast();
        //regulation 
        
        cf = new CF(marketing, address(regulation), cfReceiver);
    
        // regulation.setCf(address(cf));

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
        for (uint i=0; i<whites.length; i++){
            cf.setTaxExemption(whites[i], true);
        }

        vm.stopBroadcast();

        console.log("NftStaking address:",address(nftStaking));
        console.log("cf address:",address(cf));
    }
}

