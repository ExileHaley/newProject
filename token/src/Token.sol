// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Token is ERC20, Ownable, ReentrancyGuard {

    event SwapAndSendTax(address recipient, uint256 tokensSwapped);

    address public marketing;
    address public pancakePair;
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    mapping(address => bool) public isExemptFromTax;
    uint256 immutable public taxRate;
    bool private swapping;

    uint256 public minTokensBeforeSwap = 1 * 10 ** decimals();

    constructor(
        address _marketing, 
        address _initialRecipient,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender){

        _mint(_initialRecipient, 100000000e18);

        marketing = _marketing;

        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);

        isExemptFromTax[msg.sender] = true;
        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[marketing] = true;
        isExemptFromTax[address(this)] = true;

        taxRate = 2500;
    }

    function setMarketing(address _marketing) external onlyOwner {
        require(_marketing != address(0), "Zero address");
        marketing = _marketing;
    }

    function setTaxExemption(address _addr, bool _exempt) external onlyOwner {
        require(_addr != address(0), "Zero address");
        isExemptFromTax[_addr] = _exempt;
    }

    function swapTokensForUSDT(address _to, uint256 _amount) private nonReentrant {

        if (_amount == 0) return ;
        swapping = true;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        
        _approve(address(this), address(pancakeRouter), _amount);
        
        try pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0, 
            path,
            _to,
            block.timestamp + 30
        ) {
            emit SwapAndSendTax(_to, _amount);
        }catch{}

        swapping = false;
        
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        if (swapping) {
            super._update(from, to, amount);
            return;
        }

        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        bool isExchange = from == pancakePair || to == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];

        uint256 taxAmount = 0;
        if (!takeTax && isExchange) taxAmount = (amount * taxRate) / 10000;

        if (taxAmount > 0) {
            super._update(from, address(this), taxAmount);
            
            if(balanceOf(address(this)) >= minTokensBeforeSwap) swapTokensForUSDT(marketing, balanceOf(address(this)));
            
            super._update(from, to, amount - taxAmount);
        } else {
            super._update(from, to, amount);
        }

    }

}