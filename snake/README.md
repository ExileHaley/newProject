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
$ forge script script/Regulation.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```

### upgrade UpgradeScript
```shell
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```


#### regulation address:0xBCFC3CEe6b79FB9D9532ED83D6656F39856aCBbb
#### testERC20:0x256CB03D0361Da7a3BdABAa3146E54BC0234BFB3

#### Refulation 方法
```solidity
// 充值代币，orderNum(订单编号)、orderMark(订单标识)、token(代币合约地址)、amount(要充值的代币数量)
function deposit(
        string memory mark,
        uint256 amount
    ) external;

// 用户通过签名提取
// 首先通过用户前端提交的数据，以及后端返回的数据拿到合约方法所需要的数据，再进行合约调用
struct SignMessage{
    string  mark; //订单标识
    address token; //代币合约地址，如果合约地址为0地址，则代表提取bnb
    address recipient; //代币的接收者地址
    uint256 amount; //要提取的代币数量
    uint256 nonce; //nonce值，这个从后端拿
    uint256 deadline; //这个数据也从后端拿
    uint8 v; // v: parameter (27 or 28)
    bytes32 r; // r: parameter
    bytes32 s;
} 
function withdrawWithSignature(SignatureInfo.SignMessage memory _msg) external;

```
