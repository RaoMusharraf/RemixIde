// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTContract is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;
    struct TokenIdByCollection{
        uint256[] tokenIds;
    }
    mapping(address=>mapping(uint=>uint)) public TokenId;
    mapping(address=>uint) public count;
    mapping(string=>TokenIdByCollection) private tokenIdByCollection;

    constructor() ERC721("MyToken", "MTK") {}

    function safeMint(address to,uint256 tokenId, string memory uri,string memory collectionId) external returns (uint256) {
        _tokenIdCounter.increment();
        TokenId[to][count[to]+1] = tokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        count[to]++;
        tokenIdByCollection[collectionId].tokenIds.push(tokenId);
        return tokenId;
    }
    function getTokenId(address to) public view returns(uint[] memory){
        uint[] memory myArray = new uint[](count[to]);
        for(uint i=0;i<count[to];i++){
            myArray[i] = TokenId[to][i+1];
        }
        return myArray;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
         (ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
      function getTokenIdsByCollection(string memory collectionId) public view returns (uint[] memory) {
        return tokenIdByCollection[collectionId].tokenIds;
    }
}
