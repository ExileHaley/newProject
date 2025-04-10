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
    address public lpDividend;
    address public nodeDividend;
    //address of liquidity contract
    address public lockOwner;
    address public bnbRecipient;

    function setUp() public {
        initialRecipient = address(0x000000000000000000000000000000000000dEaD);
        exceedTaxWallet = address(0x000000000000000000000000000000000000dEaD);
        lpDividend = address(0x000000000000000000000000000000000000dEaD);
        nodeDividend = address(0x000000000000000000000000000000000000dEaD);

        lockOwner = address(0x000000000000000000000000000000000000dEaD);
        bnbRecipient = address(0x000000000000000000000000000000000000dEaD);
    }

    function run() public {
        vm.startBroadcast();
        //部署代币
        {
            token = new Token("Token", "TKN", initialRecipient, exceedTaxWallet, lpDividend, nodeDividend);
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
