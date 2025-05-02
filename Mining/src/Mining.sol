// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IMining} from "./interfaces/IMining.sol";

interface IToken {
    function mint(address to, uint256 amount) external;
}

contract Mining is Initializable, OwnableUpgradeable, UUPSUpgradeable, IMining, ReentrancyGuard{
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant STAKE_PERIOD = 2592000;       // 30 天为一期
    uint256 public constant BASE           = 10000;      // 百分比基数
    uint256 public constant REWARD_RATE    = 3000;       // 30% 对应 3000/10000

    address public token;
    address public lp;
    uint256 public index;
    // address public initialInviter;

    mapping(uint256 => StakingOrder) public stakingOrderInfo;
    mapping(address => User) public userInfo;
    StakingOrder[] public stakingOrders;
    
    function initialize(address _token, address _lp) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        token = _token;
        lp = _lp;
        index = 0;
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setConfig(address _token, address _lp) external onlyOwner {
        require(_token != address(0), "Zero address");
        token = _token;
        lp = _lp;
    }

    function getValidOrderIndexes(address _user) public view returns (uint256[] memory) {
        User memory user = userInfo[_user];
        uint256 totalOrders = user.stakingOrdersIndexes.length;
        uint256 count = 0;

        // 先统计未提取的订单数量
        for (uint256 i = 0; i < totalOrders; i++) {
            uint256 orderIndex = user.stakingOrdersIndexes[i];
            if (!stakingOrderInfo[orderIndex].isExtracted) {
                count++;
            }
        }

        // 创建数组并填充有效订单索引
        uint256[] memory validOrderIndexes = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < totalOrders; i++) {
            uint256 orderIndex = user.stakingOrdersIndexes[i];
            if (!stakingOrderInfo[orderIndex].isExtracted) {
                validOrderIndexes[j] = orderIndex;
                j++;
            }
        }

        return validOrderIndexes;
    }


    function getUserInfo(address _user) external view returns(
        address _inviter,
        uint256 _award,
        uint256 _usdtValue,
        Level _level,
        uint256[] memory _validOrderIndexes,
        uint256[] memory _orderIndexes,
        address[] memory _invitees,
        AwardRecord[] memory _awardRecords
    ) {
        User memory user = userInfo[_user];
        _inviter = user.inviter;
        _award = user.award;
        _usdtValue = user.usdtValue;
        _level = user.level;
        _invitees = user.invitees;
        _awardRecords = user.awardRecords;
        _orderIndexes = user.stakingOrdersIndexes;
        _validOrderIndexes = getValidOrderIndexes(_user);
    }


    function getQuoteAmount(uint256 amountToken) public view returns(uint256 amountUsdt){
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, token, USDT);
        amountUsdt = UniswapV2Library.quote(amountToken, reserveA, reserveB);
    }

    function staking(uint256 amountToken) external {
        User storage user = userInfo[msg.sender];
        //require(user.inviter != address(0), "Need to bind the inviter address.");
        //测试
        // require(getQuoteAmount(amountToken) >= 100e18, "At least 100USDT tokens are required.");
        TransferHelper.safeTransferFrom(token, msg.sender, DEAD, amountToken);
        StakingOrder memory order = StakingOrder({
            holder: msg.sender,
            amount: amountToken,
            stakingTime: block.timestamp,
            isExtracted: false
        }); 
        stakingOrders.push(order);
        stakingOrderInfo[index] = order;
        user.stakingOrdersIndexes.push(index);
        userInfo[user.inviter].invitees.push(msg.sender);
        index++;

        distribute(msg.sender, amountToken);
        updateLevel(msg.sender, amountToken);
    }

    function updateLevel(address _user, uint256 _amount) internal{
        // uint256 usdtAmount = getQuoteAmount(_amount);
        //测试
        uint256 usdtAmount = _amount;
        address current = _user;
        while(current != address(0)){
            address inviter = userInfo[current].inviter;
            if(inviter == address(0)) break;
            userInfo[inviter].usdtValue += usdtAmount;
            Level newLevel = getLevelByValue(userInfo[inviter].usdtValue);
            if (uint(newLevel) > uint(userInfo[inviter].level)) {
                userInfo[inviter].level = newLevel;
            }

            current = inviter;
        }

    }
    
    function getLevelByValue(uint256 usdtValue) internal pure returns (Level) {
        if (usdtValue >= 1_000_000e18) return Level.V5;
        else if (usdtValue >= 500_000e18) return Level.V4;
        else if (usdtValue >= 200_000e18) return Level.V3;
        else if (usdtValue >= 50_000e18) return Level.V2;
        else if (usdtValue >= 10_000e18) return Level.V1;
        else return Level.INVALID;
    }

    function distribute(address _user, uint256 _amountToken) internal {
        address current = _user;
        uint256[5] memory rates = [uint256(1000), 500, 250, 125, 625]; // 单位为1e3，即10% = 1000/10000
        uint256 totalBase = 10000;
        uint256 baseAmount = _amountToken;

        // ------ 1. 邀请人奖励 ------
        for (uint256 i = 0; i < 5; i++) {
            address inviter = userInfo[current].inviter;
            if (inviter == address(0)) break;

            if (userInfo[inviter].invitees.length >= (i + 1) && getValidOrderIndexes(inviter).length > 0) {
                uint256 reward = baseAmount * rates[i] / totalBase;
                userInfo[inviter].award += reward;

                userInfo[inviter].awardRecords.push(AwardRecord({
                    invitee: _user,
                    stakingAmount: _amountToken,
                    awardAmount: reward,
                    awardTime: block.timestamp,
                    isLevelAward: false
                }));
            }

            current = inviter;
        }

        // ------ 2. 按等级分配 1% 总奖励 ------
        uint256 levelRewardTotal = baseAmount * 100 / totalBase; // 1%
        uint256 perLevelReward = levelRewardTotal / 5;
        bool[5] memory levelRewardClaimed;
        uint256 pendingLevels = 0;

        current = _user;

        while (current != address(0)) {
            address inviter = userInfo[current].inviter;
            if (inviter == address(0)) break;

            Level lvl = userInfo[inviter].level;
            if (lvl != Level.INVALID) {
                uint256 lvlIndex = uint256(lvl) - 1; // Level 枚举从 1 开始

                // 如果这个等级未被领取
                if (lvlIndex < 5 && !levelRewardClaimed[lvlIndex]) {
                    // 统计还未被领取的所有等级奖励
                    uint256 accumulatedReward = 0;

                    for (uint256 i = 0; i <= lvlIndex; i++) {
                        if (!levelRewardClaimed[i]) {
                            accumulatedReward += perLevelReward;
                            levelRewardClaimed[i] = true; // 标记为已领取
                            pendingLevels++;
                        }
                    }

                    // 发放累计奖励给当前 inviter
                    if (accumulatedReward > 0) {
                        userInfo[inviter].award += accumulatedReward;
                        AwardRecord memory record;
                        record.invitee = _user;
                        record.stakingAmount = _amountToken;
                        record.awardAmount = accumulatedReward;
                        record.awardTime = block.timestamp;
                        record.isLevelAward = true;

                        userInfo[inviter].awardRecords.push(record);

                    }
                }
            }

            // 所有等级奖励已分配完，提前跳出
            if (pendingLevels >= 5) break;

            current = inviter;
        }

    }

    function bindInviter(address inviter) external {
        require(inviter != msg.sender, "Cannot bind yourself as inviter.");
        require(userInfo[msg.sender].inviter == address(0), "Inviter already bound.");
        require(inviter != address(0), "Inviter cannot be zero address.");
        userInfo[msg.sender].inviter = inviter;
        // userInfo[inviter].invitees.push(msg.sender);
    }


    // ------------------------------------------------------------
    // 1. 查询单个订单的“实时收益”
    // ------------------------------------------------------------

    function getOrderRealTimeYield(uint256 orderIndex) public view returns (uint256) {
        StakingOrder memory order = stakingOrderInfo[orderIndex];

        // 计算总收益 = 本金 + 奖励部分
        uint256 totalYield = order.amount + (order.amount * REWARD_RATE / BASE);  

        uint256 elapsed = block.timestamp > order.stakingTime
                                    ? block.timestamp - order.stakingTime
                                    : 0;

        if (elapsed >= STAKE_PERIOD) return totalYield;
        else return elapsed * (totalYield / STAKE_PERIOD);

    }

    // ------------------------------------------------------------
    // 2. 查询某个用户所有“未提取”订单的实时收益总和
    // ------------------------------------------------------------
    function getUserRealTimeYield(address userAddr) external view returns (uint256 total) {
        User storage user = userInfo[userAddr];
        uint256 len = user.stakingOrdersIndexes.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 idx = user.stakingOrdersIndexes[i];
            if (!stakingOrderInfo[idx].isExtracted) {
                total += getOrderRealTimeYield(idx);
            }
        }
    }

    function getOrderCountdown(uint256 orderIndex) public view returns (uint256) {
        StakingOrder memory order = stakingOrderInfo[orderIndex];
        uint256 elapsed = block.timestamp > order.stakingTime
                                    ? block.timestamp - order.stakingTime
                                    : 0;
        if (elapsed >= STAKE_PERIOD) return 0;
        return STAKE_PERIOD - elapsed;
    }

    function claimOrder(uint256 orderIndex) external nonReentrant {
        StakingOrder storage order = stakingOrderInfo[orderIndex];
        require(order.holder == msg.sender, "Not the order owner.");
        require(!order.isExtracted, "Already claimed.");

        uint256 yield = 0;
        yield = getOrderRealTimeYield(orderIndex);
        order.isExtracted = true;

        IToken(token).mint(msg.sender, yield);
    }

    function claimAward(uint256 amount) external nonReentrant {
        User storage user = userInfo[msg.sender];
        require(user.award >= amount, "No award to claim.");
        user.award -= amount;
        IToken(token).mint(msg.sender, amount);
    }


    function getStakingOrders() external view returns (StakingOrder[] memory) {
        return stakingOrders;
    }

    function getUserValidStakingAmount(address userAddr) public view returns (uint256 totalAmount) {
        User storage user = userInfo[userAddr];
        uint256 len = user.stakingOrdersIndexes.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 idx = user.stakingOrdersIndexes[i];
            if (!stakingOrderInfo[idx].isExtracted) {
                totalAmount += stakingOrderInfo[idx].amount;
            }
        }
    }

    function getUserValidStakingAmountForUsdt(address userAddr) external view returns (uint256 totalUsdt){
        return getQuoteAmount(getUserValidStakingAmount(userAddr));
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
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

    function addLiquidity(uint256 amountToken) external returns(uint256 _amountToken, uint256 _amountUsdt, uint256 _liquidityAmount) {
        uint256 amountUsdt = getQuoteAmount(amountToken);

        (_amountToken, _amountUsdt, _liquidityAmount) = addLiquidity(
            token, 
            USDT, 
            amountToken, 
            amountUsdt, 
            0, 
            0, 
            msg.sender, 
            block.timestamp
        );

    }

    function removeLiquidity(uint256 _liquidity) external {
        TransferHelper.safeTransferFrom(lp, msg.sender, address(this), _liquidity);
        IERC20(lp).approve(uniswapV2Router, _liquidity);
        IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            USDT, 
            token, 
            _liquidity, 
            0, 
            0, 
            msg.sender, 
            block.timestamp
        );
        
    }

    function serchLiquidityBalance(address _user) external view returns(uint256){
        return IERC20(lp).balanceOf(_user);
    }


}
