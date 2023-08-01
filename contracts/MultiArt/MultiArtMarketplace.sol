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
    ERC721 token;
    address MinterAddress;
    address paymentToken;
    address AddminAddress;
    uint256 AdminPricePer;
    address tokenAddress;
    mapping(address => mapping(uint256 => NFT)) public _idToNFT;
    mapping (address => Admin) public AdminCalculation;
    // mapping (uint256 => uint256) public Id;
    struct NFT {
        uint256 tokenId;
        address seller;
        address owner;
        address royalityAddress;
        uint256 royalitypercentage;
        bool royalityCheck; 
        uint256 price;
        bool listed;
    }
    struct Admin {
        uint256 TotalSale;
        uint256 TotalProfit;
    }
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    constructor(address ERC721NFT, address _AdminAddress, uint256 _AdminPricePer,address _tokenAddress){
        token = ERC721(ERC721NFT);
        MinterAddress = ERC721NFT;
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
    function ListNft(address _mintContract,uint256 _royalityPercentage,uint256 _price,uint256 _tokenId) public nonReentrant {
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        if(_idToNFT[_mintContract][_tokenId].royalityCheck){
            _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_idToNFT[_mintContract][_tokenId].royalityAddress,_idToNFT[_mintContract][_tokenId].royalitypercentage,false,_price,false);
        }else{
            _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_idToNFT[_mintContract][_tokenId].royalityAddress,_royalityPercentage,false,_price,false);    
        }
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        _nftCount.increment();  
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(address _mintContract,uint256 price,uint256 _tokenId,uint typ) public payable nonReentrant {
        require(_idToNFT[_mintContract][_tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price >= _idToNFT[_mintContract][_tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(_mintContract).transferFrom(address(this), msg.sender, _tokenId);
        if(_idToNFT[_mintContract][_tokenId].royalityCheck){
            uint256 AdminPrice = (AdminPricePer * _idToNFT[_mintContract][_tokenId].price)/100;
            uint256 royality_amount = (_idToNFT[_mintContract][_tokenId].royalitypercentage * _idToNFT[_mintContract][_tokenId].price)/100;
            uint256 amount = _idToNFT[_mintContract][_tokenId].price - (royality_amount + AdminPricePer);
            AdminCalculation[AddminAddress] = Admin((AdminCalculation[AddminAddress].TotalSale + price),(AdminCalculation[AddminAddress].TotalProfit + AdminPrice));
            if(typ == 1){
                payable(_idToNFT[_mintContract][_tokenId].royalityAddress).transfer(royality_amount);  
                payable(AddminAddress).transfer(AdminPrice);
                payable(_idToNFT[_mintContract][_tokenId].seller).transfer(amount);
            }  
            else if(typ == 2){  
                IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[_mintContract][_tokenId].royalityAddress,royality_amount);
                IERC20(tokenAddress).safeTransferFrom(msg.sender,AddminAddress,AdminPrice);
                IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[_mintContract][_tokenId].seller,amount);
            }
            else{
                revert("Please Enter the correct payment Type");
            }
        }
        else{
            uint256 AdminPrice = (AdminPricePer * _idToNFT[_mintContract][_tokenId].price)/100;
            uint256 amount = _idToNFT[_mintContract][_tokenId].price - AdminPrice ;
            AdminCalculation[AddminAddress] = Admin((AdminCalculation[AddminAddress].TotalSale + price),(AdminCalculation[AddminAddress].TotalProfit + AdminPrice));
            payable(AddminAddress).transfer(AdminPrice);
            payable(_idToNFT[_mintContract][_tokenId].seller).transfer(amount); 
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
        }
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,msg.sender,_idToNFT[_mintContract][_tokenId].royalityAddress,_idToNFT[_mintContract][_tokenId].royalitypercentage,true,_idToNFT[_mintContract][_tokenId].price,true);
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
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_mintContract][_tokenId].owner = msg.sender;
        _idToNFT[_mintContract][_tokenId].listed=true;
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[_mintContract][_tokenId].tokenId, _idToNFT[_mintContract][_tokenId].seller, msg.sender, _idToNFT[_mintContract][_tokenId].price);
    }
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
    */
    function getListedNfts(address _to,address _mintContract) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint list = _nftCount.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[_mintContract][i].seller == _to) && (!_idToNFT[_mintContract][i].listed)) {
                myListedNftCount++;
            }
        }
        uint remaning = list - myListedNftCount ;
        NFT[] memory nfts = new NFT[](remaning);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((_idToNFT[_mintContract][i].seller != _to) && (!_idToNFT[_mintContract][i].listed)) {
                nfts[nftsIndex] = _idToNFT[_mintContract][i];
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
    function getNotListedNfts(address _to,address _mintContract) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint list = _nftCount.current();
        uint notlist = nftCount - list;
        uint myNotListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[_mintContract][i].seller == _to) && (_idToNFT[_mintContract][i].listed)) {
                myNotListedNftCount++;
            }
        }
        uint remaning = notlist - myNotListedNftCount ;
        NFT[] memory nfts = new NFT[](remaning);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount ; i++) {
            if ((_idToNFT[_mintContract][i].seller != _to) && (_idToNFT[_mintContract][i].listed)) {
                nfts[nftsIndex] = _idToNFT[_mintContract][i];
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
    function getMyNfts(address _sender,address _mintContract) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint myNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if (_idToNFT[_mintContract][i].owner == _sender) {
                myNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myNftCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if (_idToNFT[_mintContract][i].owner == _sender) {
                nfts[nftsIndex] = _idToNFT[_mintContract][i];
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
    function getMyListedNfts(address _sender,address _mintContract) public view returns (NFT[] memory) {
        uint nftCount = tokenID.current();
        uint myListedNftCount = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[_mintContract][i].seller == _sender) && (!_idToNFT[_mintContract][i].listed)) {
                myListedNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 1; i <= nftCount; i++) {
            if ((_idToNFT[_mintContract][i].seller == _sender) && (!_idToNFT[_mintContract][i].listed)) {
                nfts[nftsIndex] = _idToNFT[_mintContract][i];
                nftsIndex++;
            }
        }
        return nfts;
    }
    // ============ ListedId FUNCTIONS ============
    /*
        @dev ListedId fetch owner of Id, bool List Check and Price.
        @return Owner of Id, bool List Check and Price.
    */
    function ListedId(uint256 tokenId,address _mintContract) public view returns(address seller,bool Listed,uint256 Price) {
        require(tokenId > 0 && tokenId <= tokenID.current(),"Token Id NOT Exist");
        if(!_idToNFT[_mintContract][tokenId].listed){
            return (_idToNFT[_mintContract][tokenId].seller,!_idToNFT[_mintContract][tokenId].listed,_idToNFT[_mintContract][tokenId].price);
        }else{
            return (_idToNFT[_mintContract][tokenId].seller,!_idToNFT[_mintContract][tokenId].listed,0);
        }     
    } 
}