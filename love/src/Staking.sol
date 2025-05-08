// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
// import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
// import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
// import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IStaking} from "./interfaces/IStaking.sol";

contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, IStaking, ReentrancyGuard{

    // enum Expired{EXPIRED30,EXPIRED60,EXPIRED90}
    mapping(Expired => uint256) public expiredTime;
    mapping(Expired => uint256) public yieldRate;

    // struct StakingOrder{
    //     Expired expired;
    //     address holder;
    //     uint256 amount;
    //     uint256 stakingTime;
    //     uint256 extracted;
    //     bool    isRedeemed;
    // }

    // struct AwardRecord{
    //     address invitee;
    //     uint256 stakingAmount;
    //     uint256 awardAmount;
    //     uint256 awardTime;
    // }

    // struct User{
    //     address inviter;  
    //     uint256 award;
    //     uint256[] stakingOrdersIndexes;
    //     address[] invitees;
    //     AwardRecord[] awardRecords;
    // }

    mapping(uint256 => StakingOrder) public stakingOrderInfo;
    mapping(address => User) public userInfo;
    
    address public initialInviter;
    address public love;
    address public best;
    uint256 public index;

    function initialize(address _initialInviter, address _love, address _best) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        initialInviter = _initialInviter;
        love = _love;
        best = _best;
        expiredTime[Expired.EXPIRED30] = 30 days;
        expiredTime[Expired.EXPIRED60] = 60 days;
        expiredTime[Expired.EXPIRED90] = 90 days;

        //30 days 100
        //60 days 220
        //90 days 400
        yieldRate[Expired.EXPIRED30] = 100;
        yieldRate[Expired.EXPIRED60] = 220;
        yieldRate[Expired.EXPIRED90] = 400;
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setConfig(address _love, address _best) external onlyOwner {
        require(_love != address(0) && _best != address(0), "Zero address");
        love = _love;
        best = _best;
    }

    function getUserInfo(address _user) external view returns(
        address _inviter,
        uint256 _award,
        uint256[] memory _validOrderIndexes,
        uint256[] memory _allOrderIndexes,
        address[] memory _invitees,
        AwardRecord[] memory _awardRecords
    ) {
        User memory user = userInfo[_user];
        _inviter = user.inviter;
        _award = user.award;
        _invitees = user.invitees;
        _awardRecords = user.awardRecords;
        _allOrderIndexes = user.stakingOrdersIndexes;
        _validOrderIndexes = getValidOrderIndexes(_user);
    }

    function bindInviter(address _inviter) external {
        require(_inviter != msg.sender && _inviter != address(0), "Cannot bind yourself or 0x as inviter.");
        require(userInfo[msg.sender].inviter == address(0), "Inviter already bound.");
        if(_inviter != initialInviter) require(userInfo[_inviter].stakingOrdersIndexes.length > 0, "Inviter not staked.");
        userInfo[msg.sender].inviter = _inviter;
        userInfo[_inviter].invitees.push(msg.sender);
    }

    function staking(Expired _expired, uint256 _amountLove) external nonReentrant{
        require(userInfo[msg.sender].inviter != address(0), "Please bind an inviter first.");
        require(_amountLove > 0, "Amount must be greater than 0");
        TransferHelper.safeTransferFrom(love, msg.sender, address(this), _amountLove);
        index++;
        StakingOrder memory order = StakingOrder({
            expired: _expired,
            holder: msg.sender,
            amount: _amountLove,
            stakingTime: block.timestamp,
            extracted: 0,
            isRedeemed: false
        });
        userInfo[msg.sender].stakingOrdersIndexes.push(index);
        stakingOrderInfo[index] = order;
        updateAward(msg.sender, _amountLove);
    }

    function updateAward(address _user, uint256 _amount) internal {
        address _inviter = userInfo[_user].inviter;
        if(_inviter != address(0)){
            userInfo[_inviter].award += _amount * 8 / 100;
            userInfo[_inviter].awardRecords.push(AwardRecord({
                invitee: _user,
                stakingAmount: _amount,
                awardAmount: _amount * 8 / 100,
                awardTime: block.timestamp
            }));

            address _upInviter = userInfo[_inviter].inviter;
            if(_upInviter != address(0)){
                userInfo[_upInviter].award += _amount * 5 / 100;
                userInfo[_upInviter].awardRecords.push(AwardRecord({
                    invitee: _user,
                    stakingAmount: _amount,
                    awardAmount: _amount * 5 / 100,
                    awardTime: block.timestamp
                }));
            }
        }
    }

    function getValidOrderIndexes(address _user) internal view returns(uint256[] memory){
        User memory user = userInfo[_user];
        uint256 totalOrders = user.stakingOrdersIndexes.length;
        uint256 count = 0;

        // 先统计未提取的订单数量
        for (uint256 i = 0; i < totalOrders; i++) {
            uint256 orderIndex = user.stakingOrdersIndexes[i];
            if (!stakingOrderInfo[orderIndex].isRedeemed) {
                count++;
            }
        }

        // 创建数组并填充有效订单索引
        uint256[] memory validOrderIndexes = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < totalOrders; i++) {
            uint256 orderIndex = user.stakingOrdersIndexes[i];
            if (!stakingOrderInfo[orderIndex].isRedeemed) {
                validOrderIndexes[j] = orderIndex;
                j++;
            }
        }

        return validOrderIndexes;
    }

    function getOrderRealTimeYield(uint256 _orderIndex) public view returns (uint256) {
        StakingOrder memory order = stakingOrderInfo[_orderIndex];
        require(order.holder != address(0), "Invalid order");
        //总到期时间
        uint256 totalDuration = expiredTime[order.expired];
        //奖励率，这里是总量
        uint256 ratePerLove = yieldRate[order.expired];
        //总奖励是数量*ratePerLove
        uint256 totalReward = order.amount * ratePerLove;

        uint256 elapsed = block.timestamp > order.stakingTime
            ? block.timestamp - order.stakingTime
            : 0;

        // 不超过质押周期
        if (elapsed > totalDuration) {
            elapsed = totalDuration;
        }

        uint256 unlocked = totalReward * elapsed / totalDuration;
        return unlocked > order.extracted ? unlocked - order.extracted : 0;
    }


    function getOrderCountdown(uint256 _orderIndex) public view returns (uint256) {
        StakingOrder memory order = stakingOrderInfo[_orderIndex];
        require(order.holder != address(0), "Invalid order");

        // 获取订单总时长
        uint256 duration = expiredTime[order.expired];
        // 到期时间戳
        uint256 endTime = order.stakingTime + duration;

        // 如果已经过期或是90天类型，直接返回 0
        if (block.timestamp >= endTime || order.expired == Expired.EXPIRED90) {
            return 0;
        }

        return endTime - block.timestamp;
    }


    function redeem(uint256 _orderIndex) external nonReentrant {
        StakingOrder storage order = stakingOrderInfo[_orderIndex];
        require(order.holder == msg.sender, "Not order owner");
        require(!order.isRedeemed, "Already redeemed");

        // 禁止赎回90天的订单
        require(order.expired != Expired.EXPIRED90, "Cannot redeem 90-day orders");

        // 计算当前未提取收益
        uint256 yieldAmount = getOrderRealTimeYield(_orderIndex);

        // 标记为已赎回
        order.isRedeemed = true;
        order.extracted += yieldAmount;

        // 转出LOVE本金
        TransferHelper.safeTransfer(love, msg.sender, order.amount);

        // 转出BEST收益（如果有）
        if (yieldAmount > 0) {
            TransferHelper.safeTransfer(best, msg.sender, yieldAmount);
        }
    }


    function claimOrder(uint256 _orderIndex) external nonReentrant {
        StakingOrder storage order = stakingOrderInfo[_orderIndex];
        require(order.holder == msg.sender, "Not order owner");
        require(!order.isRedeemed, "Order already redeemed");

        uint256 yieldAmount = getOrderRealTimeYield(_orderIndex);
        require(yieldAmount > 0, "No yield available");

        // 更新已提取收益
        order.extracted += yieldAmount;

        // 发放奖励
        TransferHelper.safeTransfer(best, msg.sender, yieldAmount);
    }


    function claimAward(uint256 _amount) external nonReentrant {
        User storage user = userInfo[msg.sender];
        require(user.award >= _amount, "Insufficient award balance");
        
        // 扣除已领取的奖励
        user.award -= _amount;

        // 发放奖励
        TransferHelper.safeTransfer(love, msg.sender, _amount);
    }

}
