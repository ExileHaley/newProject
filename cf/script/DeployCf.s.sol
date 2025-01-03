// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Script, console} from "forge-std/Script.sol";
// import {CF} from "../src/CF.sol";
// contract DeployCf is Script {
//     CF      public cf;
//     address tokenRecipient;
//     address regulation;
//     address marketing;
//     address nftStaking;
    
//     function setUp() public {
//         tokenRecipient = address(0x50a67E10075Ccb0899Ddb00f8ACe00A30cAEb1b6);
//         marketing = address(0xD3569A1eb9eE79404572c69a2cB76A885557FEa9);


//         regulation = address(0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0);
//         nftStaking = address(0x2B82e39d41E3BDcaFcB2Cc6FD5D936C2B9Ffb515);
        
//     }

//     function run() public {
//         vm.startBroadcast();
//         cf = new CF(marketing, regulation, tokenRecipient);
//         cf.setNftStaking(nftStaking);

//         address[] memory whites = new address[](10);
//         whites[0] = 0x507a182653822a8CdA2CCDe59875aBd985750f20;
//         whites[1] = 0x39975FA6fBC128f13f208Cc4C0EE5816dc2B7804;
//         whites[2] = 0x9cD68AFf16c9a14b6EC02133b8Cf0652E677da7F;
//         whites[3] = 0xcb2259062c736d6524D74EA817C544799e4a47Ae;
//         whites[4] = 0xbb39917AFC2e6A6dcB4CaD104C96499c417938Ed;
//         whites[5] = 0x0E5D0DeA73D75012e8d1095a177182405245Bd69;
//         whites[6] = 0xafCD333E5FB6Dd2935Ef8d211Db9Ecd2323f1665;
//         whites[7] = 0x7bd9819967b4FB7eFBB96d7Abb8a6968B902267b;
//         whites[8] = 0x7352D6e23Cb7205E7db0bd232125471d7B13ADc1;
//         whites[9] = 0x7D2B42a48CD1cEFDfb717679026fA67fa9b35BfD;

//         for(uint i=0; i<whites.length; i++){
//             cf.setTaxExemption(whites[i], true);
//         }

//         vm.stopBroadcast();
//         // 输出部署地址
//         console.log("CF Token:",address(cf));
//     }

    
// }