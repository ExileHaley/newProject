/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IStaking {
    enum Expired{EXPIRED30,EXPIRED60,EXPIRED90}
    struct StakingOrder{
        Expired expired;
        address holder;
        uint256 amount;
        uint256 stakingTime;
        uint256 extracted;
        bool    isRedeemed;
    }

    struct AwardRecord{
        address invitee;
        uint256 stakingAmount;
        uint256 awardAmount;
        uint256 awardTime;
    }

    struct User{
        address inviter;  
        uint256 award;
        uint256[] stakingOrdersIndexes;
        address[] invitees;
        AwardRecord[] awardRecords;
    }
}