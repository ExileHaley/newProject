// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {UniswapV2Library} from "./library/UniswapV2Library.sol";
import {TransferHelper} from "./library/TransferHelper.sol";
import {IUniswapV2Router02} from "./interface/IUniswapV2Router02.sol";
import {IERC20} from "./interface/IERC20.sol";
import {ReentrancyGuard} from "./library/ReentrancyGuard.sol";
import {IUniswapV2Factory} from "./interface/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "./interface/IUniswapV2Pair.sol";


interface IToken{
    function invitationes(address user) external view returns(address pending, address inviter, uint256 time);
    function mint(address user, uint256 amount) external;
}

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{

    struct StakingLiquidity {
        uint256 usdtBalance;
        uint256 lpBalance;
        uint256 stakingTime;
        uint256 pending;
        uint256 debt;
    }
    mapping(address => StakingLiquidity) public stakingLiquidityInfo;

    struct StakingSingleOrder {
        address holder;
        uint256 tokenBalance;
        uint256 stakingTime;
        bool    extracted;
    }
    mapping(uint256 => StakingSingleOrder) public stakingSingleOrderInfo;
    StakingSingleOrder[] public stakingSingleOrders;
    mapping(address => uint256[]) public stakingSingleOrdersIndexes;
    mapping(address => uint256) public stakingSingleInviteIncome;


    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public constant dead = 0x000000000000000000000000000000000000dEaD;
    address public token;
    address public lp;
    address public constant uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    uint256 public totalStakingLiquidity;
    uint256 public perStakingReward;

    // uint256 public feeRate;
    // uint256 public lpRewardRate;
    uint256 public index;

    receive() external payable{}

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    function initialize(
        address _token,
        address _lp
    ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        token = _token;
        lp = _lp;
        index = 1;
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function getInviter(address user) public view returns(address){
        (, address inviter,) = IToken(token).invitationes(user);
        return inviter;
    }

    function getQuoteAmount(uint256 amountToken) public view returns(uint256 amountUsdt){
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, token, usdt);
        amountUsdt = UniswapV2Library.quote(amountToken, reserveA, reserveB);
    }

    function getUsdtForTokenAmount(uint256 amountUsdt) public view returns(uint256 amountToken){
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, usdt, token);
        amountToken = UniswapV2Library.quote(amountUsdt, reserveA, reserveB);
    }

    /********************************************************pull***********************************************************/
    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(uniswapV2Factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(uniswapV2Factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /********************************************************pull***********************************************************/

    function provide(uint256 amountToken) external{
        StakingLiquidity storage stakingLiquidity = stakingLiquidityInfo[msg.sender];
        uint256 amountUsdt = getQuoteAmount(amountToken);
        //添加流动性
        (, uint256 _usdtAmount, uint256 _liquidityAmount) = addLiquidity(
            token, 
            usdt, 
            amountToken, 
            amountUsdt, 
            0, 
            0, 
            address(this), 
            block.timestamp
        );
        //数据更新
        //获取收益有问题导致的测试失败
        updateLiquidityReward(msg.sender);
        stakingLiquidity.usdtBalance += _usdtAmount * 2;
        stakingLiquidity.lpBalance += _liquidityAmount;
        stakingLiquidity.debt = stakingLiquidity.lpBalance * perStakingReward;
        totalStakingLiquidity += _liquidityAmount;
    }

    function updateLiquidityReward(address user) internal {
        stakingLiquidityInfo[user].pending += getLiquidityTruthIncome(user);
        stakingLiquidityInfo[user].stakingTime = block.timestamp;
    }

    // event RemoveLiquidityTokenAmount(uint256 returnAmount, uint256 fees, uint256 sendAmount, uint256 tokenBalance);
    function removeLiquidity() public {
        StakingLiquidity storage stakingLiquidity = stakingLiquidityInfo[msg.sender];

        IERC20(lp).approve(uniswapV2Router, stakingLiquidity.lpBalance);

        (uint256 _tokenAmount,uint256 _usdtAmount) = IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            token, 
            usdt, 
            stakingLiquidity.lpBalance, 
            0, 
            0, 
            address(this), 
            block.timestamp + 10
        );
        TransferHelper.safeTransfer(usdt, msg.sender, _usdtAmount);
        uint256 sendAmount = _tokenAmount * 98 / 100;
        TransferHelper.safeTransfer(token, msg.sender, sendAmount);
        TransferHelper.safeTransfer(token, dead, IERC20(token).balanceOf(address(this)));

        uint256 income = getLiquidityTruthIncome(msg.sender);
        uint256 incomeFee = income * 10 / 100;

        IToken(token).mint(msg.sender,income - incomeFee);
        totalStakingLiquidity -= stakingLiquidity.lpBalance;
        delete stakingLiquidityInfo[msg.sender];
        update(incomeFee);
        
    }

    function getStakingLiquidityIncome(address user) public view returns(uint256 income){
        StakingLiquidity memory stakingLiquidity = stakingLiquidityInfo[user];
        if(stakingLiquidity.usdtBalance > 0){
            uint256 tokenPrincipal = getUsdtForTokenAmount(stakingLiquidity.usdtBalance);
            uint256 tokenIncomeForSecond = tokenPrincipal * 5 / 1000 / 86400;
            uint256 middle = block.timestamp - stakingLiquidity.stakingTime;
            income = tokenIncomeForSecond * middle;
        }
    }

    function getMinerLiquidityIncome(address user) public view returns(uint256){
        StakingLiquidity memory stakingLiquidity = stakingLiquidityInfo[user];
        return stakingLiquidity.lpBalance * perStakingReward - stakingLiquidity.debt;
    }

    function getLiquidityTruthIncome(address user) public view returns(uint256){
        StakingLiquidity memory stakingLiquidity = stakingLiquidityInfo[user];
        return getMinerLiquidityIncome(user) / 1e13 + getStakingLiquidityIncome(user) + stakingLiquidity.pending;
    }


    function claimLiquidity(address user, uint256 amount) public {
        StakingLiquidity storage stakingLiquidity = stakingLiquidityInfo[user];
        updateLiquidityReward(user);
        require(stakingLiquidity.pending >= amount, "Amount is greater than income");
        stakingLiquidity.pending -= amount;
        stakingLiquidity.debt = stakingLiquidity.lpBalance * perStakingReward;
        uint256 currentFee = amount * 10 / 100;
        IToken(token).mint(user, amount - currentFee);
        update(currentFee);
    }

    function update(uint256 amount) internal{
        if(totalStakingLiquidity == 0) perStakingReward += amount * 1e13;
        else perStakingReward += (amount * 1e13 / totalStakingLiquidity);
    }

    function getOrderStatus(uint256 orderId) external view returns(uint256){
        StakingSingleOrder storage stakingSingle = stakingSingleOrderInfo[orderId];
        if(block.timestamp >= stakingSingle.stakingTime + 10 days) return 0;
        else return 10 days - (block.timestamp - stakingSingle.stakingTime);
    }
    
    function staking(uint256 tokenAmount) external{
        // require(tokenAmount >= getUsdtForTokenAmount(100e18),"Minimum 100 USDT");
        TransferHelper.safeTransferFrom(token, msg.sender, dead, tokenAmount);
        StakingSingleOrder memory stakingSingle = StakingSingleOrder({
            holder: msg.sender,
            tokenBalance: tokenAmount,
            stakingTime: block.timestamp,
            extracted: false
        });
        stakingSingleOrders.push(stakingSingle);
        stakingSingleOrdersIndexes[msg.sender].push(index);
        stakingSingleOrderInfo[index] = stakingSingle;
        index++;
        
        address up = getInviter(msg.sender);
        if(up != address(0)) stakingSingleInviteIncome[up] += (tokenAmount * 5 / 100);

        address upper = getInviter(up);
        if(upper != address(0)) stakingSingleInviteIncome[upper] += (tokenAmount * 2 / 100);
    }

    function withdraw(uint256 orderId) external{
        StakingSingleOrder storage stakingSingle = stakingSingleOrderInfo[orderId];
        require(stakingSingle.holder == msg.sender, "Not the owner of this order");
        require(!stakingSingle.extracted, "Already extracted");
        require(block.timestamp - stakingSingle.stakingTime >= 10 days, "Staking time is not enough");
        uint256 income = getUserSingleIncome(orderId);
        IToken(token).mint(msg.sender, income);
        stakingSingle.extracted = true;
    }

    function getUserSingleIncome(uint256 orderId) public view  returns(uint256){
        StakingSingleOrder storage stakingSingle = stakingSingleOrderInfo[orderId];

        uint256 totalExpectedIncome = stakingSingle.tokenBalance + (stakingSingle.tokenBalance * 10 / 100);
        uint256 tokenIncomeForSecond = totalExpectedIncome / 10 days;
        uint256 middle = block.timestamp - stakingSingle.stakingTime;
        uint256 totalIncome = tokenIncomeForSecond * middle;

        if(stakingSingle.extracted) return 0;
        else if(totalIncome >= totalExpectedIncome) return totalExpectedIncome;
        else return totalIncome;
        
    }

    function getValidOrder(address user) external view returns(uint256[] memory orderIds){
        uint256[] memory orderIndexes = stakingSingleOrdersIndexes[user];
        uint256 validCount = 0;
        for(uint256 i = 0; i < orderIndexes.length; i++){
            if(!stakingSingleOrderInfo[orderIndexes[i]].extracted) validCount++;
        }

        orderIds = new uint256[](validCount);
        uint256 j = 0;
        for(uint256 i = 0; i < orderIndexes.length; i++){
            if(!stakingSingleOrderInfo[orderIndexes[i]].extracted){
                orderIds[j] = orderIndexes[i];
                j++;
            }
        }
    }

    
}