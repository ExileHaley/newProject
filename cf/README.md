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
$ forge script script/DeployCfArt.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```
### upgrade UpgradeScript

```shell
$ forge script script/UpgradeNftStaking.s.s.sol -vvv --rpc-url=https://bsc.meowrpc.com --broadcast --private-key=[privateKey]
```

#### cf address: 0x40E79D34CDa3d3C038A894118895b74f88d17b5e
#### cfArt address: 0x834BBA31ed4AdBa186fB714d9480315DA56F3a6B
#### regulation address: 0x11F586dc8cD7E0a9a505EDdd07d9Ac3fA57eb9f3
#### nftStaking address: 0xA848a7fB6e86eD236Aa2F11C7D9ADD4C1F354f6f
#### pancake pool address: 0x37eA03b5D173bc5A4413fD8f23A7ff16bEB53ede


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
