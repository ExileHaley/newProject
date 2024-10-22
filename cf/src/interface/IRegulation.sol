// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {SignatureInfo} from "../libraries/SignatureInfo.sol";


interface IRegulation{
    
    event Recharge(string orderNum,string orderMark,address token,address associateAddr,uint256 amount,uint256 time);

    event Withdraw(string orderNum,string orderMark,address token,address associateAddr,uint256 amount,uint256 nonce,uint256 time);

    event Mint(string orderMark,address token,address associateAddr,uint256 amount,uint256 usdt,uint256 time);

    function isExcuted(string memory num, string memory mark) external view returns(bool);

    function nonce() external view returns(uint256);

    function deposit(
        string memory orderNum,
        string memory orderMark,
        address token,
        uint256 amount
    ) external;

    function withdrawWithSignature(SignatureInfo.SignMessage memory _msg) external;

    function depositETH(
        string memory orderNum,
        string memory orderMark, 
        uint256 amount
    ) external payable;

    function managerWithdraw(
        address token, 
        address to, 
        uint256 amount
    ) external;

    function getSignMsgHash(SignatureInfo.SignMessage memory _msg) external view returns (bytes32);

    function checkerSignMsgSignature(SignatureInfo.SignMessage memory _msg) external view returns (bool);

    function managerMint(string memory mark,address to,uint256 amount) external;

    function mintCfArt(string memory mark,uint256 amount) external;

    function getPayment(uint256 amountNFT) external view returns(uint256);
}

//solc --abi IRegulation.sol | awk '/JSON ABI/{x=1;next}x' > IRegulation.abi