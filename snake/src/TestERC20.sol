// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20{
    constructor() ERC20("Test","TES"){
        _mint(msg.sender,1000000000e18);
    }
}