// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SignatureInfo} from "../libraries/SignatureInfo.sol";

interface IRegulation {
    event Recharge(string mark,address token,address associateAddr,uint256 amount,uint256 time);
    event Withdraw(string mark,address token,address associateAddr,uint256 amount,uint256 time);
    function nonce() external view returns(uint256);
    function checkerSignMsgSignature(SignatureInfo.SignMessage memory _msg) external view returns (bool);
    function isExcuted(string memory mark) external view returns(bool);
}