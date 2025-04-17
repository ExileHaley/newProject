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
$ forge script script/Deploy.s.sol -vvv --rpc-url=https://bsc-dataseed1.defibit.io --broadcast --private-key=[privateKey]
```

### abi:./out/LockLiquidity.sol/LockLiquidity.json
### token合约地址:0xa1b3EBDFAc9d96624C9898E90F8De2A613e6d271
### lp合约地址:0x062E703a4f3731740C038E1656D8391c8D26AB52
### liquidity合约地址:0xa7fDd11B63C9Ab78cc0357F6BbeF2175dd07BBa6
### liquidity合约方法:
```javascript
//获取用户lp当前已解锁的数量，user用户钱包地址，unlockedAmount已解锁数量，有18位精度
function getUnlockedAmount(address user) public view returns(uint256 unlockedAmount);
//获取用户lp解锁到期时间，expirationTime单位s，user用户钱包地址
function getExpirationTime(address user) public view returns(uint256 expirationTime);
//这个方法用户的lp要对liquidity合约进行授权
//用户解锁lp，默认全部解锁
function unlockLiquidity() external;
//获取用户信息，user用户地址，lpAmount用户质押的lp数量，有18位精度，time是用户质押的时间戳
function holderInfo(address user) external view returns(uint256 lpAmount, uint256 time);
//用户使用bnb参与私募，payable这里在前端要单独传主币数量，大于0.2小于10，有18位精度
function raiseFunds() external payable;
//获取用户已参与私募的bnb数量，amount返回的是用户参与的bnb数量，有18位精度
function getRaiseAmount(address funder) external view returns (uint256 amount);
```