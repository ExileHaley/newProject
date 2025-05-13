// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {TokenV2} from "./TokenV2.sol";

contract Deploy {

    address public deployedAddress;

    address public usdt = address(0x55d398326f99059fF775485246999027B3197955);

    function deployTokenV2(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet
    ) external{

        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol, block.timestamp));
        address predictedAddress;
        
        // 初始化一个循环，确保地址大于 USDT 地址
        bool addressIsGreater = false;
        while (!addressIsGreater) {
            salt = keccak256(abi.encodePacked(_name, _symbol, block.timestamp)); // 使用时间戳等动态参数生成不同的 salt
            predictedAddress = predictAddress(_name, _symbol, _initialRecipient, _exceedTaxWallet, salt);
            
            if (predictedAddress > usdt) {
                addressIsGreater = true;
            } else {
                // 如果地址小于 USDT，则改变 salt 并重试
                _name = string(abi.encodePacked(_name, "hdakhakafkakafakfajhajfnajf0000asdas")); // 动态调整名称
            }
        }

        bytes memory bytecode = type(TokenV2).creationCode;
        // 使用 CREATE2 部署 TokenV2 合约
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        deployedAddress = addr;
    }

    function predictAddress(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet,
        bytes32 salt
    ) public view returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(
            type(TokenV2).creationCode,
            abi.encode(_name, _symbol, _initialRecipient, _exceedTaxWallet)
        );
        bytes32 bytecodeHash = keccak256(bytecode);

        bytes32 data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
        predicted = address(uint160(uint256(data)));
    }

    function transferOwnership(address newOwner) external {
        TokenV2(deployedAddress).transferOwnership(newOwner);
    }

}