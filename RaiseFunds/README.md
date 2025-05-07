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

### upgrade
```shell
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc-mainnet.public.blastapi.io --broadcast --private-key=[privateKey]
```

### build token constructor
```shell
$ cast abi-encode "constructor(string,string,address,address,address)" "EAC" "EAC" 0xcF908559fcDAEb83b8e77A73dA84B1940f1355eC 0x9B8d301A095B4acb9D6ACF4B932D30593Df22521 0xf755948147D98CD9dA1128F3c39e260daC90c522

```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.28+commit.a1b79de6 0x3A5B27e7d9340960Ac1326f97e7A2Bac92436Fe2 src/Token.sol:Token  --constructor-args ... --etherscan-api-key AZKEFB6WTYWWZ4987AJ6QWFS6MHC9SUZ9R

```

### check verify token
```shell
$ forge verify-check 38qpxzv1eyn5mqzwvpldrtnheyfyururht4nwpkggck2i1zs8u --etherscan-api-key AZKEFB6WTYWWZ4987AJ6QWFS6MHC9SUZ9R --chain-id 56

```

### impl:0x8C28F06F128Ac245abFc7CB7fC0B904B647B8f35

cast abi-encode "initialize(address,address,address,address)" 0x7dB02d7c15d25a14a285F530Aa7387fb4E973d11 0x3A5B27e7d9340960Ac1326f97e7A2Bac92436Fe2 0x8a03078743E4B98b28F70e5A0F590B4BcEd85c1d 0xaC863E374d542880ae8D608204EA25351A62470E

--constructor-args 0x0000000000000000000000007db02d7c15d25a14a285f530aa7387fb4e973d110000000000000000000000003a5b27e7d9340960ac1326f97e7a2bac92436fe20000000000000000000000008a03078743e4b98b28f70e5a0f590b4bced85c1d000000000000000000000000ac863e374d542880ae8d608204ea25351a62470e


### verify impl contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.28+commit.a1b79de6 0x8C28F06F128Ac245abFc7CB7fC0B904B647B8f35 src/LockLiquidity.sol:LockLiquidity  --etherscan-api-key AZKEFB6WTYWWZ4987AJ6QWFS6MHC9SUZ9R

```

### build proxy constructor
```shell
$ 
```

### verify proxy contract
```shell
$ 
```

### check verify proxy
```shell
$ 
```


## 注：前端对照下面地址进行更换保持一致，后端在config.json中更换liquidity这个地址，然后重新run EAC——linux可执行文件

### abi:./out/LockLiquidity.sol/LockLiquidity.json
### token合约地址:0x6b3149fd77593105936266903508Cc84117C4EdC
### lp合约地址:0x200B84225Bf786649E327F806B80fD35d9B274c5
### liquidity合约地址:0xd143F10da8979C91920F12220C91aDAB2D734E18

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
