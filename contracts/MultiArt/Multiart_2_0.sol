// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Multiart is ERC721, ERC721URIStorage, Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    
    struct TokenIdByCollection {
        uint256[] tokenIds;
    }
    mapping(address => mapping(uint256 => uint256)) public TokenId;
    mapping(address => uint256) public count;
    mapping(string => TokenIdByCollection) private tokenIdByCollection;
    mapping(string => uint256) public alreadyMintedQuantity;
    address public mintPriceReceiver;
    address public adminAddress;
    address public transferFeeReceiver;
    address tokenAddress;
    uint256 public royalty;

    struct NFT {
        uint256 mintTime;
        address mintArtist;
    }
    mapping (uint => NFT) public NFTMetadata;
    mapping (address => uint) public ArtistAmount;

    constructor(address _adminAddress,address _mintPriceReceiver, address _transferFeeReceiver,address _tokenAddress,uint256 _royalty)
        ERC721("Multiart", "MAT")
    {
        adminAddress = _adminAddress;
        mintPriceReceiver = _mintPriceReceiver;
        transferFeeReceiver = _transferFeeReceiver;
        tokenAddress = _tokenAddress;
        royalty=_royalty;
    }
    function setAdminAddress(address _adminAddress) external {
        adminAddress = _adminAddress;
    }
    function safeMint(uint256 feePercentage,string memory uri,uint StartTime,uint EndTime,string memory NFT_doc,uint mintQuantity,uint TotalQuantity,address artist,uint perNFTPrice,uint typ,string memory collectionId) public payable {
        require((StartTime < block.timestamp) && (block.timestamp < EndTime),"Time Overflow");
        require(msg.value == (perNFTPrice*mintQuantity), "Invalid Price");
        uint256 usedQuantity = alreadyMintedQuantity[NFT_doc];
        require((usedQuantity + mintQuantity) <= TotalQuantity,"Remaining NFTQuantity is Less than Your NFTQuantity");
        uint256 calculatedFeePrice = calculateReceiverPrice(feePercentage,msg.value);
        uint256 mintedPrice = msg.value - calculatedFeePrice;
        for(uint i =1 ; i <= mintQuantity ; i++){
            _tokenIdCounter.increment();
            TokenId[msg.sender][count[msg.sender] + 1] = _tokenIdCounter.current();
            _safeMint(msg.sender, _tokenIdCounter.current());
            _setTokenURI(_tokenIdCounter.current(), uri);
            count[msg.sender]++;
            NFTMetadata[_tokenIdCounter.current()] = NFT(block.timestamp,artist);
            tokenIdByCollection[collectionId].tokenIds.push(_tokenIdCounter.current());
        }
        alreadyMintedQuantity[NFT_doc] += mintQuantity; 
        ArtistAmount[artist] += mintedPrice;
        if(typ == 1){
            payable(mintPriceReceiver).transfer(mintedPrice);
            payable(transferFeeReceiver).transfer(calculatedFeePrice);
        }
        else if(typ == 2){
            IERC20(tokenAddress).safeTransferFrom(msg.sender,mintPriceReceiver,mintedPrice);
            IERC20(tokenAddress).safeTransferFrom(msg.sender,transferFeeReceiver,calculatedFeePrice);
        }
        else{
            revert("Please Enter the correct payment Type");
        } 
    }

    function calculateReceiverPrice(uint256 _feePercentage, uint256 _TotalPrice)
        public
        pure
        returns (uint256)
    {
        return ((_TotalPrice * _feePercentage) / 1000);
    }
    function viewArtistAmount(address to) public view returns(uint256 artist) {
        return ArtistAmount[to];
        // payable(to).transfer(ArtistAmount[to]);
        // delete ArtistAmount[to];
    }

    function getTokenId(address to) public view returns (uint256[] memory) {
        uint256[] memory myArray = new uint256[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = TokenId[to][i + 1];
        }
        return myArray;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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

    function getTokenIdsByCollection(string memory collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return tokenIdByCollection[collectionId].tokenIds;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setMintPriceReceiver(address _mintPriceReceiver) public   {
        mintPriceReceiver=_mintPriceReceiver;
    }
    function setTransferFeeReceiver(address _transferFeeReceiver) public {
        transferFeeReceiver=_transferFeeReceiver;
    }
    function setRoyalty(uint256 _royalty) public {
        royalty=_royalty ;
    }
}