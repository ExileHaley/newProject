// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    Staking public staking;

    address public love;
    address public best;
    address public initialInviter;
    address public owner;

//     初始地址 0xD1AE2c6C123951DA80a417FAC3451D768C12F825 
// 现在的币转到地址 0xA9851c4e88F290eFB4cd8F92bCd76D69f8CB3d73
// 权限地址0xD8648E823DBa65579A2C3E3f5092e604bBef018B

    function setUp() public {
        love = address(0xf453560309713fE5480474432f0af56b15Dd51D0);
        best = address(0xDf71a9F5d2DD419f43b1C05Ce33B74F39De8eB12);
        //
        initialInviter = address(0xD1AE2c6C123951DA80a417FAC3451D768C12F825);
        owner = address(0xD8648E823DBa65579A2C3E3f5092e604bBef018B);
    }

    function run() public {
        vm.startBroadcast();

        Staking stakingImpl = new Staking();
            //deploy proxy of staking
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl), 
                abi.encodeCall(
                    stakingImpl.initialize, 
                    (initialInviter, love, best)
                )
            );
        staking = Staking(payable(address(stakingProxy)));
        staking.transferOwnership(owner);
        vm.stopBroadcast();

        console.log("Staking deployed to:", address(staking));
    }
}
