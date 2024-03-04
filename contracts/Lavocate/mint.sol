// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts@5.0.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@5.0.1/access/Ownable.sol";

contract LegalAiContract is ERC721, ERC721URIStorage, Ownable {
    uint public _nextTokenId;
    mapping (address => uint) public totalMintPerUser;
    mapping (address => mapping (uint => string)) public getURI;

    constructor(address initialOwner) ERC721("LegalAl", "AI") Ownable(initialOwner)
    {
    }
    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        getURI[to][totalMintPerUser[to]] = uri;
        totalMintPerUser[to]++;
    }
    function getAllURIPerUser(address to) public view returns (string[] memory){
        string[] memory myArray = new string[](totalMintPerUser[to]);
        for(uint i=0;i<totalMintPerUser[to];i++){
            myArray[i] = getURI[to][i];
        }
        return myArray;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}