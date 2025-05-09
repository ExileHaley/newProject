// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
// import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
// import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
// import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";
// import {TransferHelper} from "./libraries/TransferHelper.sol";
// import {IMiningV1} from "./interfaces/IMiningV1.sol";

// interface IToken {
//     function mint(address to, uint256 amount) external;
// }

// contract MiningV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable, IMiningV1, ReentrancyGuard{

//     address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
//     address public constant uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
//     address public constant uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
//     address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
//     uint256 public constant STAKE_PERIOD = 2592000;       // 30 天为一期
//     uint256 public constant BASE           = 10000;      // 百分比基数
//     uint256 public constant REWARD_RATE    = 3000;       // 30% 对应 3000/10000


//     mapping(address => address) public inviter;
//     mapping(address => uint256) public award;
//     mapping(address => uint256) public invitePerformance;
//     mapping(address => Level) public level;
//     mapping(address => uint256[]) stakingOrdersIndexes;
//     mapping(address => address[]) invitees;

//     //order info
//     mapping(uint256 => StakingOrder) public stakingOrderInfo;
    
//     address public token;
//     address public lp;
//     uint256 public index;

//     function initialize(address _token, address _lp) public initializer {
//         __Ownable_init_unchained(_msgSender());
//         __UUPSUpgradeable_init_unchained();
//         token = _token;
//         lp = _lp;
//         index = 0;
//     }

//      // Authorize contract upgrades only by the owner
//     function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

//     function setConfig(address _token, address _lp) external onlyOwner {
//         require(_token != address(0), "Zero address");
//         token = _token;
//         lp = _lp;
//     }

//     function getUserInfo(address _user) external view returns(
//         address _inviter,
//         uint256 _award,
//         uint256 _usdtValue,
//         Level _level,
//         uint256[] memory _validOrderIndexes,
//         uint256[] memory _orderIndexes,
//         address[] memory _invitees
//     ) {
//         _inviter = inviter[_user];
//         _award = award[_user];
//         _usdtValue = invitePerformance[_user];
//         _level = level[_user];
//         _invitees = invitees[_user];
//         _orderIndexes = stakingOrdersIndexes[_user];
//         _validOrderIndexes = getValidOrderIndexes(_user);
//     }

//     function getValidOrderIndexes(address _user) public view returns (uint256[] memory) {
//         // User memory user = userInfo[_user];
//         uint256 totalOrders = stakingOrdersIndexes[_user].length;
//         uint256 count = 0;

//         // 先统计未提取的订单数量
//         for (uint256 i = 0; i < totalOrders; i++) {
//             uint256 orderIndex = stakingOrdersIndexes[_user][i];
//             if (!stakingOrderInfo[orderIndex].isExtracted) {
//                 count++;
//             }
//         }

//         // 创建数组并填充有效订单索引
//         uint256[] memory validOrderIndexes = new uint256[](count);
//         uint256 j = 0;
//         for (uint256 i = 0; i < totalOrders; i++) {
//             uint256 orderIndex = stakingOrdersIndexes[_user][i];
//             if (!stakingOrderInfo[orderIndex].isExtracted) {
//                 validOrderIndexes[j] = orderIndex;
//                 j++;
//             }
//         }

//         return validOrderIndexes;
//     }

//     function bindInviter(address _inviter) external {
//         require(_inviter != msg.sender, "Cannot bind yourself as inviter.");
//         require(_inviter != address(0), "Inviter cannot be zero address.");
//         inviter[msg.sender] = _inviter;
//     }

//     function staking(uint256 amountToken) external {

//         // 测试时跳过 inviter 校验和 USDT 估值
//         // require(user.inviter != address(0), "Need to bind the inviter address.");
//         // uint256 usdtAmount = getAmountOut(token, USDT, amountToken);
//         // require(usdtAmount >= 100e18, "At least 100USDT tokens are required.");

//         TransferHelper.safeTransferFrom(token, msg.sender, DEAD, amountToken);

