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
####  CF Token: 0xC3214Da07B8985878f2F3590a01a7D4202Caf01d
####  NFTStaking: 0x2B82e39d41E3BDcaFcB2Cc6FD5D936C2B9Ffb515

####  Pancake pair: 0x3c1EBD94454eF0af97fa7f5ef41ba742dB4AB6E2



#### ABI:./contract/out/regulation.sol/regulation.json
#### ABI:./contract/out/NFTStaking.sol/NFTStaking.json




#### CFRefulation 方法更新
```solidity
//用户铸造NFT，修改后需要用户使用cf购买，所以cf首先对regulation合约进行授权
//mark(铸造标识)、amount(铸造的NFT数量)
function mintCfArt(string memory mark,uint256 amount) external;

//之前这里返回的是usdt的数量，现在这里会返回需要
function getPayment(uint256 amountNFT) external view returns(uint256)
```

#### NFTStaking 方法更新
```solidity
//新增方法，用于用户购买倍数额度，现在要求用户没有5倍出局上线，这里可以使用cf购买倍数，amount是cf数量，所以cf对NFTStaking合约进行授权
function purchaseCardinality(uint256 amount) external
```