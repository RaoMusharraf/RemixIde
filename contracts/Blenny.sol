// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Blenny Minting Contract
 */

contract Blenny is ERC721, ERC721URIStorage, Pausable, Ownable,ERC721Enumerable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public  _tokenSupply;

    string public baseURI;
    bool public check ;
    
    struct Tokens{
        address _address;
        uint256 token_id;
        string uri;
    }
     
    mapping (address => uint) public Wallet; 
    mapping (uint => Tokens) public TokenIds;
    mapping(uint256 => string) public  tokenURIs;

    constructor() ERC721("Blenny NFT", "BNFT") {

    }
    
    // ============ MINTING FUNCTIONS ============
    /* 
        @dev safeMintNFTs mint only one NFT
    */
    function safeMint(string memory uri) public{
        require(check,"Mint is Not Open");

        _tokenSupply.increment();
        _safeMint(msg.sender, _tokenSupply.current());
        _setTokenURI(_tokenSupply.current(), uri);
        TokenIds[_tokenSupply.current()]= Tokens(msg.sender,_tokenSupply.current(),uri);
        Wallet[msg.sender] += 1; 
        tokenURIs[_tokenSupply.current()] = uri;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
      function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
     /* 
        @param _to is the address that give the Token Ids that are minted by this address
        @dev Check_TokenID get all the Ids that are mint by this address 
        @returns Token Ids that are minted by the address 
    */
    function CheckTokenId(address _to) public view returns (uint[] memory)  {
        uint[] memory memoryArray = new uint[](Wallet[_to]);
        uint counter=0;
        for(uint i = 1; i <= Wallet[_to]; i++) {
            if(TokenIds[i]._address == _to){
                memoryArray[counter] = TokenIds[i].token_id;
                counter++;
            }     
        }
        return memoryArray;
    } 
    /* 
        @dev GetAllTokenIds get all the Ids that are mint by this address 
        @returns Token Ids that are minted by the address 
    */
    function AllTokenIds() public view returns (uint[] memory)  {
        uint[] memory memoryArray = new uint[](_tokenSupply.current());
        uint counter=0;
        for(uint i = 1; i <= _tokenSupply.current(); i++) {
            memoryArray[counter] = TokenIds[i].token_id;
            counter++;    
        }
        return memoryArray;
    } 
    /* 
        @dev GetAllTokenUri get all the Ids that are mint by this address 
        @returns Token Uri that are minted by the address 
    */
    function AllTokenUri() public view returns (string[] memory)  {
        string[] memory memoryArray = new string[](_tokenSupply.current());
        uint counter=0;
        for(uint i = 1; i <= _tokenSupply.current(); i++) {
            memoryArray[counter] = tokenURIs[i];
            counter++;    
        }
        return memoryArray;
    }
    /* 
        @dev GetAllTokenDetails get all the Ids that are mint by this address 
        @returns Token Details that are minted by the address 
    */
    function AllTokenDetails() public view returns (Tokens[] memory)  {
        Tokens[] memory memoryArray = new Tokens[](_tokenSupply.current());
        uint counter=0;
        for(uint i = 1; i <= _tokenSupply.current(); i++) {
            memoryArray[counter] = TokenIds[i];
            counter++;    
        }
        return memoryArray;
    }
    /* 
        @param _tokenID is the User input id that give the address
        @dev GetAddress get address that mint this _tokenID
        @returns _address Id that are minted by this address 
    */
    function GetAddress(uint _tokenId) public view returns(address _address)
    {
        return TokenIds[_tokenId]._address;    
    }

    function isSet() public onlyOwner{
        check = !check;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}