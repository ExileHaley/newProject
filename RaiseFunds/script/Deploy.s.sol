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

//     节点地址：0xf755948147d98cd9da1128f3c39e260dac90c522
// BNB私募地址：0xac863e374d542880ae8d608204ea25351a62470e
// 代币地址：0xcf908559fcdaeb83b8e77a73da84b1940f1355ec
// 超出手续费地址：0x9b8d301a095b4acb9d6acf4b932d30593df22521

    function setUp() public {
        initialRecipient = address(0xcF908559fcDAEb83b8e77A73dA84B1940f1355eC);
        exceedTaxWallet = address(0x9B8d301A095B4acb9D6ACF4B932D30593Df22521);
        nodeDividend = address(0xf755948147D98CD9dA1128F3c39e260daC90c522);

        lockOwner = address(0x8a03078743E4B98b28F70e5A0F590B4BcEd85c1d);
        bnbRecipient = address(0xaC863E374d542880ae8D608204EA25351A62470E);
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
