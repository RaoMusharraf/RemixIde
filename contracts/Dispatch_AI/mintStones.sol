// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Dispatch is ERC721, ERC721Pausable, Ownable, ERC721Burnable {

    using Counters for Counters.Counter;
    Counters.Counter public tokenIdCounter;
    Counters.Counter public URICount;
    mapping(address => mapping(uint256 => uint256)) public TokenId;
    mapping(address => uint256) public count;

    mapping (uint256 => Admin) public URI;

    struct Admin {
        string URI;
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

    // ============ AdminEnterData FUNCTIONS ============
    /* 
        @dev AdminEnterData in this function admin enter data related Cars.
        @param _uri URI contains data like price & image etc.
        @param _price is the required amount to buy any NFT.
    */
    function EnterData (string memory _uri,uint capAmount) public onlyOwner{
        URICount.increment();
        URI[URICount.current()] = Admin(_uri,capAmount,URICount.current());
    }

    function safeMint(address to) public {
        uint tokenId = tokenIdCounter.current();
        _safeMint(to, tokenId);
        TokenId[to][count[to]] = tokenId;
        tokenIdCounter.increment();
        count[to]++;
    }
    function getTokenId(address to) public view returns (uint256[] memory) {
        uint256[] memory myArray = new uint256[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = TokenId[to][i + 1];
        }
        return myArray;
    }
    function updateTokenId(address _to,uint _tokenId,address _seller) external {
        TokenId[_to][count[_to] + 1] = _tokenId;
        uint256[] memory myArray =  getTokenId(_seller);
        for(uint i=0 ; i < myArray.length ; i++){
            if(myArray[i] == _tokenId){
                TokenId[_seller][i+1] = TokenId[_seller][count[_seller]];
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
}