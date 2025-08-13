// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script{
    Staking public staking;
    address public aniToken;
    address public agiToken;
    address public admin;

    function setUp() public {
        aniToken = address(0x77e066D53529d4104b4b98a5aE3668155601F4dA);
        agiToken = address(0xc2Da04c41519dda050ce2e05e28F8AeB74A4B52d);
        admin = address(0xE1cE74179318a119feD3C4d90558950a04686151);
    }

    function run() public {
        vm.startBroadcast();

        //部署质押合约
        {
            Staking stakingImpl = new Staking();
            //deploy proxy of staking
            ERC1967Proxy stakingProxy = new ERC1967Proxy(
                address(stakingImpl), 
                abi.encodeCall(
                    stakingImpl.initialize, 
                    (aniToken, agiToken, admin)
                )
            );
            staking = Staking(payable(address(stakingProxy)));  
        }
        vm.stopBroadcast();

        console.log("Staking deployed at: ", address(staking));
    }
}