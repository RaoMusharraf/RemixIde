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
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    address MinterAddress;
    address paymentToken;
    address AddminAddress;
    uint256 AdminPricePer;
    address tokenAddress;
    mapping(address => mapping(uint256 => NFT)) public _idToNFT;
    mapping (uint => addressToken) public listCount;
    mapping (address => Admin) public AdminCalculation;
    // mapping (uint256 => uint256) public Id;
    struct NFT {
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        uint256 count;
        bool listed;
    }
    struct Admin {
        uint256 TotalSale;
        uint256 TotalProfit;
    }
    struct addressToken{
        address contractAddress;
        uint tokenId;
    }
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    constructor(address _AdminAddress, uint256 _AdminPricePer,address _tokenAddress){
        AddminAddress = _AdminAddress;
        AdminPricePer = _AdminPricePer;
        tokenAddress = _tokenAddress;
    }
    // ============ setAdminPrice FUNCTIONS ============
    /* 
        @param price is the NFT value from AdminSide.
    */
    function setAdminPrice (uint256 _AdminPricePer) public onlyOwner{
        AdminPricePer = _AdminPricePer;
    }
    // ============ getAdminPrice FUNCTIONS ============
    /* 
        @param price is the NFT value from AdminSide.
    */
    function getAdminPrice () public view returns(uint256 price) {
        return AdminPricePer;
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(address _mintContract,uint256 _price,uint256 _tokenId) public nonReentrant {
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        _nftCount.increment();
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_price,_nftCount.current(),false);
        listCount[_nftCount.current()] = addressToken(_mintContract,_tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(address _mintContract,uint256 _tokenId,uint256 price,uint typ) public payable nonReentrant {
        require(_idToNFT[_mintContract][_tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price >= _idToNFT[_mintContract][_tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(_mintContract).transferFrom(address(this), msg.sender, _tokenId);
        uint256 AdminPrice = (AdminPricePer * _idToNFT[_mintContract][_tokenId].price)/100;

        uint256 amount = _idToNFT[_mintContract][_tokenId].price - AdminPrice;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = _idToNFT[_mintContract][_tokenId].count;
        listCount[_idToNFT[_mintContract][_tokenId].count] = listCount[_nftCount.current()];
        delete listCount[_nftCount.current()];
        AdminCalculation[AddminAddress] = Admin((AdminCalculation[AddminAddress].TotalSale + price),(AdminCalculation[AddminAddress].TotalProfit + AdminPrice));
        if(typ == 1){ 
            payable(AddminAddress).transfer(AdminPrice);
            payable(_idToNFT[_mintContract][_tokenId].seller).transfer(amount);
        }  
        else if(typ == 2){  
            IERC20(tokenAddress).safeTransferFrom(msg.sender,AddminAddress,AdminPrice);
            IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[_mintContract][_tokenId].seller,amount);
        }
        else{
            revert("Please Enter the correct payment Type");
        }
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,msg.sender,_idToNFT[_mintContract][_tokenId].price,_idToNFT[_mintContract][_tokenId].count,true);
        _nftCount.decrement();
        emit NFTSold(_idToNFT[_mintContract][_tokenId].tokenId, _idToNFT[_mintContract][_tokenId].seller, msg.sender, msg.value);
    }
   // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(address _mintContract,uint256 _tokenId) public nonReentrant {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Please List First !!!");
        require(_idToNFT[_mintContract][_tokenId].seller == msg.sender,"Only Owner Can Cancel !!!");
        ERC721(_mintContract).transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_mintContract][_tokenId].owner = msg.sender;
        _idToNFT[_mintContract][_tokenId].listed=true;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = _idToNFT[_mintContract][_tokenId].count;
        listCount[_idToNFT[_mintContract][_tokenId].count] = listCount[_nftCount.current()];
        delete listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[_mintContract][_tokenId].tokenId, _idToNFT[_mintContract][_tokenId].seller, msg.sender, _idToNFT[_mintContract][_tokenId].price);
    }
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
    */
    function getListedNfts(address _to) public view returns (NFT[] memory,NFT[] memory) {
        uint myListedCount = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller == _to) && (!_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                myListedCount++;
            }
        }
        NFT[] memory myListedNFT = new NFT[](myListedCount);
        if(myListedCount != 0){
            uint myListedIndex = 0;
            for (uint i = 1; i <= _nftCount.current() ; i++) {
                if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller == _to) && (!_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                    myListedNFT[myListedIndex] = _idToNFT[listCount[i].contractAddress][listCount[i].tokenId];
                    myListedIndex++;
                }
            }
        }
        uint listNft = (_nftCount.current()-myListedCount);
        NFT[] memory listedNFT = new NFT[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if ((_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].seller != _to) && (!_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed)) {
                listedNFT[listedIndex] = _idToNFT[listCount[i].contractAddress][listCount[i].tokenId];
                listedIndex++;
            }
        }
        return (myListedNFT,listedNFT);
    }
}