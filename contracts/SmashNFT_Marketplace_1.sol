// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @title MarketPlace
 */
contract SmashNFT_Marketplace is ReentrancyGuard , Ownable{
    
    using Counters for Counters.Counter;
    Counters.Counter public _nftsSold;
    Counters.Counter public _nftCount;
    
    uint256 public LISTING_FEE = 0 ;
    address payable private _marketOwner;
    mapping (uint => address) public FirstOwner;
    mapping (uint256 => Check) public check;
    mapping(uint256 => NFT) private _idToNFT;
    struct NFT {
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool listed;
    }
    struct Check{
        bool _check;
        address _address;
    }
    event NFTListed(address nftContract,uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(address nftContract,uint256 tokenId,address seller,address owner,uint256 price);
    ERC721 token;
    address MinterAddress;

    constructor(address contractAddr){
        token = ERC721(contractAddr);
        MinterAddress = contractAddr;
    }

    // ============ ListNft FUNCTIONS ============
    /* 
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(uint256 _tokenId, uint256 _price) public payable nonReentrant {

        require(_price > 0, "Price must be at least 1 wei");
        require(!(check[_tokenId]._check),"One Token ID Listed One Time");
        //token.approve(address(this),_tokenId);
        token.transferFrom(msg.sender, address(this), _tokenId);
        _nftCount.increment();
        _idToNFT[_tokenId] = NFT(MinterAddress,_tokenId,payable(msg.sender),payable(address(this)),_price,false);
        FirstOwner[_tokenId]=msg.sender;
        check[_tokenId]._address=msg.sender;
        emit NFTListed(MinterAddress, _tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /* 
        @dev BuyNft convert the ownership seller to the buyer 
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint256 _tokenId) public payable nonReentrant {
        NFT storage nft = _idToNFT[_tokenId];
        require(msg.value >= nft.price , "Not enough ether to cover asking price");
        require(_idToNFT[_tokenId].seller != msg.sender, "An offer cannot buy this Seller");
        address payable buyer = payable(msg.sender);
        uint result = nft.price - LISTING_FEE;
        payable(nft.seller).transfer(result);
        token.transferFrom(address(this), buyer, nft.tokenId);  
        payable(FirstOwner[_tokenId]).transfer(LISTING_FEE);
        nft.owner = buyer;
        nft.listed=true;
        check[_tokenId]._check = true;
        _nftsSold.increment();
        emit NFTSold(MinterAddress, nft.tokenId, nft.seller, buyer, msg.value);
    }

    // ============ ReSellNFT FUNCTIONS ============
    /* 
        @dev resellNft again list the NFT with same TokenId and new seller
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ReSellNft(uint256 _tokenId, uint256 _price) public payable nonReentrant {
        require(_price > 0, "Price must be at least 1 wei");
        require(_idToNFT[_tokenId].owner == msg.sender,"Only owner Of this Token Can Resell");
        if(_idToNFT[_tokenId].seller != _idToNFT[_tokenId].owner){
            require(ClaculatePrice(_idToNFT[_tokenId].price) >= _price ,"This Price Is More Than 20%");
        }
        token.transferFrom(msg.sender, address(this), _tokenId);
        NFT storage nft = _idToNFT[_tokenId];
        nft.seller = payable(msg.sender);
        nft.owner = payable(address(this));
        nft.listed = false;
        nft.price = _price;
        check[_tokenId]._address = msg.sender;
        _nftsSold.decrement();
        emit NFTListed(MinterAddress, _tokenId, msg.sender, address(this), _price);
    }
    // ============ CancelOffer FUNCTIONS ============
    /* 
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(uint256 _tokenId) public{
        require(check[_tokenId]._address == msg.sender,"Only Owner can Cancel");
        check[_tokenId]._check = true;
        _idToNFT[_tokenId].listed=true;
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_tokenId].owner = payable(msg.sender);
        _nftsSold.increment();
    }
    // ============ CalculatePrice FUNCTIONS ============
    /* 
        @dev ClaculatePrice New price in the reSell not greater than 20% with the last price
        @return calculated price
    */
    function ClaculatePrice(uint _price) public pure returns(uint){
        uint a = 5;
        uint result; 
        result = _price + (_price/a);
        return result;
    }
    // ============ GetLintingFee FUNCTIONS ============
    /* 
        @return LISTING_FEE amount that transfer to the first owner
    */
    function GetListingFee() public view returns (uint256) {
        return LISTING_FEE;
    }
    // ============ SetLintingFee FUNCTIONS ============
    /* 
        @dev SetListingFee Set amount of ListingFee
        @param _ListingFee  amount set to the "LISTING_FEE"
    */
    function SetListingFee(uint256 _ListingFee) public onlyOwner{
        LISTING_FEE = _ListingFee;
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
        for (uint i = 0; i < nftCount; i++) {
            if (!_idToNFT[i + 1].listed) {
                nfts[nftsIndex] = _idToNFT[i + 1];
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
    function getMyNfts() public view returns (NFT[] memory) {
        uint nftCount = _nftCount.current();
        uint myNftCount = 0;
        for (uint i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].owner == msg.sender) {
                myNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myNftCount);
            uint nftsIndex = 0;
            for (uint i = 0; i < nftCount; i++) {
                if (_idToNFT[i + 1].owner == msg.sender) {
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
    function getMyListedNfts() public view returns (NFT[] memory) {
        uint nftCount = _nftCount.current();
        uint myListedNftCount = 0;
        for (uint i = 0; i < nftCount; i++) {
            if ((_idToNFT[i + 1].seller == msg.sender) && (!_idToNFT[i + 1].listed)) {
                myListedNftCount++;
            }
        }
        NFT[] memory nfts = new NFT[](myListedNftCount);
        uint nftsIndex = 0;
        for (uint i = 0; i < nftCount; i++) {
            if (_idToNFT[i + 1].seller == msg.sender && (!_idToNFT[i + 1].listed)) {
                nfts[nftsIndex] = _idToNFT[i + 1];
                nftsIndex++;
            }
        }
        return nfts;
    }
}
