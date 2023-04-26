// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
/**
 * @title Smash NFT Minter Contract
 */
contract SmashNFT_Minter is ERC721URIStorage, Ownable {

    string public baseURI;
    address public editor;
    struct Tokens{
        address _address;
        uint256 token_id;
    }

    uint count=0;

    mapping(uint256 => string) internal tokenUris;
    mapping (uint => Tokens) public TokenIds;
    mapping(address => uint ) public wallet;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    constructor() ERC721("Smash NFTs", "SNFT") {
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
        // Custom tokenURI exists
        if (bytes(tokenUris[tokenId]).length != 0) {
            return tokenUris[tokenId];
        }
        else {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        }
    }
    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyOwner {
        tokenUris[_tokenId] = _uri;
    }
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }


    // ============ MINTING FUNCTIONS ============
    /* 
        @dev SingleMintNFTs mint only one NFT
        @dev BulkMintNFTs mint multiple NFTs
        @param _mintAmount The number of tokens to distribute
    */
    function SingleMintNFTs(string memory _tokenURI) public payable {
        _tokenSupply.increment();
        _mint(msg.sender, _tokenSupply.current());
        _setTokenURI(_tokenSupply.current(), _tokenURI);
        tokenUris[_tokenSupply.current()]=_tokenURI;
        wallet[msg.sender]++;
        TokenIds[count].token_id=_tokenSupply.current();
        TokenIds[count]._address=msg.sender;
        count++;

    }
    function BulkMintNFTs(uint256 _mintAmount,string[] memory _tokenURI) public payable{
        require(_mintAmount == _tokenURI.length,"MintAmount and Length Of TokenUri must Same");
        require(_mintAmount > 0, "You can only mint more than 0 tokens");
        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenSupply.increment();
            _mint(msg.sender, _tokenSupply.current());
            _setTokenURI(_tokenSupply.current(), _tokenURI[i]);
            tokenUris[_tokenSupply.current()]=_tokenURI[i];
            wallet[msg.sender]++;
            TokenIds[count].token_id=_tokenSupply.current();
            TokenIds[count]._address=msg.sender;
            
            count++;
        }
    }
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    /* 
        @param _to is the address that give the Token Ids that are minted by this address
        @dev Check_TokenID get all the Ids that are mint by this address 
        @returns Token Ids that are minted by the address 
    */
    function CheckTokenId(address _to) public view returns (uint[] memory)  {
        uint[] memory memoryArray = new uint[](wallet[_to]);
        uint counter=0;
        for(uint i = 0; i < count; i++) {
            if(TokenIds[i]._address == _to){
                memoryArray[counter] = TokenIds[i].token_id;
                counter++;
            }     
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
        for(uint i = 0; i < count; i++) {
            if(TokenIds[i].token_id == _tokenId){
                return TokenIds[i]._address;
            }     
        }
    }
}