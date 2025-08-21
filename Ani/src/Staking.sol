// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {TransferHelper} from "./TransferHelper.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Staking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    
    enum Period {
        INVALID,
        ONE_DAY,
        SEVEN_DAYS,
        ONE_MONTH,
        THREE_MONTHS,
        ONE_YEAR
    }
    struct StakingOrder {
        address holder;
        uint256 aniAmount;
        uint256 stakingTime;
        uint256 withdrawnEarnings; //当前订单已提取收益
        Period  period;
        bool    extracted;
    }
    mapping(uint256 => StakingOrder) public stakingOrderInfo;
    mapping(address => uint256[]) public stakingOrdersIds;
    mapping(Period => uint256) public perTokenPerSecondFP;
    mapping(Period => uint256) public periodSeconds;


    address public aniToken;
    address public agiToken;
    uint256 public nextOrderId;

    address public admin;

    uint256 public constant MIN_STAKE = 10000 * 1e18;

     // --- Events ---
    event Staked(address indexed user, uint256 indexed orderId, uint256 amount, Period period);
    event Claimed(address indexed user, uint256 indexed orderId, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed orderId, uint256 principalAmount);

    receive() external payable{}

    // --- Modifiers ---
    modifier onlyHolder(uint256 orderId) {
        require(stakingOrderInfo[orderId].holder == msg.sender, "not order owner");
        _;
    }

    function initialize(address _aniToken,address _agiToken, address _admin) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        aniToken = _aniToken;
        agiToken = _agiToken;
        admin = _admin;
        nextOrderId = 1;

        // durations
        periodSeconds[Period.ONE_DAY] = 1 days;
        periodSeconds[Period.SEVEN_DAYS] = 7 days;
        periodSeconds[Period.ONE_MONTH] = 30 days;
        periodSeconds[Period.THREE_MONTHS] = 90 days;
        periodSeconds[Period.ONE_YEAR] = 365 days;

        // daily yields per 10k ANI in AGI (expressed with 18 decimals)
        // 1W = 10000 ANI -> produces X AGI per day as specified
        // translate them to per-token-per-second fixed point (scaled by 1e18):
        // perTokenPerSecondFP = (dailyYieldPer10000 * 1e18) / 10000 / 86400
        // uint256 scale = 1e18;
        uint256 d1 = 100000000000000000;   // 0.1 * 1e18
        uint256 d7 = 110000000000000000;   // 0.11 * 1e18
        uint256 d30 = 150000000000000000;  // 0.15 * 1e18
        uint256 d90 = 200000000000000000;  // 0.2  * 1e18
        uint256 d365 = 350000000000000000; // 0.35 * 1e18

        perTokenPerSecondFP[Period.ONE_DAY] = d1 / 10000 / 86400;
        perTokenPerSecondFP[Period.SEVEN_DAYS] = d7 / 10000 / 86400;
        perTokenPerSecondFP[Period.ONE_MONTH] = d30 / 10000 / 86400;
        perTokenPerSecondFP[Period.THREE_MONTHS] = d90 / 10000 / 86400;
        perTokenPerSecondFP[Period.ONE_YEAR] = d365 / 10000 / 86400;

    }

    function setPerTokenPerSecondFP() external onlyOwner {
        uint256 d1 = 1000000000000000;   // 0.1 * 1e18
        uint256 d7 = 1100000000000000;   // 0.11 * 1e18
        uint256 d30 = 1500000000000000;  // 0.15 * 1e18
        uint256 d90 = 2000000000000000;  // 0.2  * 1e18
        uint256 d365 = 3500000000000000; // 0.35 * 1e18

        perTokenPerSecondFP[Period.ONE_DAY] = d1 / 10000 / 86400;
        perTokenPerSecondFP[Period.SEVEN_DAYS] = d7 / 10000 / 86400;
        perTokenPerSecondFP[Period.ONE_MONTH] = d30 / 10000 / 86400;
        perTokenPerSecondFP[Period.THREE_MONTHS] = d90 / 10000 / 86400;
        perTokenPerSecondFP[Period.ONE_YEAR] = d365 / 10000 / 86400;
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function stake(uint256 amount, Period period) external nonReentrant {
        require(amount >= MIN_STAKE, "stake at least 10000 ANI");
        require(periodSeconds[period] != 0, "invalid period");

        // transfer ani in
        TransferHelper.safeTransferFrom(aniToken, msg.sender, address(this), amount);

        uint256 id = nextOrderId;
        stakingOrderInfo[id] = StakingOrder({
            holder: msg.sender,
            aniAmount: amount,
            stakingTime: block.timestamp,
            withdrawnEarnings: 0,
            period: period,
            extracted: false
        });
        stakingOrdersIds[msg.sender].push(id);
        nextOrderId++;
        emit Staked(msg.sender, id, amount, period);

    }


    /// @notice Claim accumulated AGI rewards for a specific order (without withdrawing principal)
    function claimEarnings(uint256 orderId) external nonReentrant onlyHolder(orderId) {
        uint256 pending = _pendingForOrder(orderId);
        require(pending > 0, "no pending rewards");

        // update withdrawn
        stakingOrderInfo[orderId].withdrawnEarnings += pending;

        // require(agiToken.transfer(msg.sender, pending), "agi transfer failed");
        TransferHelper.safeTransfer(agiToken, msg.sender, pending);
        emit Claimed(msg.sender, orderId, pending);
    }

    function _pendingForOrder(uint256 orderId) internal view returns (uint256) {
        StakingOrder storage order = stakingOrderInfo[orderId];
        if (order.aniAmount == 0) return 0;
        uint256 start = order.stakingTime;
        uint256 duration = periodSeconds[order.period];
        uint256 end = start + duration;
        uint256 from = start;
        uint256 to = block.timestamp;
        if (to > end) to = end;
        if (to <= from) return 0;
        uint256 elapsed = to - from;

        uint256 fp = perTokenPerSecondFP[order.period]; // scaled by 1e18
        // raw = aniAmount * fp * elapsed / 1e18
        uint256 raw = (order.aniAmount * fp) / 1e18;
        uint256 earned = raw * elapsed;

        // earned is already in token units (AGI with 18 decimals)
        // subtract already withdrawn
        if (earned <= order.withdrawnEarnings) return 0;
        return earned - order.withdrawnEarnings;
    }

    /// @notice Get pending AGI rewards (not yet withdrawn) for a single order
    function getOrderPending(uint256 orderId) external view returns (uint256) {
        return _pendingForOrder(orderId);
    }

    /// @notice Get total pending AGI rewards for a user across all orders
    function getUserPending(address user) external view returns (uint256) {
        uint256[] storage ids = stakingOrdersIds[user];
        uint256 total;
        for (uint256 i = 0; i < ids.length; i++) {
            total += _pendingForOrder(ids[i]);
        }
        return total;
    }


    /// @notice Return orderIds for caller that have not been redeemed (principal not withdrawn)
    function getActiveOrderIndexes(address user) external view returns (uint256[] memory) {
        uint256[] storage ids = stakingOrdersIds[user];
        uint256 count;
        for (uint256 i = 0; i < ids.length; i++) {
            if (!stakingOrderInfo[ids[i]].extracted) count++;
        }
        uint256[] memory out = new uint256[](count);
        uint256 j;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (!stakingOrderInfo[id].extracted) {
                out[j++] = id;
            }
        }
        return out;
    }

    /// @notice Withdraw principal after maturity. Rewards should be claimed separately or can be claimed automatically here.
    function withdraw(uint256 orderId) external nonReentrant onlyHolder(orderId) {
        StakingOrder storage order = stakingOrderInfo[orderId];
        require(!order.extracted, "already withdrawn");
        uint256 endTime = order.stakingTime + periodSeconds[order.period];
        require(block.timestamp >= endTime, "not matured yet");

        // optionally auto-claim pending (unwithdrawn) rewards for this order
        uint256 pending = _pendingForOrder(orderId);
        if (pending > 0) {
            order.withdrawnEarnings += pending;
            // require(agiToken.transfer(order.holder, pending), "agi transfer failed");
            TransferHelper.safeTransfer(agiToken, order.holder, pending);
            emit Claimed(order.holder, orderId, pending);
        }

        order.extracted = true;
        // require(aniToken.transfer(order.holder, order.aniAmount), "ani transfer failed");
        TransferHelper.safeTransfer(aniToken, order.holder, order.aniAmount);
        emit Withdrawn(order.holder, orderId, order.aniAmount);
    }

    
    function getOrderCountdown(uint256 orderId) external view returns (uint256) {
        StakingOrder storage order = stakingOrderInfo[orderId];
        uint256 endTime = order.stakingTime + periodSeconds[order.period];
        if (block.timestamp >= endTime) {
            return 0;
        } else {
            return endTime - block.timestamp;
        }
    }

    
    function getUserActiveStakedAmount(address user) external view returns (uint256) {
        uint256[] storage ids = stakingOrdersIds[user];
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            StakingOrder storage order = stakingOrderInfo[ids[i]];
            if (!order.extracted) {
                totalAmount += order.aniAmount;
            }
        }
        return totalAmount;
    }


    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }    

    function emergencyWithdraw() external nonReentrant onlyAdmin {
        uint256 aniAmount = IERC20(aniToken).balanceOf(address(this));
        uint256 agiAmount = IERC20(agiToken).balanceOf(address(this));
        if(aniAmount > 0) TransferHelper.safeTransfer(aniToken, msg.sender, aniAmount);
        if(agiAmount > 0) TransferHelper.safeTransfer(agiToken, msg.sender, agiAmount);
    }

    function emergencyWithdrawToken(address token, uint256 amount) external nonReentrant onlyAdmin {
        // require(token != aniToken && token != agiToken, "cannot withdraw staking tokens");
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }

}