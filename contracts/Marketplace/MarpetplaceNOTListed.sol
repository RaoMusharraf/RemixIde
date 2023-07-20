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
    uint256 AdminPrice;
    mapping(uint256 => NFT) public _idToNFT;
    mapping (uint256 => Admin) public URI;
    mapping (uint256 => uint256) public Id;
    struct NFT {
        uint256 tokenId;
        string coordinate;
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
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    constructor(address ERC721NFT, address _AdminAddress, uint256 _AdminPrice){
        token = ERC721(ERC721NFT);
        MinterAddress = ERC721NFT;
        AddminAddress = _AdminAddress;
        AdminPrice = _AdminPrice;
    }
    // ============ setAdminPrice FUNCTIONS ============
    /* 
        @param price is the NFT value from AdminSide.
    */
    function setAdminPrice (uint256 price) public onlyOwner{
        AdminPrice = price;
    }
    // ============ getAdminPrice FUNCTIONS ============
    /* 
        @param price is the NFT value from AdminSide.
    */
    function getAdminPrice () public view returns(uint256 price) {
        return AdminPrice;
    }
    // ============ BuyAdmin FUNCTIONS ============
    /*
        @dev BuyAdmin buy NFTs from Admin using id.
        @param id that are created by admin when admin enter data.
    */
    function Buy(uint256 price,uint256 tokenId,string memory _coordinate) public payable nonReentrant {
        require(AdminPrice == price,"Insuficient Fund !");
        tokenID.increment();
        IConnected(MinterAddress).safeMint(msg.sender,tokenId);
        payable(AddminAddress).transfer(AdminPrice);
        Id[tokenId] = tokenID.current();
        // IERC20(paymentToken).safeTransferFrom(msg.sender, AddminAddress , price);
        _idToNFT[tokenID.current()] = NFT(tokenId,_coordinate,msg.sender,msg.sender,AdminPrice,true);
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(uint256 _price,uint256 _tokenId) public nonReentrant {
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        token.transferFrom(msg.sender, address(this), _tokenId);
        _idToNFT[Id[_tokenId]] = NFT(_tokenId,_idToNFT[Id[_tokenId]].coordinate,msg.sender,address(this),_price,false);
        _nftCount.increment();
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint256 price,uint256 _tokenId) public payable nonReentrant {
        require(_idToNFT[Id[_tokenId]].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price >= _idToNFT[Id[_tokenId]].price , "Not enough ether to cover asking price !!!");
        payable(_idToNFT[Id[_tokenId]].seller).transfer(_idToNFT[Id[_tokenId]].price);
        // IERC20(paymentToken).safeTransferFrom(msg.sender, _idToNFT[_tokenId].seller ,_idToNFT[_tokenId].price);
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[Id[_tokenId]] = NFT(_tokenId,_idToNFT[Id[_tokenId]].coordinate,msg.sender,msg.sender,_idToNFT[Id[_tokenId]].price,true);
        _nftCount.decrement();
        emit NFTSold(_idToNFT[Id[_tokenId]].tokenId, _idToNFT[Id[_tokenId]].seller, msg.sender, msg.value);
    }
    // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(uint256 _tokenId) public nonReentrant {
        require(!_idToNFT[Id[_tokenId]].listed,"Please List First !!!");
        require(_idToNFT[Id[_tokenId]].seller == msg.sender,"Only Owner Can Cancel !!!");
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[Id[_tokenId]].owner = msg.sender;
        _idToNFT[Id[_tokenId]].listed=true;
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[Id[_tokenId]].tokenId, _idToNFT[Id[_tokenId]].seller, msg.sender, _idToNFT[Id[_tokenId]].price);
    }
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
    */
    function getListedNfts(address _to) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint list = _nftCount.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _to) && (!_idToNFT[i].listed)) {
                myListedNftCount++;
            }
        }
        uint remaning = list - myListedNftCount ;
        NFT[] memory nfts = new NFT[](remaning);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((_idToNFT[i].seller != _to) && (!_idToNFT[i].listed)) {
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
    function getNotListedNfts(address _to) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint list = _nftCount.current();
        uint notlist = nftCount - list;
        uint myNotListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _to) && (_idToNFT[i].listed)) {
                myNotListedNftCount++;
            }
        }
        uint remaning = notlist - myNotListedNftCount ;
        NFT[] memory nfts = new NFT[](remaning);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((_idToNFT[i].seller != _to) && (_idToNFT[i].listed)) {
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
    function getMyNfts(address _sender) public view returns (NFT[] memory) {
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
    function getMyListedNfts(address _sender) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _sender) && (!_idToNFT[i].listed)) {
                myListedNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[i].seller == _sender) && (!_idToNFT[i].listed)) {
                nfts[nftsIndex] = _idToNFT[i];
                nftsIndex++;
            }
        }
        return nfts;
    }
}