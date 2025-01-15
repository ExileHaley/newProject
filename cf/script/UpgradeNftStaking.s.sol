// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTStaking} from "../src/NFTStaking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeNftStaking is Script{
    NFTStaking public nftStaking;
    address public to;

    function setUp() public {
        nftStaking = NFTStaking(payable(0xA848a7fB6e86eD236Aa2F11C7D9ADD4C1F354f6f));
        to = 0x71B1043e426eBe957bAee5221233A948726ADa3f;
    }

    function run() public {
        vm.startBroadcast();

        NFTStaking nftStakingImpl = new NFTStaking();
        bytes memory data1 = "";
        nftStaking.upgradeToAndCall(address(nftStakingImpl), data1);

        nftStaking.managerWithdraw(to);

        vm.stopBroadcast();

    }

}