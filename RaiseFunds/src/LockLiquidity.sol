// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {TransferHelper} from "./library/TransferHelper.sol";
import {IERC20} from "./interface/IERC20.sol";
import {IUniswapV2Router02} from "./interface/IUniswapV2Router02.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LockLiquidity is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard{
    //liquidity
    struct Holder{
        uint256 liquidityAmount;
        uint256 lockTime;
    }
    mapping(address => Holder) public holderInfo;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public lpToken;
    address public token;
    address public lockOwner;
    event LockLiquidityCreated(string mark, uint256 length);

    //raies funds
    event FundsRaised(address sender, uint256 amount);
    address public  bnbRecipient;
    address[] public funders;
    mapping(address => uint256) public raiseAmount;

    receive() external payable{}

    modifier onlyLockOwner() {
        require(msg.sender == lockOwner, "Not the lock owner");
        _;
    }

    function initialize(address _lpToken, address _token, address _lockOwner,address _bnbRecipient) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        bnbRecipient = _bnbRecipient;
        lpToken = _lpToken;
        token = _token;
        lockOwner = _lockOwner;
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setAddress(address _token, address _lpToken, address _bnbRecipient, address _lockOwner) external onlyOwner(){
        token = _token;
        lpToken = _lpToken;
        bnbRecipient = _bnbRecipient;
        lockOwner = _lockOwner;
    }

    function getUnlockedAmount(address user) public view returns(uint256 unlockedAmount){
        Holder memory holder = holderInfo[user];
        if(block.timestamp >= holder.lockTime + 30 days) unlockedAmount = holder.liquidityAmount;
    }

    function getExpirationTime(address user) public view returns(uint256 expirationTime){
        Holder memory holder = holderInfo[user];
        if(block.timestamp < holder.lockTime + 30 days) expirationTime = holder.lockTime + 30 days - block.timestamp;
        if(block.timestamp < holder.lockTime + 1 hours) expirationTime = holder.lockTime + 1 hours - block.timestamp;
    }

    function lockLiquidity(string memory mark, address[] memory users, uint256[] memory amounts) external onlyLockOwner(){
        for(uint i=0; i < users.length; i++){
            if(users[i] != address(0)){
                holderInfo[users[i]].liquidityAmount += amounts[i];
                holderInfo[users[i]].lockTime = block.timestamp;
            }
        }
        emit LockLiquidityCreated(mark, users.length);
    }

    function unlockLiquidity() external nonReentrant{
        Holder storage holder = holderInfo[msg.sender];
        require(holder.liquidityAmount > 0, "Not enough liquidity");
        if(getUnlockedAmount(msg.sender) > 0) removeLiquidty(msg.sender, holder.liquidityAmount, false);
        else removeLiquidty(msg.sender, holder.liquidityAmount, true);

        holder.liquidityAmount = 0;
        holder.lockTime = 0;
    }

    function removeLiquidty(address user, uint256 lpAmount, bool fee) internal{
        IERC20(lpToken).approve(uniswapV2Router, lpAmount);
        uint256 _beforeBalance = IERC20(token).balanceOf(address(this));
        uint256 _wbnbAmount = IUniswapV2Router02(uniswapV2Router).removeLiquidityETHSupportingFeeOnTransferTokens(
            token, 
            lpAmount, 
            0, 
            0, 
            address(this), 
            block.timestamp
        );
        uint256 _afterBalance = IERC20(token).balanceOf(address(this));
        if(!fee) TransferHelper.safeTransfer(token, user, _afterBalance - _beforeBalance);
        else TransferHelper.safeTransfer(token, DEAD, _afterBalance - _beforeBalance);
        TransferHelper.safeTransferETH(user, _wbnbAmount);
    }

    function raiseFunds() external payable{
        require(msg.value >= 2e17 && msg.value <= 10e18, "Amount must be greater than 0");
        TransferHelper.safeTransferETH(bnbRecipient, msg.value);
        raiseAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
        emit FundsRaised(msg.sender, msg.value);
    }

    function getFunders() external view returns (address[] memory){
        return funders;
    }

    function getRaiseAmount(address funder) external view returns (uint256){
        return raiseAmount[funder];
    }

}