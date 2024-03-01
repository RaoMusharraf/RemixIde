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

contract Marketplace is ReentrancyGuard , Ownable
{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    ERC721 token;
    address MinterAddress;
    address usdtToken;
    address AddminAddress;
    mapping(uint256 => NFT) public _idToNFT;
    mapping (uint256 => Admin) public URI;
    mapping (uint256 => uint256) public Id;
    // mapping (address => mapping(uint256 => rentOffer)) public rentOfferMapping;
    mapping (address => mapping(uint256 => uint)) public getTokenId;
    mapping (uint => rentOffer ) public NFTOwner;
    mapping (address => uint256) public countRentNFTs;
    mapping (address => mapping(uint256 => uint)) public getRentTokenId;
    mapping (uint => RentBid ) public ActiveRentOffer;
    mapping (address => uint256) public countBuyRentNFTs;
    mapping (uint => mapping(uint => BidderDetails)) public biddersData;
    mapping (uint => uint) public count;
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
    struct rentOffer{
        address owner;
        uint tokenId;
        uint count;
        uint month;
        uint price;
        string coordinate;
        bool isActive;
        bool second;
    }
    struct RentBid {
        uint tokenId;
        address bidder;
        string coordinate;
        uint amount;
        uint startTime;
        uint endTime;
    }
    struct BidderDetails
    {
    uint tokenId;
    address bidder;
    uint price;
    string coordinate;
    }

    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    constructor(address initialOwner, address ERC20FT,address ERC721NFT) Ownable (initialOwner) {
        token = ERC721(ERC721NFT);
        MinterAddress = ERC721NFT;
        AddminAddress = initialOwner;
        usdtToken = ERC20FT;
    
    }
    // ============ BuyAdmin FUNCTIONS ============
    /*
        @dev BuyAdmin buy NFTs from Admin using id.
        @param id that are created by admin when admin enter data.
    */
    function Buy(uint256 price,uint256 tokenId,string memory _coordinate) public nonReentrant {
        tokenID.increment();
        IConnected(MinterAddress).safeMint(msg.sender,tokenId);
        Id[tokenId] = tokenID.current();
        IERC20(usdtToken).safeTransferFrom(msg.sender, AddminAddress , price);
        _idToNFT[tokenID.current()] = NFT(tokenId,_coordinate,msg.sender,msg.sender,price,true);
        
    }
    // ============ MakeOffer FUNCTIONS ============
    /*
        @dev MakeRentOffer In this function user wants to list their NFT/Property For rent.
        @param _owner, _tokenId, _month, _price, _coordinate that are created by owner when owner enter data.
    */
    function MakeRentOffer(address _owner, uint _tokenId, uint _month, uint _price, string memory _coordinate) external nonReentrant {
        require(token.ownerOf(_tokenId)==_owner,"You are Not Owner of this NFT!");
        require(_idToNFT[Id[_tokenId]].listed,"Please Cancel the NFT from List!");
        require(!((ActiveRentOffer[_tokenId].startTime < block.timestamp ) && (block.timestamp  < ActiveRentOffer[_tokenId].endTime)),"Already for Rent");
        require(!NFTOwner[_tokenId].isActive,"You have already List this NFT for Rent!!!");
        if(!NFTOwner[_tokenId].second){
            getTokenId[_owner][countRentNFTs[_owner]+1] = _tokenId;
            NFTOwner[_tokenId] = rentOffer(_owner, _tokenId, (countRentNFTs[_owner] + 1), _month, _price, _coordinate, true, false);
            countRentNFTs[_owner]++; 
        }else{
            NFTOwner[_tokenId] = rentOffer(_owner,_tokenId,NFTOwner[_tokenId].count,_month,_price,_coordinate,true,true);
        }
    }
    // ============ MakeRentBid Function ============
    function makeRentBid(uint _tokenId, uint _amount, string memory _coordinate) external nonReentrant {
        require(_idToNFT[Id[_tokenId]].listed, "NFT is not listed for Rent!");
        require(NFTOwner[_tokenId].isActive, "NFT is not available for Rent!");
        require(_amount >= NFTOwner[_tokenId].price, "Price should be at least the listed price!");
        uint endtime = block.timestamp + 10 minutes;
        biddersData[_tokenId][count[_tokenId]+1] = BidderDetails(_tokenId,msg.sender,_amount,_coordinate);
        ActiveRentOffer[_tokenId] = RentBid(_tokenId, msg.sender,_coordinate, _amount, block.timestamp, endtime);
        count[_tokenId]++;
    }
    // ============ AcceptRentedBid FUNCTIONS ============
    function acceptRentedBid(uint _tokenId, address _bidder) external nonReentrant {
        require(token.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT!");
        require(NFTOwner[_tokenId].isActive, "This NFT is not available for Rent!");
        require(ActiveRentOffer[_tokenId].bidder == _bidder, "This bid is not for the given NFT!");
        require(block.timestamp >= ActiveRentOffer[_tokenId].startTime && block.timestamp <= ActiveRentOffer[_tokenId].endTime, "Bid has ended!");
        uint newEndTime = block.timestamp + NFTOwner[_tokenId].month * 2629743;
        IERC20(usdtToken).safeTransferFrom(_bidder, NFTOwner[_tokenId].owner, ActiveRentOffer[_tokenId].amount); 
        ActiveRentOffer[_tokenId] = RentBid(_tokenId, _bidder,ActiveRentOffer[_tokenId].coordinate,ActiveRentOffer[_tokenId].amount, block.timestamp,newEndTime);   
        NFTOwner[_tokenId].isActive = false;

    }

    //============GetBiddersDetails Function ===============
    function getBiddersDetails(uint256 _tokenId) external view returns (BidderDetails[] memory) {
        uint activeBidCount = count[_tokenId];
        BidderDetails[] memory bidderDetails = new BidderDetails[](activeBidCount);
        for (uint i = 1; i <= activeBidCount; i++) {
            bidderDetails[i - 1] = biddersData[_tokenId][i];
        }
        return bidderDetails;
    }

    // ============ CancelRentOffer FUNCTIONS ============
    function CancelRentOffer(address _owner,uint _tokenId) external nonReentrant{
        require(token.ownerOf(_tokenId)==_owner,"You are Not Owner of this NFT");
        require(NFTOwner[_tokenId].isActive,"This Is Not For Rent!");
        require(!((ActiveRentOffer[_tokenId].startTime < block.timestamp ) && (block.timestamp  < ActiveRentOffer[_tokenId].endTime)),"Already for Rent");
        NFTOwner[_tokenId].isActive = false;
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(uint256 _price,uint256 _tokenId) public nonReentrant {
        require(!NFTOwner[_tokenId].isActive,"This NFT_ID Is for Rent!");
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
    function buyNft(uint256 price,uint256 _tokenId) public nonReentrant {
        require(_idToNFT[Id[_tokenId]].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price >= _idToNFT[Id[_tokenId]].price , "Not enough ether to cover asking price !!!");
        IERC20(usdtToken).safeTransferFrom(msg.sender, _idToNFT[Id[_tokenId]].seller ,_idToNFT[Id[_tokenId]].price);
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[Id[_tokenId]] = NFT(_tokenId,_idToNFT[Id[_tokenId]].coordinate,msg.sender,msg.sender,_idToNFT[Id[_tokenId]].price,true);
        _nftCount.decrement();
        emit NFTSold(_idToNFT[Id[_tokenId]].tokenId, _idToNFT[Id[_tokenId]].seller, msg.sender,price);
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
    function getNotListedNfts(address _to) public view returns (NFT[] memory,rentOffer[] memory) {
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
        
        rentOffer[] memory rentNfts = new rentOffer[](remaning);
        uint nftsRentIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((NFTOwner[getTokenId[_idToNFT[i].seller][i]].owner != _to) && (NFTOwner[getTokenId[_idToNFT[i].seller][i]].isActive)) {
                rentNfts[nftsRentIndex] =  NFTOwner[getTokenId[_idToNFT[i].seller][i]];
                nftsRentIndex++;
            }
        }
        return (nfts,rentNfts);
    }
    // ============ GetMyNFTs FUNCTIONS ============
    /*
        @dev getMyNfts fetch all the NFTs that are Buy
        @return array of NFTs that are Buy to this current address
    */
    function getMyNfts(address _sender) public view returns (NFT[] memory,rentOffer[] memory) {
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
        uint nftsRentIndex = 0;
        rentOffer[] memory rentNfts = new rentOffer[](myNftCount);
        for (uint i = 1; i <= nftCount ; i++) {
            if (NFTOwner[getTokenId[_idToNFT[i].seller][i]].owner == _sender && NFTOwner[getTokenId[_idToNFT[i].seller][i]].isActive) {
                rentNfts[nftsRentIndex] = NFTOwner[getTokenId[_idToNFT[i].seller][i]];
                nftsRentIndex++;
            }
        }
        return (nfts,rentNfts);
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