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

#### 说明：用户质押的是ANI，提取的是AGI
### staking合约地址：
```solidity
enum Period {
        INVALID, //无效 0
        ONE_DAY, //1天 1
        SEVEN_DAYS,//7天 2
        ONE_MONTH, //1月 3
        THREE_MONTHS, //3月 4
        ONE_YEAR //1年 5
    }
    struct StakingOrder {
        address holder; //当前订单的持有者
        uint256 aniAmount; //当前订单质押的ani总数量
        uint256 stakingTime; //当前订单的质押事件
        uint256 withdrawnEarnings; //当前订单已提取收益
        Period  period; //当前订单的周期
        bool    extracted; //是否赎回
    }
//获取订单信息
function stakingOrderInfo(uint256 orderId) external view returns(StakingOrder memory info);
//质押ani，amount需要10000起步，period传1/2/3/4/5，分别代表不同的周期
function stake(uint256 amount, Period period) external;
//提取订单收益agi，orderId订单编号
function claimEarnings(uint256 orderId) external;
//获取当前订单的可提取收益agi，orderId订单编号
function getOrderPending(uint256 orderId) external view returns (uint256);
//获取用户所有订单的总收益agi，或者说可提取收益，user用户钱包地址
function getUserPending(address user) external view returns (uint256);
//获取用户当前未赎回订单的所有编号，user用户钱包地址
function getActiveOrderIndexes(address user) external view returns (uint256[] memory);
//赎回订单ani，orderId订单编号
function withdraw(uint256 orderId) external;
//获取当前订单的的到期倒计时，orderId订单编号
function getOrderCountdown(uint256 orderId) external view returns (uint256);
//获取当前用户所有未赎回订单总质押的ani数量，user用户钱包地址
function getUserActiveStakedAmount(address user) external view returns (uint256);
```
