// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @title MarketPlace
 */
contract Marketplace is ReentrancyGuard , Ownable{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public nftAuctionCount;
    address paymentToken;
    address tokenAddress;
    mapping(address => mapping(uint256 => NFT)) public _idToNFT;
    mapping (uint => addressToken) public listCount;
    // Auction
    mapping (address => mapping (uint => nftAuction)) public NftAuction;
    mapping (uint => uint ) public userListCount;
    mapping (uint => addressToken) public auctionListCount;
    mapping (uint => mapping(uint=>userDetail)) public Bidding;
    struct NFT {
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        uint256 count;
        bool listed;
    }
    struct addressToken{
        address contractAddress;
        uint tokenId;
    }
    struct userDetail{
        address user;
        uint price;
    }
    struct nftAuction{
        address owner;
        uint tokenId;
        uint totalBidTimeInHour;
        uint startTime;
        uint endTime;
        bool isActive;
    }
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(address _mintContract,uint256 _price,uint256 _tokenId) public nonReentrant {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        _nftCount.increment();
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_price,_nftCount.current(),true);
        listCount[_nftCount.current()] = addressToken(_mintContract,_tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint listIndex,uint256 price,uint typ) public payable nonReentrant {
        
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price >= _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        uint256 amount = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price;
        if(typ == 1){ 
            payable(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller).transfer(amount);
        }  
        else if(typ == 2){  
            IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller,amount);
        }
        else{
            revert("Please Enter the correct payment Type");
        }
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTSold(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, msg.value);
    }
    // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(uint listIndex) public nonReentrant {
        require(!_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed,"Please List First !!!");
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller == msg.sender,"Only Owner Can Cancel !!!");
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner = msg.sender;
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price);
    }
    function AuctionList(address _mintContract,uint _tokenId,uint _totalBidTime,uint _startTime) external {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        require(_totalBidTime >= 1,"Bid Time Must Be One Hour!");
        nftAuctionCount.increment();
        NftAuction[_mintContract][_tokenId] = nftAuction(msg.sender,_tokenId,_totalBidTime,_startTime,(_startTime+(3600*_totalBidTime)),true);
        auctionListCount[nftAuctionCount.current()] = addressToken(_mintContract,_tokenId);
        userListCount[nftAuctionCount.current()] = 0; 
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId);
    }
    function NftBidding(uint _auctionListCount,uint _price) external {
        require(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner != msg.sender,"You are Not Eligible for Bidding");
        require(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive,"Not Listed In Auction!");
        require(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].startTime < block.timestamp ,"Bidding Not Start!");
        require(block.timestamp < NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].endTime,"Bidding END!");
        Bidding[_auctionListCount][userListCount[_auctionListCount]+1] = userDetail(msg.sender,_price);
        userListCount[_auctionListCount]++;
    }
    function cancelAuctionList(uint _auctionListCount) external {
        require(block.timestamp < NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].endTime,"Please wait bidding time is not complete!");
        ERC721(auctionListCount[_auctionListCount].contractAddress).transferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId);
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete auctionListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
        
    }
    function ClaimNFT(uint _auctionListCount,uint typ) external payable {
        require(block.timestamp > NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].endTime,"Bidding END!");
        address owner;
        uint price;
        (owner,price) = selectUser(_auctionListCount);
        require(owner == msg.sender ,"you are not sellected bidder");
        if(typ == 1){ 
            payable(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner).transfer(price);
        }  
        else if(typ == 2){  
            IERC20(tokenAddress).safeTransferFrom(owner,NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner,price);
        }
        else{
            revert("Please Enter the correct payment Type");
        }
        ERC721(auctionListCount[_auctionListCount].contractAddress).transferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId);
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete auctionListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
    }
    function selectUser(uint _auctionListCount) public view returns(address selectedUser,uint price){
        uint heighest = 0;
        address owner;
        for(uint i = 1 ; i <= userListCount[_auctionListCount] ; i++){
            if(heighest < Bidding[_auctionListCount][i].price){
                heighest = Bidding[_auctionListCount][i].price;
                owner = Bidding[_auctionListCount][i].user;
            }
        }
        return (owner,heighest);
    }
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
    */
    function getListedNfts(address _to) public view returns (NFT[] memory,NFT[] memory) {
        uint myListedCount = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller == _to) && (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                myListedCount++;
            }
        }
        NFT[] memory myListedNFT = new NFT[](myListedCount);
        if(myListedCount != 0){
            uint myListedIndex = 0;
            for (uint i = 1; i <= _nftCount.current() ; i++) {
                if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller == _to) && (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                    myListedNFT[myListedIndex] = _idToNFT[listCount[i].contractAddress][listCount[i].tokenId];
                    myListedIndex++;
                }
            }
        }
        uint listNft = (_nftCount.current()-myListedCount);
        NFT[] memory listedNFT = new NFT[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if ((NftAuction[listCount[i].contractAddress][listCount[i].tokenId].owner != _to) && (NftAuction[listCount[i].contractAddress][listCount[i].tokenId].isActive)) {
                listedNFT[listedIndex] = _idToNFT[listCount[i].contractAddress][listCount[i].tokenId];
                listedIndex++;
            }
        }
        return (myListedNFT,listedNFT);
    }
    function getAuctionListedNfts(address _to) public view returns (nftAuction[] memory,nftAuction[] memory) {
        uint myListedCount = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if ((NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].owner == _to) && (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive)) {
                myListedCount++;
            }
        }
        nftAuction[] memory myListedNFT = new nftAuction[](myListedCount);
        if(myListedCount != 0){
            uint myListedIndex = 0;
            for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
                if ((NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].owner == _to) && (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive)) {
                    myListedNFT[myListedIndex] = NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId];
                    myListedIndex++;
                }
            }
        }
        uint listNft = (nftAuctionCount.current()-myListedCount);
        nftAuction[] memory listedNFT = new nftAuction[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if ((NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].owner != _to) && (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive)) {
                listedNFT[listedIndex] = NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId];
                listedIndex++;
            }
        }
        return (myListedNFT,listedNFT);
    }
}