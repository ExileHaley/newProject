// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { SignatureChecker } from "./libraries/SignatureChecker.sol";
import { SignatureInfo } from "./libraries/SignatureInfo.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";
import { IRegulation } from "./interface/IRegulation.sol";
import { CFArt } from "./CFArt.sol";

contract Regulation is IRegulation, Initializable, OwnableUpgradeable, EIP712Upgradeable, UUPSUpgradeable{
    using ECDSA for bytes32;
    bytes32 public  constant SIGN_TYPEHASH = keccak256(
        "SignMessage(string orderNum,string orderMark,address token,address recipient,uint256 amount,uint256 nonce,uint256 deadline)"
    );


    uint256 public override nonce;
    address public admin;
    address public cfArt;
    address public usdt;
    address public recipient;
    mapping(string => mapping(string => bool)) public override isExcuted;
    receive() external payable{}

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function initialize(address _admin, address _cfArt, address _usdt, address _recipient) public initializer {
        __EIP712_init_unchained("Regulation", "1");
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        admin = _admin;
        cfArt = _cfArt;
        usdt = _usdt;
        recipient = _recipient;
    }

    function setConfig(address _cfArt,address _usdt,address _recipient) external{
        cfArt = _cfArt;
        usdt = _usdt;
        recipient = _recipient;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function _onlyAdmin() internal view {
        require(admin == msg.sender || owner() == msg.sender, "NOT_PERTMIT");
    }

    function setAdmin(address _admin) external onlyAdmin(){
        admin = _admin;
    }

    function deposit(
        string memory orderNum,
        string memory orderMark,
        address token,
        uint256 amount
    ) external override{
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        emit Recharge(orderNum, orderMark, token, msg.sender, amount, block.timestamp);
    }

    function withdrawWithSignature(SignatureInfo.SignMessage memory _msg) external override{
        require(_msg.nonce == nonce, "Nonce error.");
        require(_msg.deadline >= block.timestamp, "Deadline error.");
        require(checkerSignMsgSignature(_msg), "Check signature error.");
        if(_msg.token != address(0)) TransferHelper.safeTransfer(_msg.token, _msg.recipient, _msg.amount);
        else TransferHelper.safeTransferETH(_msg.recipient, _msg.amount);
        isExcuted[_msg.orderNum][_msg.orderMark] = true;
        nonce++;
        emit Withdraw(_msg.orderNum, _msg.orderMark, _msg.token, _msg.recipient, _msg.amount, _msg.nonce, block.timestamp);
    }

    function depositETH(
        string memory orderNum,
        string memory orderMark, 
        uint256 amount
    ) external payable override{
        require(msg.value >= amount,"Error amount.");
        TransferHelper.safeTransferETH(address(this), amount);
        emit Recharge(orderNum, orderMark, address(0), msg.sender, amount, block.timestamp);
    }

    function managerWithdraw(
        address token, 
        address to, 
        uint256 amount
    ) external override onlyAdmin(){
        if(token != address(0)) TransferHelper.safeTransfer(token, to, amount);
        else TransferHelper.safeTransferETH(to, amount);
    }

    function getSignMsgHash(SignatureInfo.SignMessage memory _msg) public view override returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            SIGN_TYPEHASH,
            keccak256(abi.encodePacked(_msg.orderNum)),
            keccak256(abi.encodePacked(_msg.orderMark)),
            _msg.token,
            _msg.recipient,
            _msg.amount,
            _msg.nonce,
            _msg.deadline
        )));
    }

    function checkerSignMsgSignature(SignatureInfo.SignMessage memory _msg) public view override returns (bool) {
        bytes32 signMsgHash = getSignMsgHash(_msg);
        address recoveredSigner = ECDSA.recover(signMsgHash, _msg.v, _msg.r, _msg.s);
        return recoveredSigner == admin;
    }

    function managerMint(string memory mark,address to,uint256 amount) external override onlyAdmin(){
        CFArt(cfArt).batchMint(to, amount);
        emit Mint(mark, cfArt, to, amount, 0, block.timestamp);
    }

    function mintCfArt(string memory mark,uint256 amount) external override{
        TransferHelper.safeTransferFrom(usdt, msg.sender, recipient, amount * 300e18);
        CFArt(cfArt).batchMint(msg.sender, amount);
        emit Mint(mark, cfArt, msg.sender, amount, amount * 300e18, block.timestamp);
    }

    function getPayment(uint256 amountNFT) external pure override returns(uint256){
        return amountNFT * 300e18;
    }


    function doaminSeparator() external view returns(bytes32){
        return _domainSeparatorV4();
    }

    function getSignMsgHashAndStructHash(SignatureInfo.SignMessage memory _msg) public view returns (bytes32 includeDomain,bytes32 dataHash) {
        includeDomain = _hashTypedDataV4(keccak256(abi.encode(
            SIGN_TYPEHASH,
            keccak256(abi.encodePacked(_msg.orderNum)),
            keccak256(abi.encodePacked(_msg.orderMark)),
            _msg.token,
            _msg.recipient,
            _msg.amount,
            _msg.nonce,
            _msg.deadline
        )));
        dataHash = keccak256(abi.encode(
            SIGN_TYPEHASH,
            keccak256(abi.encodePacked(_msg.orderNum)),
            keccak256(abi.encodePacked(_msg.orderMark)),
            _msg.token,
            _msg.recipient,
            _msg.amount,
            _msg.nonce,
            _msg.deadline
        ));
    }
}
//["001","mint","0x8dfe865f43932415D866D524e4c5Dbece8a7A9c8","0x48f74550535aA6Ab31f62e8f0c00863866C8606b",1000000000,0,10000,28,"0xb0e94d4e3fd77c427ed9bf82cbd5b122f033ac504ce13742025c01e6d5c87f72","0x3117e9bfe7de52a37a3e89c90501a33dbd62874c2ae229ced8ea7ae166dc1632"]
