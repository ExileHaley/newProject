// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {CF} from "../src/CF.sol";
import { CFArt } from "../src/CFArt.sol";
import {Regulation} from "../src/Regulation.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script{
    Regulation public regulation;
    NFTStaking public nftStaking;
    CF      public cf;
    CFArt      public cfArt;

    //regulation 调用nft和token
    //nft调用nftStaking


    //NFT和token设置regulation地址，只允许改地址进行调用
    //NFTStaking设置token地址，只允许改地址进行调用
    //

    address public admin;
    address public usdtRecipient;
    address public cfRecipient;
    address public usdt;
    address public marketing;
    address public dead;
    address uniswapV2Factory;
    address uniswapV2Router;
    address[] whites = [0xa75585b4EDe92a4FE93AB695642Ab5473FC1A7cd,0x07946199c3012bd4b5e1c177582f90C3998dc439,0x7aA47d4117c1fa7dA2e2395202d278A9CF79a0bd,0xF4d5bad96FD8723bFF83fEf137e81E036566e966,0xE10f602c7130AB642eE1d2BA3B27B2D29E5611EC,0x8dA1C3e0CacCd35019F79c62250497177A306316,0x3dBD01582875582c8fC5A84Bb88f67F252Df40D3,0xa222946D7372e33F6c0Fe6c5811e9afb773fEbf0,0xBF836f83fbD6cb9c8FD8B3F47C84781A7EA3Fc03];

    function setUp() public {
        admin = 0x9F54d7EAbE4B64B3f6E802885A5D4Bbcb7e8BE0e;
        usdtRecipient = 0xCc946894c70469Af085669ccB7Ab8EA21ecA6d47;
        cfRecipient = 0xb026640f5c9A8C39585f03Ed25b041f164eB1c47;
        usdt = 0x55d398326f99059fF775485246999027B3197955;
        marketing = 0xD3569A1eb9eE79404572c69a2cB76A885557FEa9;
        dead = 0x000000000000000000000000000000000000dEaD;
        uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    }

    function run() public {
        vm.startBroadcast();
        //部署cfArt
        cfArt = new CFArt();
        cfArt.setUrl("https://cf-nft.s3.ap-east-1.amazonaws.com/nft_json/");
        cf = new CF(marketing, cfRecipient);

        //部署regulation
        //部署实现合约
        Regulation regulationImpl = new Regulation();
        // 使用ERC1967代理合约
        ERC1967Proxy regulationProxy = new ERC1967Proxy(
            address(regulationImpl), 
            abi.encodeCall(regulationImpl.initialize, (admin, address(cf), address(cfArt), usdt, usdtRecipient, dead, uniswapV2Factory, uniswapV2Router))
        );
        // 将代理合约实例化为Regulation
        regulation = Regulation(payable(regulationProxy));
        
        
        //nft staking
        NFTStaking nftStakingImpl = new NFTStaking();
        // 使用ERC1967代理合约
        ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
            address(nftStakingImpl), 
            abi.encodeCall(nftStakingImpl.initialize, (address(cfArt), address(cf), dead))
        );

        nftStaking = NFTStaking(payable(nftStakingProxy));

        //给token设置NFTStaking
        cf.setConfig(address(regulation), address(nftStaking));
        //给Nft设置regulation地址
        cfArt.setConfig(address(regulation));

        for(uint i=0; i<whites.length; i++){
            cf.setTaxExemption(whites[i], true);
        }

        vm.stopBroadcast();

        console.log("#### cf address:",address(cf));
        console.log("#### cfArt address:",address(cfArt));
        console.log("#### regulation address:",address(regulation));
        console.log("#### nftStaking address:",address(nftStaking));
        console.log("#### pancake pool address:",cf.pancakePair());

    }

//         Regulation regulationImpl = new Regulation();
//         bytes memory data= "";
//         regulation.upgradeToAndCall(address(regulationImpl), data);

}
