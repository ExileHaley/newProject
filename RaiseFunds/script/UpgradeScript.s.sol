// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LockLiquidity} from "../src/LockLiquidity.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UpgradeScript is Script {
    LockLiquidity public lockLiquidity;
    address public token;
    address public lpToken;
    address public bnbRecipient;
    address public lockOwner;


    function setUp() public {

        lockLiquidity = LockLiquidity(payable(0x02A54993D121CD1981C28771C00F65bB86A97970));
        token = address(0x39DEACa23afd484ce707F4eD4179f8f2f03e9E5e);
        lpToken = address(0x61CAD5D284259A03f89761f7747e91b8AFD3Cbb8);

        bnbRecipient = address(0xd82f386049A899901CA5Ec5CD80D57FA99bf8E79);

        lockOwner = address(0xe22F1902253E1e5Cfb6890d960271DB18bdE865e);
    }

    function run() public{
        vm.startBroadcast();
        LockLiquidity lockLiquidityImpl = new LockLiquidity();
        bytes memory data= "";
        lockLiquidity.upgradeToAndCall(address(lockLiquidityImpl), data);
        lockLiquidity.setAddress(token, lpToken, bnbRecipient, lockOwner);
        vm.stopBroadcast();
    }
}
