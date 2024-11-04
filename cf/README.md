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
$ forge script script/Deploy.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```
### upgrade UpgradeScript

```shell
$ forge script script/UpgradeScript.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```



####  Regulation: 0x67A3BE1A4A7aF26A3FF69B380Ce8C127a493d9e0
####  CF NFT: 0x14C5DF0fB04b07d63CfC55983A8393D7581907ae
####  CF Token: 0xb5C9f24D5cFAA4531b627796e952CeCCaA46bB87
####  NFTStaking: 0x2B82e39d41E3BDcaFcB2Cc6FD5D936C2B9Ffb515

####  Pancake pair: 0x3c1EBD94454eF0af97fa7f5ef41ba742dB4AB6E2



#### ABI:./contract/out/regulation.sol/regulation.json
#### ABI:./contract/out/NFTStaking.sol/NFTStaking.json


#### CFRefulation 方法
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

#### NFTStaking 方法
```solidity
//质押NFT，_tokenIds是NFT的tokenId列表
function stakeNFT(uint256[] memory _tokenIds) external;
//获取用户收益
function getUserIncome(address _user) public view returns (uint256);
//获取用户信息，_tokenIds是NFT的tokenId列表，_extracted用户已经提取的收益
function getUserInfo(address _user) external view returns(uint256[] memory _tokenIds,uint256 _extracted);
//提取收益
function claim() external;
//用户赎回NFT
function unstakeNFT() external;
```