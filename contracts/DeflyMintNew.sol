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
 * @title Defly Minting Contract
 */

contract DeflyMint is ERC721, ERC721URIStorage, Pausable, Ownable,ERC721Enumerable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public  _tokenSupply;

    string public baseURI;

    address public BUSD;
    address public Defly;
    address public mintAuthority_address;

    bool public check ;
    
    struct Tokens{
        address _address;
        uint256 token_id;
    }
     
    mapping (address => uint) public Wallet; 
    mapping (uint => Tokens) public TokenIds;
    mapping(uint256 => string) public  tokenURIs;

    constructor(address _to,address _BUSD,address _Defly) ERC721("DeFly NFT", "DNFT") {
        mintAuthority_address = _to;
        BUSD=_BUSD;
        Defly = _Defly;

    }
    
    // ============ MINTING FUNCTIONS ============
    /* 
        @dev safeMintNFTs mint only one NFT
    */
    function safeMint(address to, string memory uri,uint256 price ,uint8 typ) public payable {
        require(check,"Mint is Not Open");
        
        if(typ==1){
            _tokenSupply.increment();
            _safeMint(to, _tokenSupply.current());
            _setTokenURI(_tokenSupply.current(), uri);
            IERC20(BUSD).safeTransferFrom(
            msg.sender,
            mintAuthority_address,
            price
        );
        }
        else if(typ==2){
            _tokenSupply.increment();
            _safeMint(to, _tokenSupply.current());
            _setTokenURI(_tokenSupply.current(), uri);
            IERC20(Defly).safeTransferFrom(
            msg.sender,
            mintAuthority_address,
            price
        );
        }
        else if(typ==3){
            _tokenSupply.increment();
            _safeMint(to, _tokenSupply.current());
            _setTokenURI(_tokenSupply.current(), uri);
            payable(mintAuthority_address).transfer(price);
        }
        else {
            revert("Send Value 1,2,3 in typ");
        }
        TokenIds[_tokenSupply.current()]= Tokens(msg.sender,_tokenSupply.current());
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
        uint256 tokenId,uint256 batchSize
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