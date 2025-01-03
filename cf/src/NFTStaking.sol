// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";
import { PancakeLibrary } from "./libraries/PancakeLibrary.sol";

contract NFTStaking is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC721Holder{

    enum Mark{
        STAKE,
        UNSTAKE
    }

    struct Record{
        Mark        mark;
        address     user;
        uint256[]   tokenIds;
        uint256     amountUsdt;
        uint256     time;
    }
    mapping(address => Record[]) recordInfos;

    struct User{
        uint256[] tokenIds;
        uint256   extracted;
        uint256   debt;
        uint256   pending;
        uint256   cardinality;
    }

    mapping(address => User) userInfo;
    address cfArt;
    address usdt;
    address admin;
    address cf;
    address dead;
    address uniswapV2Factory;
    uint8   public multiple;
    uint256 totalStaking;
    uint256 public perStakingReward;

    uint256[] public tokenIds = [348,349,350,350,351,352,353,354,355,356,357,358,359,361,362,363,364,366,367,368,369,370,371,372,373,374,375,376,377
,378,379,380,381,382,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411];

    modifier onlyAdmin() {
        require(msg.sender == admin || owner() == msg.sender, "Permit error.");
        _;
    }

    function initialize(address _cfArt, address _usdt, address _admin) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        cfArt = _cfArt;
        usdt = _usdt;
        admin = _admin;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setAddress(address _cf, address _dead, address _uniswapV2Factory) external onlyOwner(){
        cf = _cf;
        dead = _dead;
        uniswapV2Factory = _uniswapV2Factory;
    }

    function initTokenIds(uint256[] calldata _tokenIds) external onlyOwner(){
        for(uint i=0; i<_tokenIds.length; i++){
            tokenIds.push(_tokenIds[i]);
        }
    }

    function isTokenIdInArray(uint256 _tokenId) public view returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                return true; // 找到元素，返回 true
            }
        }
        return false; // 遍历完未找到，返回 false
    }


    function setMultiple(uint8 _multiple) external onlyOwner(){
        multiple = _multiple;
    }

    function stakeNFT(uint256[] memory _tokenIds) external {

        for(uint i=0; i<_tokenIds.length; i++){
            require(!isTokenIdInArray(_tokenIds[i]),"Not permit.");
        }

        User storage user = userInfo[msg.sender];
        user.pending = user.tokenIds.length * perStakingReward + user.pending - user.debt;
        for(uint i=0; i<_tokenIds.length; i++){
            IERC721(cfArt).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            user.tokenIds.push(_tokenIds[i]);
        }
        user.debt = user.tokenIds.length * perStakingReward;
        totalStaking += _tokenIds.length;


        recordInfos[msg.sender].push(Record({
            mark: Mark.STAKE,
            user: msg.sender,
            tokenIds: _tokenIds,
            amountUsdt: 0,
            time: block.timestamp
        }));
    }

    function getUserIncome(address _user) public view returns (uint256) {
        User memory user = userInfo[_user];
        uint256 _currentIncome = user.tokenIds.length * perStakingReward + user.pending - user.debt;
        uint256 _maxDeserve = user.tokenIds.length * ((uint256(300e18) + user.cardinality) * multiple) ;
        // compute remaining and compute truth reward.
        uint256 _remainingDeserve = user.extracted >= _maxDeserve ? 0 : _maxDeserve - user.extracted;
        return _currentIncome < _remainingDeserve ? _currentIncome : _remainingDeserve;
    }

    function getUserInfo(address _user) external view returns(uint256[] memory _tokenIds,uint256 _extracted){
        User memory user = userInfo[_user];
        _tokenIds = user.tokenIds;
        _extracted = user.extracted;
    }

    function claim() external {
        User storage user = userInfo[msg.sender];
        uint256 availableRewards = 0;
        availableRewards = getUserIncome(msg.sender);
        require(availableRewards > 0, "Insufficient rewards");
        // user.pending = user.tokenIds.length * perStakingReward + user.pending - user.debt;
        // user.pending -= amount;
        user.debt = user.tokenIds.length * perStakingReward;
        user.pending = 0;
        user.extracted += availableRewards;
        TransferHelper.safeTransfer(usdt, msg.sender, availableRewards);
    }

    function unstakeNFT() external {
        User storage user = userInfo[msg.sender];
        require(user.tokenIds.length > 0, "No NFTs to unstake");

        uint256 availableRewards = 0;
        availableRewards = getUserIncome(msg.sender);
        if (availableRewards > 0) TransferHelper.safeTransfer(usdt, msg.sender, availableRewards);
        
        // send NFT
        for (uint256 i = 0; i < user.tokenIds.length; i++) {
            IERC721(cfArt).safeTransferFrom(address(this), msg.sender, user.tokenIds[i]);
        }

        recordInfos[msg.sender].push(Record({
            mark: Mark.UNSTAKE,
            user: msg.sender,
            tokenIds: user.tokenIds, 
            amountUsdt: availableRewards,
            time: block.timestamp
        }));

        totalStaking -= user.tokenIds.length;
        // delete
        delete user.tokenIds;
        // reset
        user.debt = 0;
        user.pending = 0;
        
    }

    function updatePool(uint256 amount) external onlyAdmin(){
        require(amount >0, "Error amount.");
        if(totalStaking == 0) totalStaking = 1;
        perStakingReward += (amount / totalStaking);
    }

    function getAmountOut(address _token, uint256 _amount) public view returns(uint256){
        (uint reserveIn, uint reserveOut) = PancakeLibrary.getReserves(uniswapV2Factory, _token, usdt);
        return PancakeLibrary.getAmountOut(_amount, reserveIn, reserveOut);
    }

    function purchaseCardinality(uint256 amount) external {
        TransferHelper.safeTransferFrom(cf, msg.sender, dead, amount);
        uint256 amountUSDT = getAmountOut(cf, amount);
        User storage user = userInfo[msg.sender];
        user.cardinality += amountUSDT;
    }

}