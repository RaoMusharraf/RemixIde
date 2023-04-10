// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
    Counters.Counter public _nftCount;
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    ERC721 token;
    address MinterAddress;
    address paymentToken;
    // address AddminAddress;
    mapping(uint256 => NFT) public _idToNFT;
    mapping (uint256 => Admin) public URI;
    struct NFT {
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
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);

    constructor(address ERC721NFT,address ERC20FT ){
        token = ERC721(ERC721NFT);
        MinterAddress = ERC721NFT;
        // AddminAddress = admin;
        paymentToken = ERC20FT;    
    }
    // ============ Mint FUNCTIONS ============
    //     @dev SingleMint mint one NFT.
    //     @dev BulkMint mint multi NFTs.
    //     @param id that are created by admin when admin enter data.
    function SingleMinting(string memory uri) public payable nonReentrant {
        tokenID.increment();
        IIERC721(MinterAddress).safeMint(msg.sender,tokenID.current(), uri);
        // IERC20(paymentToken).safeTransferFrom(msg.sender, AddminAddress , price);
        _idToNFT[tokenID.current()] = NFT(tokenID.current(),msg.sender,msg.sender,0,true);
    }
    function BulkMintNFTs(uint256 _mintAmount,string[] memory _tokenURI) public payable{
        require(_mintAmount == _tokenURI.length,"MintAmount and Length Of TokenUri must Same");
        require(_mintAmount > 0, "You can only mint more than 0 tokens");
        for (uint256 i = 0; i < _mintAmount; i++) {
            IIERC721(MinterAddress).safeMint(msg.sender,tokenID.current(), _tokenURI[i]);
            // IERC20(paymentToken).safeTransferFrom(msg.sender, AddminAddress , price);
            _idToNFT[tokenID.current()] = NFT(tokenID.current(),msg.sender,msg.sender,0,true);
        }
    }
    // ============ ListNft FUNCTIONS ============
    /* 
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(uint256 _tokenId, uint256 _price) public payable nonReentrant {
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        token.transferFrom(msg.sender, address(this), _tokenId);
        _idToNFT[_tokenId] = NFT(_tokenId,msg.sender,address(this),_price,false);
        _nftCount.increment();
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /* 
        @dev BuyNft convert the ownership seller to the buyer 
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint256 _tokenId) public payable nonReentrant {
        require(_idToNFT[_tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(msg.value >= _idToNFT[_tokenId].price , "Not enough ether to cover asking price !!!");
        IERC20(paymentToken).safeTransferFrom(msg.sender, _idToNFT[_tokenId].seller ,_idToNFT[_tokenId].price);
        token.transferFrom(address(this), msg.sender, _tokenId); 
        _idToNFT[_tokenId] = NFT(_tokenId,msg.sender,msg.sender,_idToNFT[_tokenId].price,true);
        _nftCount.decrement();
        emit NFTSold(_idToNFT[_tokenId].tokenId, _idToNFT[_tokenId].seller, msg.sender, msg.value);
    }
    // ============ CancelOffer FUNCTIONS ============
    /* 
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
    */
    function CancelOffer(uint256 _tokenId) public nonReentrant {
        require(!_idToNFT[_tokenId].listed,"Please List First !!!");
        require(_idToNFT[_tokenId].seller == msg.sender,"Only Owner Can Cancel !!!");
        token.transferFrom(address(this), msg.sender, _tokenId);
        _idToNFT[_tokenId].owner = msg.sender;
        _idToNFT[_tokenId].listed=true;
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[_tokenId].tokenId, _idToNFT[_tokenId].seller, msg.sender, _idToNFT[_tokenId].price);
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