//         // 创建质押订单
//         StakingOrder memory order = StakingOrder({
//             holder: msg.sender,
//             amount: amountToken,
//             stakingTime: block.timestamp,
//             isExtracted: false
//         }); 

//         stakingOrderInfo[index] = order;
//         stakingOrdersIndexes[msg.sender].push(index);
//         invitees[inviter[msg.sender]].push(msg.sender);
//         index++;

//         _distributeInviteReward(msg.sender, amountToken);
//         _distributeLevelReward(msg.sender, amountToken);
//         updateLevel(msg.sender, amountToken);
//     }

//     function updateLevel(address _user, uint256 _usdtAmount) internal {
        
//         address current = _user;

//         while (current != address(0)) {
//             address _inviter = inviter[current];
//             if (_inviter == address(0)) break;

//             invitePerformance[_inviter] += _usdtAmount;

//             Level newLevel = getLevelByValue(invitePerformance[_inviter]);
//             if (uint8(newLevel) > uint8(level[_inviter])) {
//                 level[_inviter] = newLevel;
//             }

//             current = _inviter;
//         }
//     }

//     function getLevelByValue(uint256 usdtValue) internal pure returns (Level) {
//         if (usdtValue >= 1_000_000e18) return Level.V5;
//         else if (usdtValue >= 500_000e18) return Level.V4;
//         else if (usdtValue >= 200_000e18) return Level.V3;
//         else if (usdtValue >= 50_000e18) return Level.V2;
//         else if (usdtValue >= 10_000e18) return Level.V1;
//         else return Level.INVALID;
//     }

//     function _distributeInviteReward(address userAddr, uint256 baseAmount) internal {
//         address current = userAddr;
//         uint256[5] memory rates = [uint256(10000), 5000, 2500, 1250, 625]; // 单位1e3
//         uint256 totalBase = 100000;

//         uint256 validLength;
//         for (uint256 i = 0; i < 5; i++) {
//             address _inviter = inviter[current];
//             if (_inviter == address(0)) break;

//             validLength = stakingOrdersIndexes[_inviter].length;
//             if (validLength > 0 && invitees[_inviter].length >= (i + 1)) {
//                 uint256 reward = baseAmount * rates[i] / totalBase;
//                 award[_inviter] += reward;
//                 emit AwardRecordEvent(_inviter, userAddr, baseAmount, reward, block.timestamp, false);
//             }

//             current = _inviter;
//         }

//     }

//     function _distributeLevelReward(address userAddr, uint256 baseAmount) internal {
//         address current = userAddr;
//         uint256 totalBase = 10000;
//         uint256 levelRewardTotal = (baseAmount * 100) / totalBase; // 1%
//         uint256 perLevelReward = levelRewardTotal / 5;

//         uint8 claimedFlag = 0; // 每个 bit 表示对应 level 是否已领奖
//         uint8 claimedCount = 0;

//         while (current != address(0) && claimedCount < 5) {
//             address _inviter = inviter[current];
//             if (_inviter == address(0)) break;

//             // User storage up = userInfo[inviter];
//             Level lvl = level[_inviter];

//             if (lvl != Level.INVALID) {
//                 uint8 lvlIndex = uint8(lvl) - 1;
//                 if (lvlIndex < 5 && (claimedFlag & (1 << lvlIndex)) == 0) {
//                     uint256 accumulated = 0;

//                     // 从当前级别开始向下找尚未领取的 level
//                     for (uint8 i = 0; i <= lvlIndex; i++) {
//                         if ((claimedFlag & (1 << i)) == 0) {
//                             claimedFlag |= uint8(1 << i); // ✅ 明确转型解决类型错误
//                             accumulated += perLevelReward;
//                             claimedCount++;
//                         }
//                     }


//                     if (accumulated > 0) {
//                         award[_inviter] += accumulated;
//                         emit AwardRecordEvent(_inviter, userAddr, baseAmount, accumulated, block.timestamp, true);
//                     }
//                 }
//             }

