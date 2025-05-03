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
    address public nodeDividend;
    address public pancakePair;

    uint256 public openingPoint;
    uint256 public lastBurnTime;
    mapping(address => bool) public isExemptFromTax;
    mapping(address => bool) public blackList;
    uint256 public constant MIN_POOL_SUPPLY = 100000000 * 10 ** 18;
    uint256 public MIN_DIVIDEND_LIMIT = 100 * 10 **18;

    address[] public holders;
    mapping(address => uint256) holderIndex;
    uint256 currentIndex;

    constructor(
        string memory _name, 
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet,
        address _nodeDividend
    )ERC20(_name, _symbol)Ownable(msg.sender){
        uint256 initialSupply = 13500000000 * 10 ** decimals();
        _mint(_initialRecipient, initialSupply);
        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), pancakeRouter.WETH());
        exceedTaxWallet = _exceedTaxWallet;
        nodeDividend = _nodeDividend;
        isExemptFromTax[_initialRecipient] = true;
        isExemptFromTax[_nodeDividend] = true;
        isExemptFromTax[address(this)] = true;
        isExemptFromTax[msg.sender] = true;
    }

    function setAddrConfig(
        address _exceedTaxWallet,
        address _nodeDividend
    ) external onlyOwner {
        require(_exceedTaxWallet != address(0) && _nodeDividend != address(0), "Zero address.");
        exceedTaxWallet = _exceedTaxWallet;
        nodeDividend = _nodeDividend;
    }

    function setMinDividendLimit(uint256 _minDividendLimit) external onlyOwner{
        MIN_DIVIDEND_LIMIT = _minDividendLimit;
    }

    function setTaxExemption(address[] calldata _addrs, bool _exempt) external onlyOwner {
        for(uint i=0; i<_addrs.length; i++) {
            require(_addrs[i] != address(0), "Zero address");
            isExemptFromTax[_addrs[i]] = _exempt;
        }
    }

    function setBlackList(address[] calldata _addrs, bool _black) external onlyOwner {
        for(uint i=0; i<_addrs.length; i++) {
            require(_addrs[i] != address(0), "Zero address");
            blackList[_addrs[i]] = _black;
        }
    }


    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override{
        require(!blackList[from], "Blacklisted address");

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
            super._update(from, address(this), baseTaxAmount * 70 / 100);
            super._update(from, nodeDividend, baseTaxAmount * 20 / 100);
            super._update(from, DEAD, baseTaxAmount * 10 / 100);

            if (extraTaxAmount > 0) super._update(from, exceedTaxWallet, extraTaxAmount);
            super._update(from, to, amount - taxAmount);
        }else{
            super._update(from, to, amount);
        }

        safeBurn(isExchange);
        process(isExchange, 50000);

        uint256 senderLpBalance = IERC20(pancakePair).balanceOf(from);
        if (senderLpBalance >= MIN_DIVIDEND_LIMIT) addHolder(from);
        else removeHolder(from);

        uint256 recipientLpBalance = IERC20(pancakePair).balanceOf(to);
        if (recipientLpBalance >= MIN_DIVIDEND_LIMIT) addHolder(to);
        else removeHolder(to);
        
    }


    function safeBurn(bool _isExchange) internal {

        if(pancakePair != address(0) && lastBurnTime == 0){
            if(IERC20(pancakePair).totalSupply() > 0 ) lastBurnTime = block.timestamp;
        }

        if (!_isExchange) {
            uint256 epoch = (block.timestamp - lastBurnTime) / 6 hours;
            if (epoch == 0) return;

            uint256 currentSupply = balanceOf(pancakePair);
            uint256 targetBurnAmount = (currentSupply * epoch) / 100; 
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

    function process(bool isExchange, uint256 gas) private {
        if(isExchange) return;
        if(balanceOf(address(this)) < 1e18) return;
        
        uint256 totalLP = IERC20(pancakePair).totalSupply();
        uint256 dividendFee = balanceOf(address(this));

        if(totalLP == 0 || dividendFee == 0) return;

        address shareHolder;
        uint256 lpBalance;
        uint256 amount;
        uint256 shareholderCount = holders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];

            lpBalance = IERC20(pancakePair).balanceOf(shareHolder);

            if (lpBalance > 0) {
                amount = (dividendFee * lpBalance) / totalLP;
                uint256 currentFee = balanceOf(address(this));
                if (amount > 0 && currentFee > amount) super._update(address(this), shareHolder, amount);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }    

    function addHolder(address user) private  {
        uint256 size;

        assembly {
            size := extcodesize(user)
        }

        if (size > 0) {
            return;
        }

        if (holderIndex[user] == 0) {
            if (holders.length ==0 || holders[0] != user) {
                holderIndex[user] = holders.length;
                holders.push(user);
            }
        }
    }

    function removeHolder(address user) private {
        uint256 indexToRemove = holderIndex[user];
        uint256 size;
        assembly {
            size := extcodesize(user)
        }
        if (indexToRemove == 0 || size > 0) {
            return;
        }
        address lastHolder = holders[holders.length - 1];
        holders[indexToRemove] = lastHolder;
        holderIndex[lastHolder] = indexToRemove;
        holders.pop();
        delete holderIndex[user];
    }

    function updateMyStatus() external {
        uint256 lpBalance = IERC20(pancakePair).balanceOf(msg.sender);
        if (lpBalance >= MIN_DIVIDEND_LIMIT) {
            addHolder(msg.sender);
        } else {
            removeHolder(msg.sender);
        }
    }

    function getHolders() public view returns(address[] memory){
        return holders;
    }

    function claim(address recipient) external onlyOwner(){
        require(recipient != address(0), "Zero address.");
        super._transfer(address(this), recipient, balanceOf(address(this)));
    } 

}