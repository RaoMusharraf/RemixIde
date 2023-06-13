// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IConnected.sol";
/**
 * @title MarketPlace
 */
contract Marketplace is ReentrancyGuard , Ownable{
    // using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    ERC721 token;
    address MinterAddress;
    address paymentToken;
    address AddminAddress;
    uint256 AdminPricePer;
    mapping(uint256 => NFT) public _idToNFT;
    // mapping (uint256 => Admin) public URI;
    // mapping (uint256 => uint256) public Id;
    struct NFT {
        uint256 tokenId;
        address ERC721;
        address seller;
        address owner;
        uint256 price;
        string uri;
        uint256 auctionStart;
        uint256 auctionEnd;
    }
    // struct Admin {
    //     string URI;
    //     uint256 Price;
    //     uint256 Count;
    // }
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    constructor(address ERC721NFT, address _AdminAddress, uint256 _AdminPricePer){
        token = ERC721(ERC721NFT);
        MinterAddress = ERC721NFT;
        AddminAddress = _AdminAddress;
        AdminPricePer = _AdminPricePer;
    }
    // ============ setAdminPrice FUNCTIONS ============
    /* 
        @param price is the NFT value from AdminSide.
    */
    function setAdminPrice (uint256 _AdminPricePer) external onlyOwner{
        AdminPricePer = _AdminPricePer;
    }
    // ============ getAdminPrice FUNCTIONS ============
    /* 
        @param price is the NFT value from AdminSide.
    */
    function getAdminPrice () external view returns(uint256 price) {
        return AdminPricePer;
    }
    // ============ BuyAdmin FUNCTIONS ============
    /*
        @dev BuyAdmin buy NFTs from Admin using id.
        @param id that are created by admin when admin enter data.
    */
    function Mint(string memory _uri,string memory collectionId,uint _price,uint _auctionStart,uint _auctionEnd) external payable nonReentrant {
        tokenID.increment();
        IConnected(MinterAddress).safeMint(address(this),tokenID.current(),_uri,collectionId);
        _idToNFT[tokenID.current()] = NFT(tokenID.current(),MinterAddress,msg.sender,address(this),_price,_uri,_auctionStart,_auctionEnd);
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(uint256 _price,uint256 _tokenId,uint256 _auctionStart,uint _auctionEnd) external nonReentrant {
        require((_idToNFT[_tokenId].auctionEnd < (_idToNFT[_tokenId].auctionStart + block.timestamp)) && (_idToNFT[_tokenId].auctionStart > block.timestamp),"Already Listed !!!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        token.transferFrom(msg.sender, address(this), _tokenId);
        _idToNFT[tokenID.current()] = NFT(tokenID.current(),MinterAddress,msg.sender,address(this),_price,_idToNFT[_tokenId].uri,_auctionStart,_auctionEnd);
        _nftCount.increment();
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint256 price,uint256 _tokenId,uint256 _currentTime) external payable nonReentrant {
        require((_idToNFT[_tokenId].auctionEnd > (_idToNFT[_tokenId].auctionStart + block.timestamp)) && (_idToNFT[_tokenId].auctionStart > block.timestamp),"Time Over !!!");
        require(_idToNFT[_tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price >= _idToNFT[_tokenId].price , "Not enough ether to cover asking price !!!");
        uint256 AdminPrice = (AdminPricePer * _idToNFT[_tokenId].price)/100;
        uint256 amount = _idToNFT[_tokenId].price - AdminPricePer;
        payable(AddminAddress).transfer(AdminPrice);
        payable(_idToNFT[_tokenId].seller).transfer(amount);  
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_tokenId] = NFT(_tokenId,MinterAddress,msg.sender,msg.sender,0,_idToNFT[_tokenId].uri,_idToNFT[_tokenId].auctionStart,_currentTime);
        _nftCount.decrement();
    }
    // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(uint256 _tokenId,uint256 _currentTime) external nonReentrant {
        require((_idToNFT[_tokenId].auctionEnd > (_idToNFT[_tokenId].auctionStart + block.timestamp)) && (_idToNFT[_tokenId].auctionStart > block.timestamp),"Cancel Time Over !!!");
        require(_idToNFT[_tokenId].seller == msg.sender,"Only Owner Can Cancel !!!");
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_tokenId].owner = msg.sender;
        _idToNFT[_tokenId].auctionEnd = _currentTime;
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[_tokenId].tokenId, _idToNFT[_tokenId].seller, msg.sender, _idToNFT[_tokenId].price);
    }
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
    */
    function getListedNfts(address _to) external view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint list = _nftCount.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _to) && ((_idToNFT[i].auctionEnd > (_idToNFT[i].auctionStart + block.timestamp)) && (_idToNFT[i].auctionStart > block.timestamp))) {
                myListedNftCount++;
            }
        }
        uint remaning = list - myListedNftCount ;
        NFT[] memory nfts = new NFT[](remaning);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((_idToNFT[i].seller != _to) && ((_idToNFT[i].auctionEnd > (_idToNFT[i].auctionStart + block.timestamp)) && (_idToNFT[i].auctionStart > block.timestamp))) {
                nfts[nftsIndex] = _idToNFT[i];
                nftsIndex++;
            }
        }
        return nfts;
    }
    // ============ GetNotListedNFTs FUNCTIONS ============
    /*
        @dev getNotListedNfts fetch all the NFTs that are not listed
        @return array of NFTs that are not listed
    */
    function getNotListedNfts(address _to) external view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint list = _nftCount.current();
        uint notlist = nftCount - list;
        uint myNotListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _to) && (!((_idToNFT[i].auctionEnd > (_idToNFT[i].auctionStart + block.timestamp)) && (_idToNFT[i].auctionStart > block.timestamp)))) {
                myNotListedNftCount++;
            }
        }
        uint remaning = notlist - myNotListedNftCount ;
        NFT[] memory nfts = new NFT[](remaning);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((_idToNFT[i].seller != _to) && (!((_idToNFT[i].auctionEnd > (_idToNFT[i].auctionStart + block.timestamp)) && (_idToNFT[i].auctionStart > block.timestamp)))) {
                nfts[nftsIndex] = _idToNFT[i];
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
    function getMyNfts(address _sender) external view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint myNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if (_idToNFT[i].owner == _sender) {
                myNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myNftCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if (_idToNFT[i].owner == _sender) {
                nfts[nftsIndex] = _idToNFT[i];
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
    function getMyListedNfts(address _sender) external view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _sender) && ((_idToNFT[i].auctionEnd > (_idToNFT[i].auctionStart + block.timestamp)) && (_idToNFT[i].auctionStart > block.timestamp))) {
                myListedNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _sender) && ((_idToNFT[i].auctionEnd > (_idToNFT[i].auctionStart + block.timestamp)) && (_idToNFT[i].auctionStart > block.timestamp))) {
                nfts[nftsIndex] = _idToNFT[i];
                nftsIndex++;
            }
        }
        return nfts;
    }
    // ============ getTokenId FUNCTIONS ============
    /*
        @dev getTokenId fetch all the NFT ids that are listed by given address
        @return array of NFT ids that are listed by the given address
    */
    function getTokenId(address to) external view returns (uint[] memory){
        return IConnected(MinterAddress).getTokenId(to);
    }
}