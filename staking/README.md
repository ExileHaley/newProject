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



### abi
### 质押合约abi:./out/staking.sol/staking.json
### swap合约abi:./out/swap.sol/swap.json
### IERC20 abi:./out/IERC20.sol/IERC20.json

### 代币合约地址:0x033E8FF9f37a786CDe1a6E7c96Dbb58e598E0962

### 质押合约地址:0xb583deBE411fCd7747a7c58a9bFc3a255CBa0EC1
### 质押合约方法如下
```javascript
//usdtBalance添加流动性的usdt双倍，lpBalance添加流动性生成的lp数量
function stakingLiquidityInfo(address user) external view returns(uint256 usdtBalance,uint256 lpBalance,uint256 stakingTime,uint256 pending,uint256 debt);
//获取用户user对应的邀请地址
function getInviter(address user) public view returns(address);

///添加流动性时，代币和usdt都需要对质押合约地址进行授权

//根据代币数量获取添加流动性所需的usdt数量
function getQuoteAmount(uint256 amountToken) public view returns(uint256 amountUsdt);
//用户添加流动性，amountToken代币的数量,根据上述方法给用户展示所需usdt数量
function provide(uint256 amountToken) external；
//用户移除流动性
function removeLiquidity() external;
//获取流动性挖矿收益，user是用户地址，返回收益数量这里是代币
function getLiquidityTruthIncome(address user) public view returns(uint256);
//用户提取流动性挖矿收益,user是用户地址，amount要提取的代币数量
function claimLiquidity(address user, uint256 amount) external;


///质押代币10天释放，这里只需要代币对质押合约地址授权即可

//用户质押代币，tokenAmount代币数量
function staking(uint256 tokenAmount) external;
//获取用户所有有效订单编号,orderIds返回一个数字类型的数组
function getValidOrder(address user) external view returns(uint256[] memory orderIds);
//根据订单编号获取订单详情,holder当前订单的拥有者，tokenAmount当前订单的代币数量，stakingTime当前订单的质押时间，extracted当前订单是否赎回，已赎回true，未赎回false
function stakingSingleOrderInfo(uint256 orderId) external view returns(address holder, uint256 tokenAmount, uint256 stakingTime, bool extracted);
//订单可赎回倒计时,根据订单编号获取当前订单赎回倒计时
function getOrderStatus(uint256 orderId) external view returns(uint256);
//获取用户推荐收益,收益是代币
function stakingSingleInviteIncome(address user) external view returns(uint256);
//用户赎回订单，订单编号orderId
function withdraw(uint256 orderId) external
```
### swap合约地址：0x1D7E92b742e35900055eb2d7f6C3bF91139d7795
### swap合约方法如下：
```javascript
///兑换时usdt对swap合约地址进行授权
//根据市场价格，计算使用usdt兑换代币的数量
function getUsdtForTokenAmount(uint256 amountUsdt) public view returns(uint256 amountToken);
//根据市场价格，给予9折优惠后，计算usdt可以兑换的代币数量
function getDiscountForSwap(uint256 amountUsdt) public view returns(uint256);
//执行兑换，输入usdt数量，上述两个方法用来展示
function swap(uint256 amountUsdt) external;
```