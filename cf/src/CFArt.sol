// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CFArt is ERC721, Ownable{
    using Strings for uint256;
    address regulation;
    uint256 public index = 1;
    string url;

    modifier onlyRegulation() {
        require(msg.sender == regulation || msg.sender == owner());
        _;
    }

    constructor()ERC721("CFArt","CF")Ownable(msg.sender){}


    function setConfig(address _regulation) external onlyOwner(){
        regulation = _regulation;
    }

    function setUrl(string memory _url) external onlyOwner(){
        url = _url;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return url;
    }

    function batchMint(address addr, uint256 amount) external onlyRegulation(){
        for(uint i=0; i<amount; i++){
            _mint(addr, index);
            index++;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        uint256 div = tokenId / 200;
        uint256 mod = tokenId % 200;

        uint256 midId;
        if(mod > 0) midId = div + 1;
        else  midId = div;

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, midId.toString(), ".json") : "";
    }

}