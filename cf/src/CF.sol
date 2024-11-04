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

    uint256 public buyTaxRate;
    uint256 public sellTaxRate;
    
    uint256 public prioritySellMultiplier = 500;
    
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public pancakePair;
    
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; 
    

    address public treasuryWallet;
    address public nftStaking;

    uint256 public minTokensBeforeSwap = 1 * 10 ** decimals();
    

    bool private swapping;
    mapping(address => bool) public isExemptFromTax;
    address public admin;
    uint256 MAXSUPPLY = 100000000000 ether;
    

    event TaxRatesUpdated(uint256 newBuyTax, uint256 newSellTax);
    event PrioritySellMultiplierUpdated(uint256 newMultiplier);
    event TreasuryWalletUpdated(address newWallet);
    event SwapAndSendTax(uint256 tokensSwapped, uint256 usdtReceived);
    event PrioritySellExecuted(uint256 amount);

    constructor(
        address _treasuryWallet,
        address _cfRegulation,
        address _initialRecipient
    ) ERC20("CF", "CF") Ownable(msg.sender) {
        require(_treasuryWallet != address(0), "Treasury wallet cannot be zero address");
        treasuryWallet = _treasuryWallet;
        admin = _cfRegulation;
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
            
        buyTaxRate = 300;  // 3%
        sellTaxRate = 300; // 3%
        
        isExemptFromTax[_treasuryWallet] = true;
        isExemptFromTax[address(this)] = true;
        
        uint256 initialSupply = 4550000000 ether;
        _mint(_initialRecipient, initialSupply);
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
    }
    
    function setTaxRates(uint256 _buyTaxRate, uint256 _sellTaxRate) external onlyOwner {
        require(_buyTaxRate <= 3000 && _sellTaxRate <= 3000, "Tax rate cannot exceed 30%");
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
        emit TaxRatesUpdated(_buyTaxRate, _sellTaxRate);
    }

    function setPrioritySellMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier >= 100 && _multiplier <= 1000, "Multiplier must be between 1x and 10x");
        prioritySellMultiplier = _multiplier;
        emit PrioritySellMultiplierUpdated(_multiplier);
    }

    function setTreasuryWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "New wallet cannot be zero address");
        isExemptFromTax[treasuryWallet] = false;
        treasuryWallet = _newWallet;
        isExemptFromTax[_newWallet] = true;
        emit TreasuryWalletUpdated(_newWallet);
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
        if(!isContract(from) && from != address(0)) require(amount + 1e18 <= balanceOf(from), "ERC20: transfer amount exceeds balance");

        if (swapping) {
            super._update(from, to, amount);
            return;
        }


        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }


        bool isSell = to == pancakePair;
        bool isBuy = from == pancakePair;

        if (isSell && from != treasuryWallet && !swapping && from != address(this)) {
            uint256 priorityAmount = amount * prioritySellMultiplier / 100;
            _executePrioritySell(priorityAmount);
        }

        bool takeTax = !isExemptFromTax[from] && !isExemptFromTax[to];
        
        uint256 taxAmount = 0;
        if (takeTax) {
            if (isBuy) {
                taxAmount = (amount * buyTaxRate) / 10000;
            } else if (isSell) {
                taxAmount = (amount * sellTaxRate) / 10000;
            }
        }

        if (taxAmount > 0) {

            super._update(from, address(this), taxAmount);

            if (taxAmount >= minTokensBeforeSwap) {
                if(isSell) swapTokensForUSDT(treasuryWallet,taxAmount);
            } 
        
            super._update(from, to, amount - taxAmount);
        } else {
            super._update(from, to, amount);
        }

        if(!isBuy && !isSell) {
            uint256 _before = IERC20(USDT).balanceOf(nftStaking);
            swapTokensForUSDT(nftStaking, balanceOf(address(this)));
            uint256 _after = IERC20(USDT).balanceOf(nftStaking);
            if(_after > _before) INFTStaking(nftStaking).updatePool(_after - _before);
        }
    }


    function _executePrioritySell(uint256 amount) private {
        if (amount == 0 || swapping) return;
        
        uint256 treasuryBalance = balanceOf(treasuryWallet);
        if (treasuryBalance < amount) return;
        
        swapping = true;
        
        super._update(treasuryWallet, address(this), amount);
        

        swapTokensForUSDT(treasuryWallet, amount);
        
        swapping = false;
        emit PrioritySellExecuted(amount);
    }


    event DebugSwappingState(bool swapping, uint256 balance);
    
    function swapTokensForUSDT(address _to, uint256 amount) private {

        if (amount == 0) return;
        swapping = true;

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
        ) {
            emit SwapAndSendTax(amount, IERC20(USDT).balanceOf(_to));
        } catch {
            swapping = false;
            return; 
        }
        
        swapping = false;
    }


    function mint(address to, uint256 amount) external onlyAdmin(){
        require(totalSupply() + amount <= MAXSUPPLY,"ERC20: mint amount exceeds maxSupply.");
        _mint(to, amount);
    }
}


