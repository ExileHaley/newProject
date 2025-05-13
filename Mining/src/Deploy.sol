// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {TokenV2} from "./TokenV2.sol";

contract Deploy {
    address public deployedAddress;
    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;

    event TokenDeployed(address indexed tokenAddress, bytes32 salt);

    function deployTokenV2(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet
    ) external returns (address) {
        bytes32 salt;
        address predicted;
        string memory nameIter = _name;

        // 尝试不同 salt，直到生成地址大于 usdt 地址
        for (uint256 i = 0; i < 1000; i++) {
            salt = keccak256(abi.encodePacked(nameIter, _symbol, _initialRecipient, _exceedTaxWallet, i));
            predicted = _predictAddress(_name, _symbol, _initialRecipient, _exceedTaxWallet, salt);
            if (predicted > usdt) {
                break;
            }
            nameIter = string(abi.encodePacked(_name, "_", _toString(i))); // 变化 name 保证 salt 不同
        }

        bytes memory bytecode = abi.encodePacked(
            type(TokenV2).creationCode,
            abi.encode(_name, _symbol, _initialRecipient, _exceedTaxWallet)
        );

        address addr;
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        deployedAddress = addr;
        emit TokenDeployed(addr, salt);
        return addr;
    }

    function predictAddress(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet,
        bytes32 salt
    ) external view returns (address) {
        return _predictAddress(_name, _symbol, _initialRecipient, _exceedTaxWallet, salt);
    }

    function _predictAddress(
        string memory _name,
        string memory _symbol,
        address _initialRecipient,
        address _exceedTaxWallet,
        bytes32 salt
    ) internal view returns (address predicted) {
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

    // 工具：uint 转 string（为了 name 拼接）
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
