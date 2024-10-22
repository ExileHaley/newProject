/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library SignatureInfo {

    struct SignMessage{
        string  orderNum;
        string  orderMark;
        address token;
        address recipient;
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
    } 

}