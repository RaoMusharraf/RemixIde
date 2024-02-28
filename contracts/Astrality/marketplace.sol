// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
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
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public totalSales;
    Counters.Counter public totalRented;
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    ERC721 token;
    address MinterAddress;
    address usdtToken;
    address AddminAddress;
    mapping(uint256 => NFT) public _idToNFT;
    mapping (uint256 => Admin) public URI;
    mapping (uint256 => uint256) public Id;
    mapping (address => mapping(uint256 => uint)) public getTokenId;
    mapping (uint => rentOffer ) public NFTOwner;
    mapping (address => uint256) public countRentNFTs;
    mapping (address => mapping(uint256 => uint)) public getRentTokenId;
    mapping (uint => buyRentOffer ) public ActiveRentOffer;
    mapping (address => uint256) public countBuyRentNFTs;
    mapping (uint => address) public BuyerAddress;
    mapping (address => uint) public ownerRentProfit;
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
    struct buyRentOffer{
        address buyer;
        uint tokenId;
        uint startTime;
        uint endTime;
    }
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);

    constructor(address ERC20FT,address ERC721NFT,address initialOwner) Ownable(initialOwner){
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
    function Buy(uint256 price,uint256 tokenId,string memory _coordinate) public payable nonReentrant {
        tokenID.increment();
        IConnected(MinterAddress).safeMint(msg.sender,tokenId);
        // payable(AddminAddress).transfer(AdminPrice);
        Id[tokenId] = tokenID.current();
        IERC20(usdtToken).safeTransferFrom(msg.sender, AddminAddress , price);
        _idToNFT[tokenID.current()] = NFT(tokenId,_coordinate,msg.sender,msg.sender,price,true);
        
    }
    // ============ MakeOffer FUNCTIONS ============
    function MakeRentOffer(address _owner,uint _tokenId,uint _month,uint _price,string memory _coordinate) external nonReentrant{
        require(token.ownerOf(_tokenId)==_owner,"You are Not Owner of this NFT");
        require(_idToNFT[Id[_tokenId]].listed,"Please Cancel the NFT from List!");
        require(!((ActiveRentOffer[_tokenId].startTime < block.timestamp ) && (block.timestamp  < ActiveRentOffer[_tokenId].endTime)),"Already for Rent");
        require(!NFTOwner[_tokenId].isActive,"You have already List this NFT for Rent!!!");
        if(!NFTOwner[_tokenId].second){
            getTokenId[_owner][countRentNFTs[_owner]+1] = _tokenId;
            NFTOwner[_tokenId] = rentOffer(_owner,_tokenId,(countRentNFTs[_owner]+1),_month,_price,_coordinate,true,true);
            countRentNFTs[_owner]++; 
        }else{
            NFTOwner[_tokenId] = rentOffer(_owner,_tokenId,NFTOwner[_tokenId].count,_month,_price,_coordinate,true,true);
        }
    }
    // ============ BuyRentOffer FUNCTIONS ============
    function BuyRentOffer(address _buyer,uint _tokenId,uint _price) external nonReentrant{
        require(token.ownerOf(_tokenId) != _buyer,"You are Not Eligible to buy Rent Offer");
        require(NFTOwner[_tokenId].isActive,"This Is Not For Rent!");
        require(_price == NFTOwner[_tokenId].price,"Insuficent Amount!");
        if(countBuyRentNFTs[_buyer] == 0){
            totalRented.increment();
            BuyerAddress[totalRented.current()] = _buyer;
        }
        getRentTokenId[_buyer][countBuyRentNFTs[_buyer]+1] = _tokenId;
        IERC20(usdtToken).safeTransferFrom(_buyer,NFTOwner[_tokenId].owner,NFTOwner[_tokenId].price);
        ActiveRentOffer[_tokenId] = buyRentOffer(_buyer,_tokenId,block.timestamp,((NFTOwner[_tokenId].month*2629743)+block.timestamp));
        NFTOwner[_tokenId].isActive = false;
        ownerRentProfit[NFTOwner[_tokenId].owner] += NFTOwner[_tokenId].price;
        countBuyRentNFTs[_buyer]++;

    }
    // ============ getBuyerRentNFTs FUNCTIONS ============
    function getBuyerRentNFTs(address _rentOwner) external view returns(rentOffer[] memory){

        uint myNftCount = 0;
        for (uint i = 1; i <= countBuyRentNFTs[_rentOwner]; i++) {
            if (((ActiveRentOffer[getRentTokenId[_rentOwner][i]].startTime < block.timestamp ) && (block.timestamp < ActiveRentOffer[getRentTokenId[_rentOwner][i]].endTime))) {
                myNftCount++;
            }
        }
        
        rentOffer[] memory rentNfts = new rentOffer[](myNftCount);
        uint nftsRentIndex = 0;
        for (uint i = 1; i <= countBuyRentNFTs[_rentOwner] ; i++) {
            if (((ActiveRentOffer[getRentTokenId[_rentOwner][i]].startTime < block.timestamp ) && (block.timestamp < ActiveRentOffer[getRentTokenId[_rentOwner][i]].endTime))) {
                rentNfts[nftsRentIndex] = NFTOwner[getRentTokenId[_rentOwner][i]];
                nftsRentIndex++;
            }
        }
        return rentNfts;
    }
    // ============ getTotalRented FUNCTIONS ============
    function getTotalRented() external view returns(uint){
        // totalRented
        uint myNftCount = 0;
        for (uint j ; j <= totalRented.current() ; j++) 
        {
            for (uint i = 1; i <= countBuyRentNFTs[BuyerAddress[j]]; i++) {
                if (((ActiveRentOffer[getRentTokenId[BuyerAddress[j]][i]].startTime < block.timestamp ) && (block.timestamp < ActiveRentOffer[getRentTokenId[BuyerAddress[j]][i]].endTime))) {
                    myNftCount++;
                }
            }
        }

        return myNftCount;
    }
    // ============ CancelRentOffer FUNCTIONS ============
    function CancelRentOffer(address _owner,uint _tokenId) external nonReentrant{
        require(token.ownerOf(_tokenId)==_owner,"You are Not Owner of this NFT");
        require(NFTOwner[_tokenId].isActive,"This Is Not For Rent!");
        require(!((ActiveRentOffer[_tokenId].startTime < block.timestamp ) && (block.timestamp  < ActiveRentOffer[_tokenId].endTime)),"Already for Rented");
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
        require(!((ActiveRentOffer[_tokenId].startTime < block.timestamp ) && (block.timestamp  < ActiveRentOffer[_tokenId].endTime)),"Already for Rent");
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
        // payable(_idToNFT[Id[_tokenId]].seller).transfer(_idToNFT[Id[_tokenId]].price);
        IERC20(usdtToken).safeTransferFrom(msg.sender, _idToNFT[Id[_tokenId]].seller ,_idToNFT[Id[_tokenId]].price);
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[Id[_tokenId]] = NFT(_tokenId,_idToNFT[Id[_tokenId]].coordinate,msg.sender,msg.sender,_idToNFT[Id[_tokenId]].price,true);
        _nftCount.decrement();
        totalSales.increment();
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
        bool isTrue = true;
        uint nftsRentIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            for(uint k = 0; k < i ; k++ ){
                if(countRentNFTs[_idToNFT[i].seller] == countRentNFTs[_idToNFT[k].seller]){
                    isTrue = false;
                    break;
                }
            }
            if(isTrue){
                for(uint j = 1; j <= countRentNFTs[_idToNFT[i].seller] ; j++){
                    if (NFTOwner[getTokenId[_idToNFT[i].seller][j]].owner != _to && NFTOwner[getTokenId[_idToNFT[i].seller][j]].isActive) {
                        rentNfts[nftsRentIndex] = NFTOwner[getTokenId[_idToNFT[i].seller][j]];
                        nftsRentIndex++;
                    }
                }
            }
            isTrue = true;
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
        bool isTrue = true;
        rentOffer[] memory rentNfts = new rentOffer[](myNftCount);
        for (uint i = 1; i <= nftCount ; i++) {
            for(uint k = 0; k < i ; k++ ){
                if(countRentNFTs[_idToNFT[i].seller] == countRentNFTs[_idToNFT[k].seller]){
                    isTrue = false;
                    break;
                }
            }
            if(isTrue){
                for(uint j = 1; j <= countRentNFTs[_idToNFT[i].seller] ; j++){
                    if (NFTOwner[getTokenId[_idToNFT[i].seller][j]].owner == _sender && NFTOwner[getTokenId[_idToNFT[i].seller][j]].isActive) {
                        rentNfts[nftsRentIndex] = NFTOwner[getTokenId[_idToNFT[i].seller][j]];
                        nftsRentIndex++;
                    }
                }
            }
            isTrue = true;
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
