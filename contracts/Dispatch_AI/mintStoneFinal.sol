// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dispatch is ERC721, ERC721Pausable, Ownable {
    uint256 public  _nextTokenId;
    uint256 public URICount;
    mapping(address user => mapping(uint counter => Token)) public tokenDetail;
    mapping(address user => uint) public count;
    mapping(address user => mapping(uint id => bool)) isActive;
    mapping (uint id => Admin) public URI;

    //Struct
    struct Token {
        uint tokenId;
        string uri;
        uint capAmount;
        uint points;
    }
    struct Admin {
        string uri;
        uint capAmount;
        uint Count;
    }

    constructor(address initialOwner)
        ERC721("Dispatch AI", "DPAI")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function bulkEnterData (string[] memory _uri,uint[] memory capAmount,uint leng) public onlyOwner{
        for (uint i = 0 ; i < leng; i++) 
        {
            URICount++;
            URI[URICount] = Admin(_uri[i],capAmount[i],URICount);
        }
    }

    function EnterData (string memory _uri,uint capAmount) public onlyOwner{
        URICount++;
        URI[URICount] = Admin(_uri,capAmount,URICount);
    }


    function safeMint(address to,uint id) public {
        require(!isActive[to][id],"You have Already Mint this Stone!");
        _nextTokenId++;
        _safeMint(to, _nextTokenId);
        tokenDetail[to][count[to]+1] = Token(_nextTokenId,URI[id].uri,URI[id].capAmount,0);
        isActive[to][id] = true;
        count[to]++;
    }

    function getTokenDetail(address to) public view returns (Token[] memory TokensDetail) {
        Token[] memory myArray = new Token[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = tokenDetail[to][i + 1];
        }
        return myArray;
    }

    function getToken(address to,uint _tokenId) public view returns (Token[] memory token) {
        Token[] memory myArray =  new Token[](1);
        for(uint i=0 ; i < count[to] ; i++){
            if(tokenDetail[to][i + 1].tokenId == _tokenId){
                myArray[0] = tokenDetail[to][i + 1];
                break;
            }
        }
        return myArray;
    }

    function getTokenId(address to) public view returns (uint256[] memory) {
        uint256[] memory myArray = new uint256[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = tokenDetail[to][i + 1].tokenId;
        }
        return myArray;
    }

    function updateTokenId(address _to,uint _tokenId,address _seller) external {
        require(ownerOf(_tokenId) == _seller,"You are not Owner Of this NFT!"); 
        tokenDetail[_to][count[_to] + 1].tokenId = _tokenId;
        uint[] memory myArray =  getTokenId(_seller);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i] == _tokenId){
                tokenDetail[_seller][i+1] = tokenDetail[_seller][count[_seller]];
                count[_seller]--;
            }
        }
        count[_to]++;
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function allTokenURIs() public view returns (Admin[] memory) {
        Admin[] memory myArray = new Admin[](URICount);
        for (uint i = 1; i <= URICount ; i++) 
        {
            myArray[i-1] = URI[i];
        }
        return(myArray);
    }

    function getTokensDeails(address to) public view returns (Token[] memory token) {
        Token[] memory myArray =  new Token[](count[to]);
        for (uint i = 0 ; i < count[to]; i++) {
            myArray[i] = tokenDetail[to][i + 1];
        }
        return myArray;
    }
}