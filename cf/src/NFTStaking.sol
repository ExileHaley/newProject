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
    address cf;
    address dead;
    uint8   public multiple;
    uint256 totalStaking;
    uint256 public perStakingReward;

    uint256[] public tokenIds;

    modifier onlyCf() {
        require(msg.sender == cf || owner() == msg.sender, "Permit error.");
        _;
    }

    function initialize(
        address _cfArt, 
        address _cf, 
        address _dead
        ) public initializer {
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        cfArt = _cfArt;
        cf = _cf;
        dead = _dead;
        multiple = 5;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}


    function initTokenIds(uint256 _tokenId) external onlyOwner(){
        tokenIds.push(_tokenId);
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
        TransferHelper.safeTransfer(cf, msg.sender, availableRewards);
    }

    function unstakeNFT() external {
        User storage user = userInfo[msg.sender];
        require(user.tokenIds.length > 0, "No NFTs to unstake");

        uint256 availableRewards = 0;
        availableRewards = getUserIncome(msg.sender);
        if (availableRewards > 0) TransferHelper.safeTransfer(cf, msg.sender, availableRewards);
        
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

    function updatePool(uint256 amount) external onlyCf(){
        // require(amount >0, "Error amount.");
        if(totalStaking == 0) totalStaking = 1;
        perStakingReward += (amount / totalStaking);
    }


    function purchaseCardinality(uint256 amount) external {
        TransferHelper.safeTransferFrom(cf, msg.sender, dead, amount);
        User storage user = userInfo[msg.sender];
        user.cardinality += amount * multiple;
    }

}