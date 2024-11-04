// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Regulation} from "../src/Regulation.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CF} from "../src/CF.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import { CFArt } from "../src/CFArt.sol";

contract Deploy is Script {
    Regulation public regulation;
    CFArt      public cfArt;
    NFTStaking public nftStaking;
    CF      public cf;

    address admin;
    address recipient;
    address tokenRecipient;
    address usdt;
    address marketing;
    address uniswapV2Factory;
    address uniswapV2Router;

    function setUp() public {

        admin = address(0x9F54d7EAbE4B64B3f6E802885A5D4Bbcb7e8BE0e);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        tokenRecipient = address(0x50a67E10075Ccb0899Ddb00f8ACe00A30cAEb1b6);

        recipient = address(0xCc946894c70469Af085669ccB7Ab8EA21ecA6d47);
        marketing = address(0xCc946894c70469Af085669ccB7Ab8EA21ecA6d47);

        uniswapV2Factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
        uniswapV2Router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    }

    function run() public {
        vm.startBroadcast();

        cfArt = new CFArt();

        // 部署实现合约
        Regulation regulationImpl = new Regulation();

        // 使用ERC1967代理合约
        ERC1967Proxy regulationProxy = new ERC1967Proxy(
            address(regulationImpl), 
            abi.encodeCall(regulationImpl.initialize, (admin, address(cfArt), usdt, recipient, uniswapV2Factory, uniswapV2Router))
        );

        // 将代理合约实例化为Regulation
        regulation = Regulation(payable(regulationProxy));

        cfArt.setAdmin(address(regulation));
        cfArt.setUrl("https://cf-nft.s3.ap-east-1.amazonaws.com/nft_json/");


        cf = new CF(marketing, address(regulation), tokenRecipient);

        NFTStaking nftStakingImpl = new NFTStaking();

        // 使用ERC1967代理合约
        ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
            address(nftStakingImpl), 
            abi.encodeCall(nftStakingImpl.initialize, (address(cfArt), usdt, address(cf)))
        );

        // 将代理合约实例化为nftStaking
        nftStaking = NFTStaking(payable(nftStakingProxy));
        cf.setNftStaking(address(nftStaking));

        vm.stopBroadcast();

        // 输出部署地址
        console.log("Regulation:", address(regulation));
        console.log("CF NFT:", address(cfArt));
        console.log("CF Token:",address(cf));
        console.log("NFTStaking:",address(nftStaking));
        console.log("Pancake pair:",cf.pancakePair());
    }

}
// JSON: https://cf-nft.s3.ap-east-1.amazonaws.com/nft_json/1.json

// IMG:https://cf-nft.s3.ap-east-1.amazonaws.com/nft_img/1.png