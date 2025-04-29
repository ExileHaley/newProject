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
$ forge script script/DeployScript.s.sol -vvv --rpc-url=https://bsc-dataseed1.defibit.io --broadcast --private-key=[privateKey]
```

### build token constructor
```shell
$ cast abi-encode "constructor(string,string,address,address,address)" "EAC" "EAC" 0xcF908559fcDAEb83b8e77A73dA84B1940f1355eC 0x9B8d301A095B4acb9D6ACF4B932D30593Df22521 0xf755948147D98CD9dA1128F3c39e260daC90c522

```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.28+commit.a1b79de6 0x3A5B27e7d9340960Ac1326f97e7A2Bac92436Fe2 src/Token.sol:Token  --constructor-args ... --etherscan-api-key AZKEFB6WTYWWZ4987AJ6QWFS6MHC9SUZ9R

```


### token地址:0x552BCcB1c2b4f12726433a7d637fF1299200569A
### lp地址:0xadB351A69E87b0531AB20B47D74A911EF26ADb59
### 挖矿合约地址:0x19b88c96Ccb1f25754174B5E9A71FDA9f6258F0D
### 挖矿合约ABI:./out/Mining.sol/Mining.json
### 首码邀请人地址:0x5E0D2012955cEA355c9efc041c5ec40a6985849b

### 挖矿合约方法
```solidity
    //分别对应0、1、2、3、4、5，总共5个级别，返回的是数字，对应到级别上
    enum Level{INVALID,V1,V2,V3,V4,V5}

    //订单信息
    struct StakingOrder{
        address holder; //当前订单的拥有者，谁质押的
        uint256 amount; //当前订单质押的token数量
        uint256 stakingTime; //当前订单的质押时间
        bool    isExtracted; //当前订单是否已赎回
    }

    //奖励记录
    struct AwardRecord{
        address invitee;    //被邀请的地址，或者说质押者地址
        uint256 stakingAmount; //质押的数量
        uint256 awardAmount;    //给当前用户奖励的数量
        uint256 awardTime;      //奖励时间
        bool    isLevelAward;  //是否是级别(V1-V5)奖励，否的话就是层级奖励
    }

//获取用户信息
/**
* user:要查询的钱包地址
* _inviter:user的邀请人地址
* _award:当前用户通过邀请获得奖励数量
* _level:当前用户的级别
* _validOrderIndexes:当前用户质押的有效订单Id
* _orderIndexes:当前用户质押的所有订单，包括有效无效
* _invitees:当前用户直推的所有人地址
* _awardRecords:当前用户得到奖励(award)的记录，包括级别和层级两种奖励
*/
function getUserInfo(address _user) external view returns(
        address _inviter,
        uint256 _award,
        Level _level,
        uint256[] memory _validOrderIndexes,
        uint256[] memory _orderIndexes,
        address[] memory _invitees,
        AwardRecord[] memory _awardRecords
    );
//绑定邀请人地址，inviter是邀请人地址，这里邀请邀请人必须质押过才可以邀请别人
function bindInviter(address inviter) external;
//amountToken是token数量，返回的amountUsdt是usdt数量
function getQuoteAmount(uint256 amountToken) public view returns(uint256 amountUsdt);
//用户质押amountToken是token数量，要求100u以上质押，是否满足该条件通过上面getQuoteAmount函数判断
function staking(uint256 amountToken) external;
//获取订单详情，通过getUserInfo获取到用户的订单Id，再传入订单Id(orderId)获取订单详情结构体StakingOrder，字段在最上面已经做了标识
function stakingOrderInfo(uint256 orderId) external view returns(StakingOrder memory);
//一个订单30天，通过订单Id(orderId)获取订单的倒计时
function getOrderCountdown(uint256 orderIndex) public view returns (uint256);
//传入订单Id(orderId)，获取该订单截止目前的总收益
function getOrderRealTimeYield(uint256 orderIndex) public view returns (uint256);
//传入用户地址userAddr，可以获取用户所有的订单收益总和，不建议给用户展示
function getUserRealTimeYield(address userAddr) external view returns (uint256 total);
//赎回或提取订单，传入订单Id(orderIndex)即可提取该订单的本金与收益
function claimOrder(uint256 orderIndex) external;
//提取邀请获得的奖励，amount传入要提取的token奖励数量
function claimAward(uint256 amount) external;

//获取用户质押所有有效订单质押的代币总数量
function getUserValidStakingAmount(address userAddr) external view returns (uint256 totalAmount);

//添加流动性，用户输入代币数量amountToken，然后自动扣除其钱包中的usdt，usdt数量展示通过getQuoteAmount函数获取，返回值不用管，这里token和usdt都需要对挖矿合约进行授权，之前的订单质押需要token对挖矿合约进行授权
function addLiquidity(uint256 amountToken) external returns(uint256 _amountToken, uint256 _amountUsdt, uint256 _liquidityAmount)

```
