// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TransferHelper} from "./library/TransferHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {UniswapV2Library} from "./library/UniswapV2Library.sol";

contract Swap is Ownable{
    address public constant uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address usdt = 0x55d398326f99059fF775485246999027B3197955;
    address token;
    address recipient;
    

    constructor(address _token, address _recipient)Ownable(msg.sender){
        token = _token;
        recipient = _recipient;
    }

    function setRecipient(address _recipient) external onlyOwner(){
        recipient = _recipient;
    }

    function getUsdtForTokenAmount(uint256 amountUsdt) public view returns(uint256 amountToken){
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, usdt, token);
        amountToken = UniswapV2Library.quote(amountUsdt, reserveA, reserveB);
    }

    function getDiscountForSwap(uint256 amountUsdt) public view returns(uint256){
        uint256 totalUsdt = amountUsdt + amountUsdt * 10 /100;
        return  getUsdtForTokenAmount(totalUsdt);
    }

    function swap(uint256 amountUsdt) external {
        TransferHelper.safeTransferFrom(usdt, msg.sender, recipient, amountUsdt);
        uint256 amountToken = getDiscountForSwap(amountUsdt);
        TransferHelper.safeTransfer(token, msg.sender, amountToken);
    }
}