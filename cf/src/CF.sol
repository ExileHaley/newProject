// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface INFTStaking{
    function updatePool(uint256 amount) external;
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

contract CF is ERC20, Ownable {

    address marketing;

    uint256 public buyTaxRate;
    uint256 public sellTaxRate;
    
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public pancakePair;
    
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; 
    
    address public nftStaking;
    
    mapping(address => bool) public isExemptFromTax;
    address public regulation;

    uint256 MAXSUPPLY = 100000000000 ether;
    

    constructor(
        address _marketing,
        address _regulation,
        address _initialRecipient
    ) ERC20("CF", "CF") Ownable(msg.sender) {
        marketing = _marketing;
        regulation = _regulation;
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
            
        buyTaxRate = 300;  // 3%
        sellTaxRate = 300; // 3%
        
        isExemptFromTax[marketing] = true;
        isExemptFromTax[address(this)] = true;
        
        uint256 initialSupply = 4550000000 ether;
        _mint(_initialRecipient, initialSupply);
    }

    modifier onlyRegulation() {
        require(regulation == msg.sender, "ERC20: caller is not the regulation");
        _;
    }

    function setRegulation(address _newRegulation) external onlyOwner {
        regulation = _newRegulation;
    }
    
    function setTaxRates(uint256 _buyTaxRate, uint256 _sellTaxRate) external onlyOwner {
        require(_buyTaxRate <= 3000 && _sellTaxRate <= 3000, "Tax rate cannot exceed 30%");
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
    }

    function setNftStaking(address _nftStaking) external onlyOwner{
        require(_nftStaking != address(0), "New address cannot be zero address");
        nftStaking = _nftStaking;
    }

    function setTaxExemption(address _address, bool _exempt) external onlyOwner {
        isExemptFromTax[_address] = _exempt;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }


    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {

        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }


        bool isSell = to == pancakePair;
        bool isBuy = from == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];

        uint256 taxAmount = 0;
        if (!takeTax) {

            if (isBuy) {
                taxAmount = (amount * buyTaxRate) / 10000;
            } else if (isSell) {
                taxAmount = (amount * sellTaxRate) / 10000;
            }

        }

        if (taxAmount > 0) {

            if(isSell) {
                super._update(from, address(this), taxAmount);
                swapTokensForUSDT(marketing,taxAmount);
            }else {
                super._update(from, nftStaking, taxAmount);
                INFTStaking(nftStaking).updatePool(taxAmount);
            }
        
            super._update(from, to, amount - taxAmount);
        } else {
            super._update(from, to, amount);
        }

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


    function mint(address to, uint256 amount) external onlyRegulation(){
        require(totalSupply() + amount <= MAXSUPPLY,"ERC20: mint amount exceeds maxSupply.");
        _mint(to, amount);
    }
}


