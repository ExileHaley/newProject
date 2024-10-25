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
$ forge script script/RegulationScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```
### upgrade UpgradeScript

```shell
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```



#### CFRefulation:0x7863bB375B1b21657378b24Aa361BC9C631E2559
#### CFArt(NFT):0x17d6eE5c3a60f3a42B9c2799B6E27da441a8A2F6

#### ABI:./contract/out/regulation.sol/regulation.json

Regulation deployed to: 0x3Bc60E3c98b4c86080E6c030b1F3C84F9188A7d8
  CFArt deployed to: 0xED7268A90a58a9d0640D953e8d8f37C733d92C72

```solidity
// 充值代币，orderNum(订单编号)、orderMark(订单标识)、token(代币合约地址)、amount(要充值的代币数量)
function deposit(
        string memory orderNum,
        string memory orderMark,
        address token,
        uint256 amount
    ) external;

// 充值BNB，orderNum(订单编号)、orderMark(订单标识)、amount(要充值的BNB数量)
function depositETH(
        string memory orderNum,
        string memory orderMark, 
        uint256 amount
    ) external payable;

// 用户通过签名提取
// 首先通过用户前端提交的数据，以及后端返回的数据拿到合约方法所需要的数据，再进行合约调用
struct SignMessage{
    string  orderNum; //订单编号
    string  orderMark; //订单标识
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

//用户铸造NFT，因为需要用户使用usdt购买，所以usdt首先对regulation合约进行授权
//mark(铸造标识)、amount(铸造的NFT数量)
function mintCfArt(string memory mark,uint256 amount) external;

//根据用户要铸造的NFT数量返回所需的usdt数量
function getPayment(uint256 amountNFT) external view returns(uint256)
```
