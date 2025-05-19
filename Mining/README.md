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
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc.blockrazor.xyz --broadcast --private-key=[privateKey]
```

### build token constructor
```shell
$ cast abi-encode "constructor(string,string,address,address,address)" "EAC" "EAC" 0xcF908559fcDAEb83b8e77A73dA84B1940f1355eC 0x9B8d301A095B4acb9D6ACF4B932D30593Df22521 0xf755948147D98CD9dA1128F3c39e260daC90c522

```

### verify token contract
```shell
$ forge verify-contract --chain-id 56 --compiler-version v0.8.28+commit.a1b79de6 0x3A5B27e7d9340960Ac1326f97e7A2Bac92436Fe2 src/Token.sol:Token  --constructor-args ... --etherscan-api-key AZKEFB6WTYWWZ4987AJ6QWFS6MHC9SUZ9R

```


### token地址:0x97729508F3B8F569194F9892D2DA0af2B968c740
### lp地址:0x31192FfCeb770bd90AeE8CF148F7f81D070c8dbE
### 挖矿合约地址:0xFd5200423B254Ee2b2DCb58208CDAC62361fAF65


### 挖矿合约ABI:./out/Mining.sol/Mining.json

### 挖矿新版本合约方法
```solidity

struct SignMessage{
        string  mark; //唯一标识
        address recipient; //接受者地址
        uint256 amount; //数量
        uint256 nonce; //nonce
        uint256 deadline; //截止时间
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s;
} 
//amountToken是token合约对应的数量，用户使用此方法进行质押，使用前token合约对挖矿合约地址进行授权
function staking(uint256 amountToken) external;
//用户提现，使用上述结构体进行传参数，该参数从后端接口获取
function claim(SignatureInfo.SignMessage memory _msg) external;

//添加流动性，用户输入代币数量amountToken，然后自动扣除其钱包中的usdt，usdt数量展示通过getQuoteAmount函数获取，返回值不用管，这里token和usdt都需要对挖矿合约进行授权，之前的订单质押需要token对挖矿合约进行授权
function addLiquidity(uint256 amountToken) external returns(uint256 _amountToken, uint256 _amountUsdt, uint256 _liquidityAmount);

//查询用户的lp余额
function serchLiquidityBalance(address _user) external view returns(uint256);

//移除流动性，_liquidity流动性lp数量，这里lp要对挖矿合约授权
function removeLiquidity(uint256 _liquidity) external;


//用户使用usdt进行前期认购,amountUsdt是usdt的数量，这里usdt需要对挖矿合约进行授权
//产品说不走合约和前端，如果不走就不要调用这个方法
function raisefunds(uint256 amountUsdt) external;
//前期认购的用户移除流动性，这里lp不需要对挖矿合约进行授权
function removeLiquidityOfRaiseFunds() external;
//查询前期认购用户获得lp数量，移除的时候也默认移除这里的全部数量
function liquidityAmount(address _user) external view returns(uint256);

```

