// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair {
    function sync() external;
}


interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Token is ERC20, Ownable{
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public exceedTaxWallet;
    address public lpDividend;
    address public nodeDividend;
    address public pancakePair;

    uint256 public openingPoint;
    uint256 public lastBurnTime;
    mapping(address => bool) public isExemptFromTax;
    uint256 public constant MIN_POOL_SUPPLY = 100000000 * 10 ** 18;
    
    constructor(
        string memory _name, 
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet,
        address _lpDividend,
        address _nodeDividend
    )ERC20(_name, _symbol)Ownable(msg.sender){
        _mint(_initialRecipient, 1000000000 * 10 ** decimals());
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());
        exceedTaxWallet = _exceedTaxWallet;
        lpDividend = _lpDividend;
        nodeDividend = _nodeDividend;
        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[address(this)] = true;
        isExemptFromTax[msg.sender] = true;
    }

    function setAddrConfig(
        address _exceedTaxWallet,
        address _lpDividend,
        address _nodeDividend
    ) external onlyOwner {
        exceedTaxWallet = _exceedTaxWallet;
        lpDividend = _lpDividend;
        nodeDividend = _nodeDividend;
    }

    function setTaxExemption(address[] calldata _addrs, bool _exempt) external onlyOwner {
        for(uint i=0; i<_addrs.length; i++) {
            require(_addrs[i] != address(0), "Zero address");
            isExemptFromTax[_addrs[i]] = _exempt;
        }
    }


    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{
        if(pancakePair != address(0) && openingPoint == 0){
            if(IERC20(pancakePair).totalSupply() > 0 ) openingPoint = block.timestamp;
        }

        if(from == address(0) || to == address(0)){
            super._update(from, to, amount);
            return;
        }

        bool isExchange = from == pancakePair || to == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];
        uint256 taxAmount = 0;
        if(!takeTax && isExchange) {
            (uint256 _buyTax, uint256 _sellTax) = calculateTaxes();
            require(_buyTax <= 30 && _sellTax <= 30, "Tax too high");
            uint256 taxRate = from == pancakePair ? _buyTax : _sellTax;
            taxAmount = (amount * taxRate) / 100;
        }

        if(taxAmount > 0){
            uint256 baseTaxAmount = (amount * 3) / 100;
            uint256 extraTaxAmount = taxAmount > baseTaxAmount ? taxAmount - baseTaxAmount : 0;

            super._update(from, lpDividend, baseTaxAmount * 70 / 100);
            super._update(from, nodeDividend, baseTaxAmount * 20 / 100);
            super._update(from, DEAD, baseTaxAmount * 10 / 100);

            if (extraTaxAmount > 0) super._update(from, exceedTaxWallet, extraTaxAmount);
            super._update(from, to, amount - taxAmount);
        }else{
            super._update(from, to, amount);
        }

        safeBurn(isExchange);

    }


    function safeBurn(bool _isExchange) internal {

        if(pancakePair != address(0) && lastBurnTime == 0){
            if(IERC20(pancakePair).totalSupply() > 0 ) lastBurnTime = block.timestamp;
        }

        if (!_isExchange) {
            uint256 epoch = (block.timestamp - lastBurnTime) / 6 hours;
            if (epoch == 0) return;

            uint256 currentSupply = balanceOf(pancakePair);
            uint256 targetBurnAmount = (currentSupply * epoch) / 100; // 每 6 小时累计 1%
            if(currentSupply > targetBurnAmount && currentSupply - targetBurnAmount >= MIN_POOL_SUPPLY){
                _burn(pancakePair, targetBurnAmount);
                lastBurnTime = block.timestamp;
                IUniswapV2Pair(pancakePair).sync();
            }
        }
    }

    function calculateTaxes() internal view returns (uint256 _buyTax, uint256 _sellTax) {
        uint256 elapsed = block.timestamp - openingPoint;
        if (elapsed < 12 hours) return (5, 15);
        else if (elapsed < 24 hours) return (5, 10);
        else return (3, 3);
    }


}