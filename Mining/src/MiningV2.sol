// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {UniswapV2Library} from "./libraries/UniswapV2Library.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import { SignatureChecker } from "./libraries/SignatureChecker.sol";
import { SignatureInfo } from "./libraries/SignatureInfo.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IToken {
    function mint(address to, uint256 amount) external;
}

contract MiningV2 is Initializable, OwnableUpgradeable, EIP712Upgradeable, UUPSUpgradeable, ReentrancyGuard{

    event Staked(address staker, uint256 amount, uint256 time);
    event Claimed(string mark, address recipient, uint256 amount, uint256 time);


    using ECDSA for bytes32;

    bytes32 public  constant SIGN_TYPEHASH = keccak256(
        "SignMessage(string mark,address recipient,uint256 amount,uint256 nonce,uint256 deadline)"
    );
    mapping(string => bool) public isExcuted;
    

    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant uniswapV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public token;
    address public lp;
    address public permit;
    uint256 public nonce;

    mapping(address => bool) public blacklist;


    function initialize(address _token, address _lp, address _permit) public initializer {
        __EIP712_init_unchained("MiningV2", "1");
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        token = _token;
        lp = _lp;
        permit = _permit;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    modifier onlyPermit() {
        require(msg.sender == permit, "Not permit");
        _;
    }

     // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setConfig(address _token, address _lp, address _permit) external onlyOwner {
        require(_token != address(0), "Zero address");
        token = _token;
        lp = _lp;
        permit = _permit;
    }


    function setBlacklist(address[] calldata _addrs, bool _blacklist) external onlyPermit {
        for (uint i = 0; i < _addrs.length; i++) {
            require(_addrs[i] != address(0), "ZERO ADDRESS");
            blacklist[_addrs[i]] = _blacklist;
        }
    }

    function getAmountOut(address token0, address token1, uint256 token0Amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint[] memory amounts = IUniswapV2Router02(uniswapV2Router).getAmountsOut(token0Amount, path);
        return amounts[1];
    }
    
    function getQuoteAmount(uint256 amountToken) external view returns(uint256 amountUsdt){
        return getAmountOut(token, USDT, amountToken);
    }

    function staking(uint256 amountToken) external{
    
        uint256 amountUSDT = getAmountOut(token, USDT, amountToken);
        require(amountUSDT >= 100e18, "At least 100USDT tokens are required.");
        TransferHelper.safeTransferFrom(token, msg.sender, DEAD, amountToken);
        emit Staked(msg.sender, amountToken, block.timestamp);
    }

    function getSignMsgHash(SignatureInfo.SignMessage memory _msg) public view  returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            SIGN_TYPEHASH,
            keccak256(abi.encodePacked(_msg.mark)),
            _msg.recipient,
            _msg.amount,
            _msg.nonce,
            _msg.deadline
        )));
    }

    function checkerSignMsgSignature(SignatureInfo.SignMessage memory _msg) public view  returns (bool) {
        bytes32 signMsgHash = getSignMsgHash(_msg);
        address recoveredSigner = ECDSA.recover(signMsgHash, _msg.v, _msg.r, _msg.s);
        return recoveredSigner == permit;
    }

    function claim(SignatureInfo.SignMessage memory _msg) external{
        require(_msg.nonce == nonce, "Nonce error.");
        require(_msg.deadline >= block.timestamp, "Deadline error.");
        require(!isExcuted[_msg.mark], "Mark excuted");
        require(checkerSignMsgSignature(_msg), "Check signature error.");
        require(!blacklist[_msg.recipient], "Blacklist error.");
        IToken(token).mint(_msg.recipient, _msg.amount);
        isExcuted[_msg.mark] = true;
        nonce++;
        emit Claimed(_msg.mark, _msg.recipient, _msg.amount, block.timestamp);
    }

     /********************************************************pull***********************************************************/
    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(uniswapV2Factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(uniswapV2Factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(uniswapV2Factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(uniswapV2Factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /********************************************************pull***********************************************************/

    function addLiquidity(uint256 amountToken) external returns(uint256 _amountToken, uint256 _amountUsdt, uint256 _liquidityAmount) {
        uint256 amountUsdt = getAmountOut(token, USDT, amountToken);

        (_amountToken, _amountUsdt, _liquidityAmount) = addLiquidity(
            token, 
            USDT, 
            amountToken, 
            amountUsdt, 
            0, 
            0, 
            msg.sender, 
            block.timestamp
        );

    }

    function removeLiquidity(uint256 _liquidity) external {
        TransferHelper.safeTransferFrom(lp, msg.sender, address(this), _liquidity);
        // IERC20(lp).approve(uniswapV2Router, _liquidity);
        _safeApprove(lp, uniswapV2Router, _liquidity);
        IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            USDT, 
            token, 
            _liquidity, 
            0, 
            0, 
            msg.sender, 
            block.timestamp
        );
        
    }

    function _safeApprove(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).approve(_spender, 0); 
        IERC20(_token).approve(_spender, _amount);
    }


}