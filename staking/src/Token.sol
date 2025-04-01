// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
}

interface IUniswapV2Pair {
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
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Token is ERC20, Ownable, ReentrancyGuard {

    event SwapAndSendTax(address recipient, uint256 tokensSwapped);

    address public marketing;
    address public pancakePair;
    address public staking;
    IPancakeRouter02 public pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public dead = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public isExemptFromTax;
    mapping(address => bool) public ogList;
    // mapping(address => address) public pendingInviter;
    // mapping(address => address) public inviter;
    uint256 public taxRate = 100;
    uint256 public openingPoint;
    uint256 public burnAmount;
    bool private swapping;

    uint256 public minTokensBeforeSwap = 1 * 10 ** decimals();

    struct Invitation{
        address pedingInviter;
        address inviter;
        uint256 inviteTime;
    }
    mapping(address => Invitation) public invitationes;

    constructor(
        address _marketing, 
        address _treasury,
        address _original,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender){

        _mint(_treasury, 3000000000e18);
        _mint(_original, 100000000e18);

        marketing = _marketing;

        pancakePair = IPancakeFactory(pancakeRouter.factory())
            .createPair(address(this), USDT);

        isExemptFromTax[msg.sender] = true;
        isExemptFromTax[_treasury] = true;
        isExemptFromTax[_original] = true;
        isExemptFromTax[marketing] = true;
        isExemptFromTax[address(this)] = true;

    }

    modifier onlyMiner() {
        require(msg.sender == staking, "Not miner");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyMiner {
        _mint(_to, _amount);
    }

    function setStaking(address _staking) external onlyOwner{
        require(_staking != address(0), "Zero address");
        staking = _staking;
        isExemptFromTax[_staking] = true;
    }

    function setMarketing(address _marketing) external onlyOwner {
        require(_marketing != address(0), "Zero address");
        marketing = _marketing;
    }

    function setTaxExemption(address[] calldata _addrs, bool _exempt) external onlyOwner {
        for(uint i=0; i<_addrs.length; i++) {
            require(_addrs[i] != address(0), "Zero address");
            isExemptFromTax[_addrs[i]] = _exempt;
        }
    }
    
    function setOgList(address[] calldata _addrs, bool _og) external onlyOwner {
        for(uint i=0; i<_addrs.length; i++) {
            require(_addrs[i] != address(0), "Zero address");
            ogList[_addrs[i]] = _og;
        }
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
    ) internal virtual override{
        
        if(pancakePair != address(0)){
            if(IERC20(pancakePair).totalSupply() > 0 && openingPoint == 0) openingPoint = block.timestamp;
        }
        
        if(swapping){
            super._update(from, to, amount);
            return;
        }

        if(from == address(0) || to == address(0)){
            super._update(from, to, amount);
            return;
        }

        bool isExchange = from == pancakePair || to == pancakePair;
        bool takeTax = isExemptFromTax[from] || isExemptFromTax[to];
        bool isOg = ogList[from] || ogList[to];
        bool isOpening = block.timestamp - openingPoint >= 3600;

        if(!isOpening && isExchange) require(takeTax || isOg, "Not open yet");

        uint256 taxAmount = 0;
        if(!takeTax && isExchange && !isOg) taxAmount = amount * taxRate / 10000;
        if(isOg && isExchange) taxAmount = amount * 1000 / 10000;

        if(taxAmount > 0){
            uint256 oneHalf = taxAmount / 2;
            super._update(from, address(this), oneHalf);
            super._update(from, dead, taxAmount - oneHalf);

            if(balanceOf(address(this)) >= minTokensBeforeSwap) swapTokensForUSDT(marketing, balanceOf(address(this)));
            super._update(from, to, amount - taxAmount);
        }else{
            super._update(from, to, amount);
        }

        if(!isExchange) afterTransfer(from, to, amount);
        
    }

    // function resetInviter(address _addr) external onlyOwner {
    //     require(_addr != address(0), "Zero address");
    //     require(inviter[_addr] != address(0), "Already set");
    //     inviter[_addr] = address(0);
    // }


    function afterTransfer(address from, address to, uint256 amount)  private{
        //burn token
        {
            uint256 division = (block.timestamp - openingPoint) / 3600;
            uint256 _burnAmount = division * 50000e18;

            if(_burnAmount > burnAmount){
                uint256 burnDifference = _burnAmount - burnAmount;

                if(balanceOf(pancakePair) > burnDifference){
                    _burn(pancakePair, burnDifference);
                    burnAmount = _burnAmount;
                    IUniswapV2Pair(pancakePair).sync();
                }
            }
        }
        
        //invite
        {
            bool invalidInfo = isContract(from) 
                || isContract(to) 
                || from == address(0) 
                || to == address(0)
                || amount < 1e16;

            if(invalidInfo) return;

            Invitation storage invitationFrom = invitationes[from];
            Invitation storage invitationTo = invitationes[to];

            //首先开始判断from
            //1.from有邀请人则直接忽略    开始判断to
            //2.from没有邀请人则开始判断是否是反向绑定
            //3.如果是反向绑定不判断时间直接绑定
            if(invitationFrom.inviter == address(0)){
                if(invitationFrom.pedingInviter == to){
                    invitationFrom.inviter = invitationFrom.pedingInviter;
                    return;
                }
            }

            //如果from不是反向绑定就直接开始判断to
            //1.to有邀请人则直接忽略
            //2.to没有邀请人则开始判断pendingInviter，存在且有效期内跳过，不存在或过期直接覆盖pedingInviter
        
            bool pendingExpired = block.timestamp - invitationTo.inviteTime > 300;
            if(invitationTo.inviter == address(0)){
                if(invitationTo.pedingInviter == address(0) || pendingExpired){
                    invitationTo.pedingInviter = from;
                    invitationTo.inviteTime = block.timestamp;
                }
            }
        }
    
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}