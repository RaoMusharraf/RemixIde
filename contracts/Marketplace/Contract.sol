// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IIERC721.sol";
/**
 * @title MarketPlace
 */
contract Marketplace is ReentrancyGuard , Ownable{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _nftsSold;
    Counters.Counter public _nftCount;
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    Counters.Counter public CountTokenId;
    ERC721 token;
    address MinterAddress;
    address paymentToken;
    address AddminAddress;
    mapping (uint256 => Check) public check;
    mapping(uint256 => NFT) public _idToNFT;
    mapping (uint256 => Admin) public URI;
    mapping (uint256 => uint256) public TOKEN_ID;
    struct NFT {
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        bool listed;
    }
    struct Admin {
        string URI;
        uint256 Price;
        uint256 Count;
    }
    struct Check{
        address _address;
    }
    event NFTListed(address nftContract,uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(address nftContract,uint256 tokenId,address seller,address owner,uint256 price);

    constructor(address MintERC721,address ERC20 , address admin){
        token = ERC721(MintERC721);
        MinterAddress = MintERC721;
        paymentToken = ERC20;
        AddminAddress = admin;
    }
    // ============ AdminEnterData FUNCTIONS ============
    /* 
        @dev AdminEnterData in this function admin enter data related Cars.
        @param _uri URI contains data like price & image etc.
        @param _price is the required amount to buy any NFT.
    */
    function AdminEnterData (string memory _uri,uint _price) public onlyOwner{
        _URICount.increment();
        URI[_URICount.current()] = Admin(_uri,_price,_URICount.current());
    }
    
    // ============ BuyAdmin FUNCTIONS ============
    /* 
        @dev BuyAdmin buy NFTs from Admin using id.
        @param id that are created by admin when admin enter data.
    */
    function BuyAdmin (uint256 id) public payable{
        tokenID.increment();
        IIERC721(MinterAddress).safeMint(msg.sender,tokenID.current(), URI[id].URI);
        IERC20(paymentToken).safeTransferFrom(msg.sender, AddminAddress , URI[id].Price);
        CountTokenId.increment();
        _idToNFT[tokenID.current()] = NFT(MinterAddress,tokenID.current(),msg.sender,msg.sender,URI[id].Price,true);
    }
    // ============ ListNft FUNCTIONS ============
    /* 
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(uint256 _tokenId, uint256 _price) public payable nonReentrant {
        require(_price > 0, "Price must be at least 1 wei");
        token.transferFrom(msg.sender, address(this), _tokenId);
        CountTokenId.increment();
        _nftCount.increment();
        TOKEN_ID[_nftCount.current()] = _tokenId;
        _idToNFT[_tokenId] = NFT(MinterAddress,_tokenId,msg.sender,address(this),_price,false);
        check[_tokenId]._address=msg.sender;
        emit NFTListed(MinterAddress, _tokenId, msg.sender, address(this), _price);
    }

    // ============ BuyNFTs FUNCTIONS ============
    /* 
        @dev BuyNft convert the ownership seller to the buyer 
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint256 _tokenId) public payable nonReentrant {
        require(_idToNFT[_tokenId].seller != msg.sender, "An offer cannot buy this Seller");
        require(msg.value >= _idToNFT[_tokenId].price , "Not enough ether to cover asking price");
        IERC20(paymentToken).safeTransferFrom(msg.sender, _idToNFT[_tokenId].seller ,_idToNFT[_tokenId].price);
        token.transferFrom(address(this), msg.sender, _tokenId); 
        _idToNFT[_tokenId].owner = msg.sender;
        _idToNFT[_tokenId].listed=true;
        _nftsSold.increment();
        emit NFTSold(MinterAddress, _idToNFT[_tokenId].tokenId, _idToNFT[_tokenId].seller, msg.sender, msg.value);
    }

    // ============ CancelOffer FUNCTIONS ============
    /* 
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(uint256 _tokenId) public{
        require(check[_tokenId]._address == msg.sender,"Only Owner can Cancel");
        _idToNFT[_tokenId].listed=true;
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_tokenId].owner = msg.sender;
        _idToNFT[_tokenId];
        _nftsSold.increment();
    }

    // ============ GetListedNFTs FUNCTIONS ============
    /* 
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
    */
    function getListedNfts() public view returns (NFT[] memory) {
        uint256 nftCount = _nftCount.current();
        uint256 unsoldNftsCount = nftCount - _nftsSold.current();
        NFT[] memory nfts = new NFT[](unsoldNftsCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if (!_idToNFT[TOKEN_ID[i]].listed) {
                nfts[nftsIndex] = _idToNFT[TOKEN_ID[i]];
                nftsIndex++;
            }
        }
        return nfts;
    }

    // ============ GetMyNFTs FUNCTIONS ============
    /* 
        @dev getMyNfts fetch all the NFTs that are Buy
        @return array of NFTs that are Buy to this current address
    */
    function getMyNfts(address _sender) public view returns (NFT[] memory) {
        uint nftCount = CountTokenId.current();
        uint myNftCount = 0;
        for (uint i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].owner == _sender) {
                myNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myNftCount);
            uint nftsIndex = 0;
            for (uint i = 0; i < nftCount; i++) {
                if (_idToNFT[i + 1].owner == _sender) {
                nfts[nftsIndex] = _idToNFT[i + 1];
                nftsIndex++;
            }
        }
        return nfts;
    }

    // ============ GetMyListedNFTs FUNCTIONS ============
    /* 
        @dev getMyNfts fetch all the NFTs that are listed by current address
        @return array of NFTs that are listed by the current address
    */
    function getMyListedNfts(address _sender) public view returns (NFT[] memory) {
        uint nftCount = _nftCount.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[TOKEN_ID[i]].seller == _sender) && (!_idToNFT[TOKEN_ID[i]].listed)) {
                myListedNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if (_idToNFT[TOKEN_ID[i]].seller == _sender && (!_idToNFT[TOKEN_ID[i]].listed)) {
                nfts[nftsIndex] = _idToNFT[TOKEN_ID[i]];
                nftsIndex++;
            }
        }
        return nfts;
    }
}