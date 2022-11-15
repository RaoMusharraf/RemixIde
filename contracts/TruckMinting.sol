// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Truck Mint NFT Minter Contract
 */
contract  TruckMint is ERC721, Ownable, ReentrancyGuard{

    using SafeERC20 for IERC20;
    string public baseURI;
    address private paymentToken;
    
    struct Tokens{
        address _address;
        uint256 token_id;
    }

    mapping (uint => Tokens) public TokenIds;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;
    address mintAuthority_address;
    uint256 mintAuthority_value = 3400000000000000000;
      // Mappings Declaration
    mapping(uint256 => string) internal tokenUris;

    constructor(string memory _baseURI,address _to,address _PaymentToken) ERC721("TruckMint", "TMN") {
        baseURI = _baseURI;
        mintAuthority_address = _to;
        paymentToken=_PaymentToken;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    bool check = true ;


    // ============ MINTING FUNCTIONS ============
    /* 
        @dev MintNFTs mint only one NFT
    */
    function MintNFT() public payable {
        require(_tokenSupply.current() <= 3000,"3000 Token Already Minted");
        require(check,"Mint is Not Open");
        _tokenSupply.increment();
        _mint(msg.sender, _tokenSupply.current());

        // payable(mintAuthority_address).transfer(mintAuthority_value);
        IERC20(paymentToken).safeTransferFrom(
            msg.sender,
            mintAuthority_address,
            mintAuthority_value
        );
        TokenIds[_tokenSupply.current()]= Tokens(msg.sender,_tokenSupply.current());
        if (_tokenSupply.current()+1 == 1001 || _tokenSupply.current()+1 == 2001)
        {
            check = false ;
        }
    }
    // ============ MINTING FUNCTIONS ============
    /* 
        @dev BulkMintNFTs mint only one NFT
    */
    function BulkMintNFT(uint256 mintamount) public onlyOwner{
        require(mintamount > 0 ,"Minting amount greater than 0");
        require(_tokenSupply.current() < 3000,"3000 Token Already Minted");
        for(uint16 i=0 ;i< mintamount ;i++)
        {
            _tokenSupply.increment();
            _mint(msg.sender, _tokenSupply.current());
            TokenIds[_tokenSupply.current()]= Tokens(msg.sender,_tokenSupply.current());
        }  
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

    function GetTokenId(address _to) public view returns(uint256 tokenID)
    {
        for(uint i = 0; i < _tokenSupply.current(); i++) {
            if(TokenIds[i]._address == _to){
                return TokenIds[i].token_id;
            }     
        }
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
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
    function isSet() public onlyOwner{
        check = !check;
    }
}