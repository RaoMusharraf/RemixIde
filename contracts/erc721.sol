// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    constructor() ERC721("Astrality", "Astrality") {}

    function safeMint(address _to ,uint256 tokenID) public
    {
        _safeMint(_to, tokenID);
    }
  
}