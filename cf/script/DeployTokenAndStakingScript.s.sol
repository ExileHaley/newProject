// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {CF} from "../src/CF.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployTokenAndStakingScript is Script {
    NFTStaking public nftStaking;
    CF      public cf;
    address marketing;
    address cfArt;
    address usdt;
    

    function setUp() public {
        marketing = address(0x8EC1Cd137898008f50A623EF418D6eda5CE25052);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
    }

    function run() public {
        vm.startBroadcast();

        cf = new CF(marketing);

        // 部署实现合约
        NFTStaking nftStakingImpl = new NFTStaking();

        // 使用ERC1967代理合约
        ERC1967Proxy nftStakingProxy = new ERC1967Proxy(
            address(nftStakingImpl), 
            abi.encodeCall(nftStakingImpl.initialize, (cfArt, usdt, address(cf)))
        );

        // 将代理合约实例化为nftStaking
        nftStaking = NFTStaking(payable(nftStakingProxy));

        cf.setNftStaking(address(nftStaking));

        vm.stopBroadcast();

        // 输出部署地址
        console.log("Regulation deployed to:", address(nftStaking));
        console.log("CFArt deployed to:", address(cf));
    }

}