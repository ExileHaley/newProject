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
import { IRegulation } from "./interfaces/IRegulation.sol";


contract Regulation is IRegulation, Initializable, OwnableUpgradeable, EIP712Upgradeable, UUPSUpgradeable{
    using ECDSA for bytes32;
    bytes32 public  constant SIGN_TYPEHASH = keccak256(
        "SignMessage(string mark,address token,address recipient,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    uint256 public override nonce;
    address public admin;
    address public token;
    address public recipient;

    mapping(string => bool) public override isExcuted;

    receive() external payable{}

    function initialize(
        address _admin, 
        address _token, 
        address _recipient) public initializer {
        __EIP712_init_unchained("Regulation", "1");
        __Ownable_init_unchained(_msgSender());
        __UUPSUpgradeable_init_unchained();
        admin = _admin; 
        token = _token;
        recipient = _recipient;

    }

    function setConfig(address _recipient) external onlyOwner(){
        recipient = _recipient;
    }

    // Authorize contract upgrades only by the owner
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner(){}

    function setAdmin(address _admin) external onlyOwner(){
        admin = _admin;
    }

    function deposit(
        string memory mark,
        uint256 amount
    ) external{
        TransferHelper.safeTransferFrom(token, msg.sender, recipient, amount);
        TransferHelper.safeTransferFrom(token, recipient, address(this), amount);
        emit Recharge(mark, token, msg.sender, amount, block.timestamp);
    }

    function withdrawWithSignature(SignatureInfo.SignMessage memory _msg) external {
        require(_msg.nonce == nonce, "Nonce error.");
        require(_msg.deadline >= block.timestamp, "Deadline error.");
        require(checkerSignMsgSignature(_msg), "Check signature error.");
        if(_msg.token == address(0)) TransferHelper.safeTransferETH(_msg.recipient, _msg.amount);
        else {
            TransferHelper.safeTransfer(_msg.token, recipient, _msg.amount);
            TransferHelper.safeTransferFrom(_msg.token, recipient, _msg.recipient, _msg.amount);
        }
        isExcuted[_msg.mark] = true;
        nonce++;
        emit Withdraw(_msg.mark, _msg.token, _msg.recipient, _msg.amount, block.timestamp);
    }


    function getSignMsgHash(SignatureInfo.SignMessage memory _msg) public view  returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            SIGN_TYPEHASH,
            keccak256(abi.encodePacked(_msg.mark)),
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

}
