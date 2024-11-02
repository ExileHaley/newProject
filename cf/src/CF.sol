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
    // 交易税率（以10000为基数，即100.00%）
    uint256 public buyTaxRate;
    uint256 public sellTaxRate;
    
    // 优先卖出倍数（以100为基数，即1.00倍）
    uint256 public prioritySellMultiplier = 500; // 默认5倍
    
    // PancakeSwap路由合约
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public pancakePair;
    
    // USDT代币地址
    // address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; // BSC上的USDT地址
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955; // BSC测试网上的USDT地址
    
    
    // 指定接收税费的地址
    address public treasuryWallet;
    address public nftStaking;
    
    // 最小兑换阈值
    uint256 public minTokensBeforeSwap = 1 * 10 ** decimals();
    
    // 合约内部状态
    bool private swapping;
    mapping(address => bool) public isExemptFromTax;
    
    // 事件
    event TaxRatesUpdated(uint256 newBuyTax, uint256 newSellTax);
    event PrioritySellMultiplierUpdated(uint256 newMultiplier);
    event TreasuryWalletUpdated(address newWallet);
    event SwapAndSendTax(uint256 tokensSwapped, uint256 usdtReceived);
    event PrioritySellExecuted(uint256 amount);

    constructor(
        address _treasuryWallet
    ) ERC20("CF", "CF") Ownable(msg.sender) {
        require(_treasuryWallet != address(0), "Treasury wallet cannot be zero address");
        treasuryWallet = _treasuryWallet;
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);
            
        // 设置初始税率
        buyTaxRate = 300;  // 5%
        sellTaxRate = 300; // 5%
        
        // 设置税费豁免地址
        isExemptFromTax[_treasuryWallet] = true;
        isExemptFromTax[address(this)] = true;
        
        uint256 initialSupply = 1000000 ether;
        _mint(msg.sender, initialSupply);
    }
    
    // 修改税率
    function setTaxRates(uint256 _buyTaxRate, uint256 _sellTaxRate) external onlyOwner {
        require(_buyTaxRate <= 3000 && _sellTaxRate <= 3000, "Tax rate cannot exceed 30%");
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
        emit TaxRatesUpdated(_buyTaxRate, _sellTaxRate);
    }
    
    // 修改优先卖出倍数
    function setPrioritySellMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier >= 100 && _multiplier <= 1000, "Multiplier must be between 1x and 10x");
        prioritySellMultiplier = _multiplier;
        emit PrioritySellMultiplierUpdated(_multiplier);
    }
    
    // 修改Treasury钱包地址
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

    // 设置税费豁免地址
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

    // 重写更新函数
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(!isContract(from) && balanceOf(from) >= 1e18) require(amount <= balanceOf(from) - 1e18, "ERC20: transfer amount exceeds balance");
        // 如果正在进行税费兑换，直接转账
        if (swapping) {
            super._update(from, to, amount);
            return;
        }

        // 如果是铸造或销毁，直接处理
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        // 判断是买入还是卖出
        bool isSell = to == pancakePair;
        bool isBuy = from == pancakePair;

        // 如果是卖出交易，且发送者不是指定地址，则触发优先卖出

        if (isSell && from != treasuryWallet && !swapping && from != address(this)) {
            uint256 priorityAmount = amount * prioritySellMultiplier / 100;
            _executePrioritySell(priorityAmount);
        }

        // 计算是否需要收税
        bool takeTax = !isExemptFromTax[from] && !isExemptFromTax[to];
        
        // 计算税费
        uint256 taxAmount = 0;
        if (takeTax) {
            if (isBuy) {
                taxAmount = (amount * buyTaxRate) / 10000;
            } else if (isSell) {
                taxAmount = (amount * sellTaxRate) / 10000;
            }
        }

        // 如果有税费
        if (taxAmount > 0) {
            // 先转tax到合约
            super._update(from, address(this), taxAmount);
            // 如果达到最小兑换阈值，执行兑换
            if (taxAmount >= minTokensBeforeSwap) {
                if(isSell) swapTokensForUSDT(treasuryWallet,taxAmount);
            } 
                
            // 再转剩余金额给接收者
            super._update(from, to, amount - taxAmount);
        } else {
            super._update(from, to, amount);
        }

        if(!isBuy && !isSell) {
            // uint256 _before = IERC20(USDT).balanceOf(nftStaking);
            swapTokensForUSDT(nftStaking, balanceOf(address(this)));
            // uint256 _after = IERC20(USDT).balanceOf(nftStaking);
            // if(_after > _before) INFTStaking(nftStaking).updatePool(_after - _before);
        }
    }

    // 执行优先卖出
    function _executePrioritySell(uint256 amount) private {
        if (amount == 0 || swapping) return;
        
        uint256 treasuryBalance = balanceOf(treasuryWallet);
        if (treasuryBalance < amount) return;
        
        swapping = true;
        
        // 从Treasury钱包转到合约
        super._update(treasuryWallet, address(this), amount);
        
        // 执行兑换
        swapTokensForUSDT(treasuryWallet, amount);
        
        swapping = false;
        emit PrioritySellExecuted(amount);
    }

    // 将代币兑换为USDT
    event DebugSwappingState(bool swapping, uint256 balance);
    
    function swapTokensForUSDT(address _to, uint256 amount) private {
        // uint256 tokenBalance = balanceOf(address(this));
        if (amount == 0) return;
        swapping = true;
        // 准备兑换路径
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        
        // 授权路由合约
        _approve(address(this), address(pancakeRouter), amount);
        
        // 执行兑换
        try pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            _to,
            block.timestamp
        ) {
            emit SwapAndSendTax(amount, IERC20(USDT).balanceOf(_to));
        } catch {
            // 如果兑换失败，恢复swapping状态
            swapping = false;
            return; // 确保后续代码不会执行
        }
        
        swapping = false;
    }
}

//其中_update函数中的else if(isBuy) swapTokensForUSDT(nftStaking)执行出现revert: Pancake: LOCKED错误
