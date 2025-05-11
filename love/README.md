### install foundry-rs/forge-std
```shell
$ forge install foundry-rs/forge-std --no-commit
```
### install openzeppelin-contracts
```shell
$ forge install openzeppelin/openzeppelin-contracts --no-commit
```

### install openzeppelin-contracts-upgradeable
```shell
$ forge install openzeppelin/openzeppelin-contracts-upgradeable --no-commit
```


### deploy
```shell
$ forge script script/DeployScript.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```


### love合约地址:0xf453560309713fE5480474432f0af56b15Dd51D0
### best合约地址:0xDf71a9F5d2DD419f43b1C05Ce33B74F39De8eB12
### 邀请首码:0xD1AE2c6C123951DA80a417FAC3451D768C12F825
### staking正式版本合约:0x89Da573B070bF3F7797D12AE4E676e3ABD9BDA47

### staking合约地址:0xf8886244a8C5eB6002C4f14fB93B10687824017a

### staking合约ABI:./out/Staking.sol/Staking.json
### 记得要更新ABI，getUserInfo中新增了一个字段_grades，表示个人两层推荐业绩

### staking合约方法
```solidity
    struct StakingOrder{
        Expired expired; //0、1、2，0代表30天，1代表60天，2代表90天
        address holder; //当前订单的拥有者地址
        uint256 amount; //当前订单质押的love数量
        uint256 stakingTime; //订单质押时间
        uint256 extracted; //用户已经提取的收益数量(best)
        bool    isRedeemed; //当前订单是否已赎回
    }
    struct AwardRecord{
        address invitee; //被邀请的质押地址
        uint256 stakingAmount; //质押数量love
        uint256 awardAmount; //奖励数量love
        uint256 awardTime; //奖励时间
    }
//新增一个方法判断邀请地址是否有效
function isValidInviter(address _inviter) external view returns (bool);
//传入订单编号返回订单详情，orderIndex订单编号
function stakingOrderInfo(uint256 orderIndex) external view returns(StakingOrder);
//查询用户信息，_user用户地址，_inviter当前用户的邀请人，_award通过邀请获得的love奖励，_grades两层业绩总额love，_validOrderIndexes用户所有没有赎回的订单编号，_allOrderIndexes用户所有的订单编号，包括赎回和质押中的，_invitees当前用户邀请了哪些用户，_awardRecords返回的是AwardRecord数组，是用户的love奖励记录
function getUserInfo(address _user) external view returns(
        address _inviter,
        uint256 _award,
        uint256 _grades,
        uint256[] memory _validOrderIndexes,
        uint256[] memory _allOrderIndexes,
        address[] memory _invitees,
        AwardRecord[] memory _awardRecords
    );
//绑定邀请人地址，_inviter输入邀请人地址
function bindInviter(address _inviter) external;
//用户进行质押love，_expired传0、1、2代表30、60、90天，_amountLove代表要质押的love数量
function staking(Expired _expired, uint256 _amountLove) external;
//通过订单编号获取当前订单截至目前的收益，_orderIndex订单编号，返回值是best数量订单收益
function getOrderRealTimeYield(uint256 _orderIndex) public view returns (uint256);
//通过订单编号获取订单的到期倒计时，_orderIndex订单编号，返回值是秒，90天的不允许赎回，所以一直返回0
function getOrderCountdown(uint256 _orderIndex) public view returns (uint256);
//赎回订单，_orderIndex是订单编号
function redeem(uint256 _orderIndex) external;
//提取订单收益best，_orderIndex是订单编号，默认提取截至目前当前订单的收益best
function claimOrder(uint256 _orderIndex) external;
//提取邀请奖励love，_amount是要提取的数量
function claimAward(uint256 _amount) external;
```
