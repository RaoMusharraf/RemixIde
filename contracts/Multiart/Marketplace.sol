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
    using SafeERC20 for IERC20;
    //Counter
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public nftAuctionCount;
    //Address
    address paymentToken;
    address tokenAddress;
    //Mapping
    mapping (address => mapping(uint256 => NFT)) public _idToNFT;
    mapping (uint => addressToken) public listCount;
    mapping (address => mapping (uint => nftAuction)) public NftAuction;
    mapping (uint => uint ) public userListCount;
    mapping (uint => addressToken) public auctionListCount;
    mapping (address => mapping(uint => mapping(uint=>userDetail))) public Bidding;
    mapping (address => mapping(uint => mapping(address=> mapping(uint=>uint)))) public BiddingCount;
    mapping (address => mapping(uint => mapping(address=>uint))) public userBiddingCount;
  
    //Struct
    struct NFT {
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 count;
        uint listTime;
        bool listed;
    }
    struct nftAuction{
        address owner;
        uint tokenId;
        uint minimumBid;
        uint startTime;
        uint endTime;
        uint listTime;
        bool isActive;
    }
    struct userDetail{
        address user;
        string userName;
        uint price;
        uint biddingTime;
    }
    struct addressToken{
        address contractAddress;
        uint tokenId;
    }
    struct ListTokenId{
        nftAuction listedData;
        uint listCount;
    }
    struct ListedNftTokenId{
        NFT listedData;
        uint listCount;
    }
    struct MyNft {
        uint256 tokenId;
        uint256 mintTime;
        address mintContract;
    }
    //Event
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price, uint SoldTime);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    event Claim(uint256 tokenId,address buyer,uint ClaimTime);
    //Constructor
    constructor(address _tokenAddress){
        tokenAddress = _tokenAddress;
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in marketplace for specific time.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
        @param _mintContract set deployed nftContract Address
        @param _startTime & _endTime set the Listing Time
    */
    function ListNft(address _mintContract,uint256 _price,uint256 _tokenId, uint256 _startTime, uint256 _endTime) public nonReentrant {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        require(_startTime < _endTime,"Time Overflow!");
        _nftCount.increment();
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_price,_startTime,_endTime,_nftCount.current(),block.timestamp,true);
        listCount[_nftCount.current()] = addressToken(_mintContract,_tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }   
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param listIndex is a counter of listed Nft's in Marketplace
        @param typ set the choice of payment method (1 for Ethereum & 2 for Erc20 Tokens)
        @param price set price of NFT 
    */
    function buyNft(uint listIndex,uint256 price,uint typ, uint _royltyPercentage, address _royalityAddress) public payable nonReentrant {
        uint startTime = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].start;
        uint endTime = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].end; 
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(startTime < block.timestamp && block.timestamp < endTime,"no longer available!");
        require(price >= _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        IConnected(listCount[listIndex].contractAddress).updateTokenId(msg.sender,listCount[listIndex].tokenId,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller);
        uint256 royaltyAmount = (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * _royltyPercentage) / 100;
        uint256 sellerAmount = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price - royaltyAmount;
        if(typ == 1){ 
            payable(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller).transfer(sellerAmount);
            payable (_royalityAddress).transfer(royaltyAmount);
        }  
        else if(typ == 2){  
            IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller,sellerAmount);
            IERC20(tokenAddress).safeTransferFrom(msg.sender,_royalityAddress,royaltyAmount);
        }
        else{
            revert("Please Enter the correct payment Type");
        }
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        IConnected(listCount[listIndex].contractAddress).update_TokenIdTime(listCount[listIndex].tokenId);
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTSold(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, msg.value,block.timestamp);
    }

    // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param listIndex is a counter of listed Nft's in Marketplace
    */
     
    function CancelOffer(uint listIndex) public nonReentrant {
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed,"Please List First !!!");
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner = msg.sender;
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price);
    }
    // ============ AuctionList FUNCTIONS ============
    /*
        @dev AuctionList list NFTs for Auction with tokenid & mint contract Address.
        @param _mintContract set deployed nftContract Address
        @param _tokenId that are minted by the nftContract
        @param _minimumBid set minimum price of NFT for Auction
        @param _startTime & _endTime set the Auction Listing & Ending Time respectively
        
    */
    function AuctionList(address _mintContract,uint _tokenId,uint _minimumBid,uint _startTime,uint _endTime) external {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(!NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        require(_startTime < _endTime,"Time Overflow!");
        nftAuctionCount.increment();
        NftAuction[_mintContract][_tokenId] = nftAuction(msg.sender,_tokenId,_minimumBid,_startTime,_endTime,block.timestamp,true);
        auctionListCount[nftAuctionCount.current()] = addressToken(_mintContract,_tokenId);
        userListCount[nftAuctionCount.current()] = 0; 
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId);
    }
    // ============ IncreaseAuctionTime FUNCTIONS ============
    /*
        @dev IncreaseAuctionTime Increase the Time For Auction.
        @param _mintContract set deployed nftContract Address
        @param _tokenId that are minted by the nftContract
        @param _totalBidTime set time of NFT for Auction
    */
    function IncreaseAuctionTime(address _mintContract,uint256 _tokenId,uint256 _totalBidTime) external {
        require(_idToNFT[_mintContract][_tokenId].seller== msg.sender,"You are not Owner");
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(NftAuction[_mintContract][_tokenId].isActive,"Already Listed In Auction!");
        require(_totalBidTime >= 1, "Bid Time Must Be One Hour!");
        NftAuction[_mintContract][_tokenId].startTime = block.timestamp;
        NftAuction[_mintContract][_tokenId].endTime = block.timestamp + (3600 * _totalBidTime);
    }
    // ============ NftBidding FUNCTIONS ============
    /*
        @dev NftBidding set the bidding on _auctionListCount with name & bidding price.
        @param _auctionListCount is a counter of listed Nft's for Auction
        @param _name set bidder's name
        @param _price set bid price of NFT for Auction
    */
    function NftBidding(uint _auctionListCount,string memory _name, uint _price) external {
        address contractAddress = auctionListCount[_auctionListCount].contractAddress;
        uint tokenId = auctionListCount[_auctionListCount].tokenId;
        uint userCount = userBiddingCount[contractAddress][tokenId][msg.sender];
        require(NftAuction[contractAddress][tokenId].owner != msg.sender,"You are Not Eligible for Bidding");
        require(NftAuction[contractAddress][tokenId].isActive,"Not Listed In Auction!");
        require(NftAuction[contractAddress][tokenId].startTime < block.timestamp ,"Bidding Not Start!");
        require(_price >= NftAuction[contractAddress][tokenId].minimumBid,"Amount Should be greater than MinimumBid");
        require(block.timestamp < NftAuction[contractAddress][tokenId].endTime,"Bidding is going on!");
        Bidding[contractAddress][tokenId][userListCount[_auctionListCount]+1] = userDetail(msg.sender,_name,_price,block.timestamp);
        BiddingCount[contractAddress][tokenId][msg.sender][userCount+1] = userListCount[_auctionListCount]+1;
        userBiddingCount[contractAddress][tokenId][msg.sender]++;
        userListCount[_auctionListCount]++;
    }
    // ============ cancelAuctionList FUNCTIONS ============
    /*
        @dev cancelAuctionList cancel the AuctionListed Nft.
        @param _auctionListCount is a counter of listed Nft's for Auction 
        
    */
    function cancelAuctionList(uint _auctionListCount) external {
        require(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner == msg.sender,"Only Owner Can Cancel!!");
        ERC721(auctionListCount[_auctionListCount].contractAddress).transferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId);
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete auctionListCount[nftAuctionCount.current()];
        delete userListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
    }
    // ============ ClaimNFT FUNCTIONS ============
    /*
        @dev ClaimNFT highest bidder claim his/her Nft.
        @param _auctionListCount is a counter of listed Nft's for Auction
        @param typ set the choice of payment method (1 for Ethereum & 2 for Erc20 Tokens)
    */
    function ClaimNFT(uint _auctionListCount,uint typ, uint _royltyPercentage, address _royalityAddress) external payable {
        require(block.timestamp > NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].endTime,"Bidding is still going on!");
        userDetail memory selectedUser;
        selectedUser = selectUser(_auctionListCount);
        uint256 royaltyAmount = (selectedUser.price * _royltyPercentage) / 100;
        uint256 sellerAmount = selectedUser.price - royaltyAmount;
        require(selectedUser.user == msg.sender ,"you are not sellected bidder");
        if(typ == 1){ 
            require(msg.value >= selectedUser.price,"Incorrect Price");
            payable(NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner).transfer(sellerAmount);
            payable(_royalityAddress).transfer(royaltyAmount);
        }  
        else if(typ == 2){  
            IERC20(tokenAddress).safeTransferFrom(selectedUser.user,NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner,sellerAmount);
            IERC20(tokenAddress).safeTransferFrom(selectedUser.user,_royalityAddress,royaltyAmount);
        }
        else{
            revert("Please Enter the correct payment Type");
        }
        ERC721(auctionListCount[_auctionListCount].contractAddress).transferFrom(address(this), msg.sender, auctionListCount[_auctionListCount].tokenId);
        emit Claim(auctionListCount[_auctionListCount].tokenId,msg.sender,block.timestamp);
        IConnected(auctionListCount[_auctionListCount].contractAddress).updateTokenId(msg.sender,auctionListCount[_auctionListCount].tokenId,NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].owner);
        NftAuction[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId].isActive = false;
        IConnected(auctionListCount[_auctionListCount].contractAddress).update_TokenIdTime(auctionListCount[_auctionListCount].tokenId);
        auctionListCount[_auctionListCount] = auctionListCount[nftAuctionCount.current()];       
        userListCount[_auctionListCount] = userListCount[nftAuctionCount.current()];
        delete auctionListCount[nftAuctionCount.current()];
        delete userListCount[nftAuctionCount.current()];
        nftAuctionCount.decrement();
       
    }
    // ============ selectUser FUNCTIONS ============
    /*
        @dev cancelBid cancel the bid of user 
        @param _auctionListIndex is a counter of listed Nft's for Auction
    */
    function cancelBid(uint _auctionListIndex) external {
        address contractAddress = auctionListCount[_auctionListIndex].contractAddress;
        uint tokenId = auctionListCount[_auctionListIndex].tokenId;
        uint userCount = userBiddingCount[contractAddress][tokenId][msg.sender];
        uint count = BiddingCount[contractAddress][tokenId][msg.sender][userCount];
        require( Bidding[contractAddress][tokenId][count].user == msg.sender,"please bid first!");
        require(block.timestamp < NftAuction[contractAddress][tokenId].endTime,"Auction Ended!");
        delete Bidding[contractAddress][tokenId][count];
        delete BiddingCount[contractAddress][tokenId][msg.sender][count];
        userBiddingCount[contractAddress][tokenId][msg.sender]--;
    }
    // ============ selectUser FUNCTIONS ============
    /*
        @dev selectUser getting highest bidder overall.
        @param _auctionListCount 
        @return userDetail array of user's data who has done bidding
    */
    function selectUser(uint _auctionListCount) public view returns(userDetail memory){
        uint heighest = 0;
        userDetail memory selectedUser;
        for(uint i = 1 ; i <= userListCount[_auctionListCount] ; i++){
            if(heighest < Bidding[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId][i].price){
                heighest = Bidding[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId][i].price;
                selectedUser = Bidding[auctionListCount[_auctionListCount].contractAddress][auctionListCount[_auctionListCount].tokenId][i];
            }
        }
        return (selectedUser);
    }
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @param _to get all the listed NFT's of anyone's address
        @return ListedNftTokenId array of MyNFTs that are listed
        @return ListedNftTokenId array of NFTs that are listed

    */
    function getListedNfts(address _to) public view returns (ListedNftTokenId[] memory,ListedNftTokenId[] memory) {
        uint myListedCount = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller == _to) && (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                myListedCount++;
            }
        }
        ListedNftTokenId[] memory myListedNFT = new ListedNftTokenId[](myListedCount);
        if(myListedCount != 0){
            uint myListedIndex = 0;
            for (uint i = 1; i <= _nftCount.current() ; i++) {
                if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller == _to) && (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                    myListedNFT[myListedIndex] = ListedNftTokenId(_idToNFT[listCount[i].contractAddress][listCount[i].tokenId],i);
                    myListedIndex++;
                }
            }
        }
        uint listNft = (_nftCount.current()-myListedCount);
        ListedNftTokenId[] memory listedNFT = new ListedNftTokenId[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller != _to) && (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                listedNFT[listedIndex] = ListedNftTokenId(_idToNFT[listCount[i].contractAddress][listCount[i].tokenId],i);
                listedIndex++;
            }
        }
        return (myListedNFT,listedNFT);
    }
    // ============ getAuctionListedNfts FUNCTIONS ============
    /*
        @dev getAuctionListedNfts fetch all the NFTs that are listed for Auction.
        @param _to get all the listed NFT's of anyone's address
        @return ListedNftTokenId array of MyNFTs that are listed for Auction     
        @return ListedNftTokenId array of NFTs that are listed for Auction
    */
    function getAuctionListedNfts(address _to) public view returns (ListTokenId[] memory,ListTokenId[] memory) {
        uint myListedCount = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if ((NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].owner == _to) && (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive)) {
                myListedCount++;
            }
        }
        ListTokenId[] memory myListedNFT = new ListTokenId[](myListedCount);
        if(myListedCount != 0){
            uint myListedIndex = 0;
            for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
                if ((NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].owner == _to) && (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive)) {
                    myListedNFT[myListedIndex] = ListTokenId(NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId],i);
                    myListedIndex++;
                }
            } 
        }
        uint listNft = (nftAuctionCount.current()-myListedCount);
        ListTokenId[] memory listTokenId = new ListTokenId[](listNft);
        uint listedIndexCount = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if ((NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].owner != _to) && (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive)) {
                listTokenId[listedIndexCount] = ListTokenId(NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId],i);
                listedIndexCount++;
            }
        }
        return (myListedNFT,listTokenId);
    }
    // ============ getBiddingHistory FUNCTIONS ============
    /*
        @dev getBiddingHistory showing all bidding history on Listcount.
        @param _listCount is a counter of listed Nft's in Marketplace
        @return userDetail array of user's data who has done bidding
    */
    function getBiddingHistory(uint _listCount) external view returns(userDetail[] memory){
        address contractAddress = auctionListCount[_listCount].contractAddress;
        uint tokenId = auctionListCount[_listCount].tokenId;
        uint indexCount = 0;
        userDetail[] memory BiddingHistory = new userDetail[](userListCount[_listCount]);
        for(uint i=1; i <= userListCount[_listCount];i++){
            BiddingHistory[indexCount] = Bidding[contractAddress][tokenId][i];
            indexCount++;
        }
        return BiddingHistory;
    }
    // function getNFTDetail(address _to, address contractAddress) external view returns (IConnected.MyNft[] memory) {
    //     IConnected.MyNft[] memory myNFT = IConnected(contractAddress).getTokenId(_to);
    //     return myNFT;
    // }
    function getNFTDetail(address _to, address[] memory contractAddresses) external view returns (MyNft[][] memory) {
        MyNft[][] memory myNFT = new MyNft[][](contractAddresses.length);
        for (uint i = 0; i < contractAddresses.length; i++) {
            IConnected.MyNft[] memory connectedNft = IConnected(contractAddresses[i]).getTokenId(_to);
            myNFT[i] = new MyNft[](connectedNft.length);
            for(uint j = 0 ; j < connectedNft.length ; j++){
                myNFT[i][j] = MyNft(connectedNft[j].tokenId,connectedNft[j].mintTime,connectedNft[j].mintContract);
            }
        }
        return (myNFT);
    }
}