//             current = _inviter;
//         }
//     }

    
//     // ------------------------------------------------------------
//     // 1. 查询单个订单的“实时收益”
//     // ------------------------------------------------------------
//     function getOrderRealTimeYield(uint256 orderIndex) public view returns (uint256) {
//         StakingOrder memory order = stakingOrderInfo[orderIndex];

//         // 计算总收益 = 本金 + 奖励部分
//         uint256 totalYield = order.amount + (order.amount * REWARD_RATE / BASE);  

//         uint256 elapsed = block.timestamp > order.stakingTime
//                                     ? block.timestamp - order.stakingTime
//                                     : 0;

//         if (elapsed >= STAKE_PERIOD) return totalYield;
//         else return elapsed * (totalYield / STAKE_PERIOD);

//     }

//     // ------------------------------------------------------------
//     // 2. 查询某个用户所有“未提取”订单的实时收益总和
//     // ------------------------------------------------------------
//     function getUserRealTimeYield(address userAddr) external view returns (uint256 total) {
//         // User storage user = userInfo[userAddr];
//         uint256 len = stakingOrdersIndexes[userAddr].length;

//         for (uint256 i = 0; i < len; i++) {
//             uint256 idx = stakingOrdersIndexes[userAddr][i];
//             if (!stakingOrderInfo[idx].isExtracted) {
//                 total += getOrderRealTimeYield(idx);
//             }
//         }
//     }

//     function getOrderCountdown(uint256 orderIndex) public view returns (uint256) {
//         StakingOrder memory order = stakingOrderInfo[orderIndex];
//         uint256 elapsed = block.timestamp > order.stakingTime
//                                     ? block.timestamp - order.stakingTime
//                                     : 0;
//         if (elapsed >= STAKE_PERIOD) return 0;
//         return STAKE_PERIOD - elapsed;
//     }

//     function claimOrder(uint256 orderIndex) external nonReentrant {
//         StakingOrder storage order = stakingOrderInfo[orderIndex];
//         require(order.holder == msg.sender, "Not the order owner.");
//         require(!order.isExtracted, "Already claimed.");

//         uint256 yield = 0;
//         yield = getOrderRealTimeYield(orderIndex);
//         order.isExtracted = true;

//         IToken(token).mint(msg.sender, yield);
//     }

//     function claimAward(uint256 amount) external nonReentrant {
//         // User storage user = userInfo[msg.sender];
//         require(award[msg.sender] >= amount, "No award to claim.");
//         award[msg.sender] -= amount;
//         IToken(token).mint(msg.sender, amount);
//     }


//     function getUserValidStakingAmount(address userAddr) public view returns (uint256 totalAmount) {
//         // User storage user = userInfo[userAddr];
//         uint256 len = stakingOrdersIndexes[userAddr].length;

//         for (uint256 i = 0; i < len; i++) {
//             uint256 idx = stakingOrdersIndexes[userAddr][i];
//             if (!stakingOrderInfo[idx].isExtracted) {
//                 totalAmount += stakingOrderInfo[idx].amount;
//             }
//         }
//     }

//     function getUserValidStakingAmountForUsdt(address userAddr) external view returns (uint256 totalUsdt){
//         return getAmountOut(token, USDT, getUserValidStakingAmount(userAddr));
//     }

//     function getAmountOut(address token0, address token1, uint256 token0Amount) public view returns (uint256) {
//         address[] memory path = new address[](2);
//         path[0] = token0;
//         path[1] = token1;

//         uint[] memory amounts = IUniswapV2Router02(uniswapV2Router).getAmountsOut(token0Amount, path);
//         return amounts[1];
//     }
    
//     function getQuoteAmount(uint256 amountToken) external view returns(uint256 amountUsdt){
//         return getAmountOut(token, USDT, amountToken);
//     }

// }