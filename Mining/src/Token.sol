// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

contract ReceiveHelper {
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;

    constructor() {
        IERC20(USDT).approve(msg.sender, type(uint256).max);
    }
}

contract Token is ERC20, Ownable {
    IPancakeRouter02 public immutable pancakeRouter;
    address public immutable pancakePair;
    address public immutable receiveHelper;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) public usdtCost;
    mapping(address => bool) public isExemptFromTax;

    mapping(address => uint256) private holderIndex;
    address[] public holders;


    uint256 public txFee;
    uint256 public openingPoint;
    uint256 private constant MIN_ADDLIQUIDITY = 10e18;
    uint256 private currentIndex;

    address public exceedTaxWallet;
    address public mining;

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _mint(_initialRecipient, 100_000_000e18);

        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), USDT);
        exceedTaxWallet = _exceedTaxWallet;
        receiveHelper = _deployHelper();

        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[address(this)] = true;
        isExemptFromTax[msg.sender] = true;
    }

    modifier onlyMining() {
        require(msg.sender == mining, "NOT PERMITTED");
        _;
    }

    function setMining(address _mining) external onlyOwner {
        require(_mining != address(0), "ZERO ADDRESS");
        mining = _mining;
    }

    function setTaxExemption(address[] calldata _addrs, bool _exempt) external onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            require(_addrs[i] != address(0), "ZERO ADDRESS");
            isExemptFromTax[_addrs[i]] = _exempt;
        }
    }

    function mint(address to, uint256 amount) external onlyMining {
        _mint(to, amount);
    }
    event DebugHolder(address user, uint256 amount);
    function _update(address from, address to, uint256 amount) internal override {
        if (pancakePair != address(0) && openingPoint == 0 && IERC20(pancakePair).totalSupply() > 0) {
            openingPoint = block.timestamp;
        }

        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        bool isExchange = from == pancakePair || to == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];

        uint256 finalAmount = amount;
        uint256 taxAmount = 0;
        uint256 taxFee = _handleUserCostAndProfitTax(from, to, amount);
        if (taxFee > 0) {
            finalAmount = amount - taxFee;
            super._update(from, address(this), taxFee);
        }

        if (!takeTax && isExchange) {
            taxAmount = amount * calculateTaxes() / 100;
        }

        if (taxAmount > 0) {
            uint256 baseTaxAmount = (amount * 3) / 100;
            if (taxAmount > baseTaxAmount) super._update(from, exceedTaxWallet, taxAmount - baseTaxAmount);
            
            super._update(from, address(this), amount * 2 / 100);
            super._update(from, DEAD, amount * 1 / 100);
            super._update(from, to, finalAmount - taxAmount);

            txFee += amount * 2 / 100;
        } else {
            super._update(from, to, finalAmount);
        }

        if (!isExchange) _swapAndAdd();

        updateHolder(from);
        updateHolder(to);

        process(isExchange, 50000);
    }

    function _handleUserCostAndProfitTax(address from, address to, uint256 amount) internal returns (uint256) {
        if(pancakePair == address(0) || IERC20(pancakePair).totalSupply() == 0) return 0;  

        if (isExemptFromTax[from] || isExemptFromTax[to]) return 0;  

        if (from == pancakePair) {
            uint256 usdtSpent = getAmountInUSDT(amount);  
            if (usdtSpent > 0) usdtCost[to] += usdtSpent; 
            return 0;  
        }

        if (to == pancakePair) {
            uint256 totalUsdtValue = getAmountOutUSDT(amount);  
            uint256 cost = usdtCost[from];  

            if (cost > 0 && totalUsdtValue > cost) {
                uint256 profit = totalUsdtValue - cost;  
                uint256 profitFee = profit * 10 / 100;  
                uint256 tokenFee = getAmountInToken(profitFee);  

                if (tokenFee > 0) {
                    return tokenFee;  
                }
            }

            usdtCost[from] = 0; 
        }

        return 0;  
    }


    function _swapAndAdd() private {
        if (txFee < 100e18) return;

        try this._safeSwapAndAdd() {
            txFee = 0; 
        } catch {

        }
    }

    function _safeSwapAndAdd() external {
        require(msg.sender == address(this), "FORBIDDEN"); // 只允许内部调用
        uint256 oneHalf = txFee / 2;
        _swapTokensForUSDT(oneHalf);
        uint256 usdtAmount = IERC20(USDT).balanceOf(receiveHelper);
        if (usdtAmount > 0) {
            IERC20(USDT).transferFrom(receiveHelper, address(this), usdtAmount);
            _addLiquidity(txFee - oneHalf, usdtAmount);
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        _approve(address(this), address(pancakeRouter), tokenAmount);
        IERC20(USDT).approve(address(pancakeRouter), usdtAmount);
        pancakeRouter.addLiquidity(address(this), USDT, tokenAmount, usdtAmount, 0, 0, DEAD, block.timestamp);
    }

    function _swapTokensForUSDT(uint256 amount) private {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        _approve(address(this), address(pancakeRouter), amount);
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, receiveHelper, block.timestamp);
    }

    function process(bool isExchange, uint256 gas) private {
        if (isExchange) return;
        uint256 totalLP = IERC20(pancakePair).totalSupply();
        uint256 dividendFee = balanceOf(address(this)) - txFee;

        if (totalLP == 0 || dividendFee < 1e18) return;

        uint256 shareholderCount = holders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) currentIndex = 0;
            address shareholder = holders[currentIndex];
            uint256 lpBalance = IERC20(pancakePair).balanceOf(shareholder);

            if (lpBalance > 0) {
                uint256 amount = (dividendFee * lpBalance) / totalLP;
                if (amount > 0 && balanceOf(address(this)) - txFee > amount) {
                    super._update(address(this), shareholder, amount);
                }
            }

            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function calculateTaxes() internal view returns (uint256) {
        uint256 elapsed = block.timestamp - openingPoint;
        return elapsed < 30 minutes ? 10 : 3;
    }

    function _deployHelper() internal returns (address helper) {
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        bytes memory bytecode = type(ReceiveHelper).creationCode;
        assembly {
            helper := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }
    
    function updateHolder(address user) private {
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        if (size > 0 || user == DEAD) {
            return;
        }

        uint256 idx = holderIndex[user];
        bool isHolder = (holders.length > 0 && holders[idx] == user);

        if (IERC20(pancakePair).balanceOf(user) >= MIN_ADDLIQUIDITY) { 
            if (!isHolder) {
                holderIndex[user] = holders.length;
                holders.push(user);
            }
        } else { 
            if (isHolder) {
                address lastHolder = holders[holders.length - 1];
                holders[idx] = lastHolder;
                holderIndex[lastHolder] = idx;
                holders.pop();
                delete holderIndex[user];
            }
        }
    }


    function updateMyStatus() external {
        updateHolder(msg.sender);
    }

    function getHolders() external view returns (address[] memory) {
        return holders;
    }

    function getAmountOutUSDT(uint256 tokenAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        uint[] memory amounts = pancakeRouter.getAmountsOut(tokenAmount, path);
        return amounts[amounts.length - 1];
    }

    function getAmountInUSDT(uint256 tokenAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = address(this);
        uint[] memory amounts = pancakeRouter.getAmountsIn(tokenAmount, path);
        return amounts[0];
    }

    function getAmountInToken(uint256 usdtAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = address(this);
        uint[] memory amounts = pancakeRouter.getAmountsIn(usdtAmount, path);
        return amounts[1];
    }


    
}

