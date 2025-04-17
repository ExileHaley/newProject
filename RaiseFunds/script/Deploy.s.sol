// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";
import {LockLiquidity} from "../src/LockLiquidity.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script{
    Token public token;
    LockLiquidity public lockLiquidity;
    //address of token contract
    address public initialRecipient;
    address public exceedTaxWallet;
    // address public lpDividend;
    address public nodeDividend;
    //address of liquidity contract
    address public lockOwner;
    address public bnbRecipient;

    function setUp() public {
        initialRecipient = address(0xF75F812e37846EDDE1D70f8Ed0eb8a35D9bd10e6);
        exceedTaxWallet = address(0x4A9A00b191D0067E5eC4F476843f6F688EE5bf25);
        nodeDividend = address(0xd99291831DfB88aDE6f8bd977e92Af86c3536F91);

        lockOwner = address(0x8a03078743E4B98b28F70e5A0F590B4BcEd85c1d);
        bnbRecipient = address(0x01BB9Ce77c9D3Fd6C320CCFc56BDF3DD59E7936E);
    }

    function run() public {
        vm.startBroadcast();
        //部署代币
        {
            token = new Token("EAC", "EAC", initialRecipient, exceedTaxWallet, nodeDividend);
        }

        //部署锁仓合约
        {
            LockLiquidity lockLiquidityImpl = new LockLiquidity();
            //deploy proxy of staking
            ERC1967Proxy lockLiquidityProxy = new ERC1967Proxy(
                address(lockLiquidityImpl), 
                abi.encodeCall(
                    lockLiquidityImpl.initialize, 
                    (token.pancakePair(), address(token), lockOwner, bnbRecipient)
                )
            );
            lockLiquidity = LockLiquidity(payable(address(lockLiquidityProxy)));  
        }


        vm.stopBroadcast();
        console.log("Token deployed at: ", address(token));
        console.log("PancakePair: ", token.pancakePair());
        console.log("LockLiquidity deployed at: ", address(lockLiquidity));
    }
}
