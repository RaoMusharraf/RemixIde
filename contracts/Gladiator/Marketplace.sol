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
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public _URICount;
    Counters.Counter public tokenID;
    address MinterAddress;
    address GladiatorToken;
    address AddminAddress;
    mapping(uint256 => NFT) public _idToNFT;
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
    constructor(address ERC20FT,address ERC721NFT, address _AdminAddress){
        GladiatorToken = ERC20FT;
        MinterAddress = ERC721NFT;
        AddminAddress = _AdminAddress;
    }
    // ============ BuyAdmin FUNCTIONS ============
    /*
        @dev BuyAdmin buy NFTs from Admin using id.
        @param id that are created by admin when admin enter data.
    */
    function Buy(uint price,string memory uri) external payable nonReentrant {
        tokenID.increment();
        IConnected(MinterAddress).safeMint(msg.sender,tokenID.current(),uri);
        IERC20(GladiatorToken).safeTransferFrom(msg.sender, AddminAddress , price);
        _idToNFT[tokenID.current()] = NFT(tokenID.current(),msg.sender,msg.sender,msg.sender,0,false,price,true);
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
    // ============ getTokenId FUNCTIONS ============
    /*
        @dev getTokenId fetch all the NFT ids that are listed by given address
        @return array of NFT ids that are listed by the given address
    */
    function getTokenId(address to) public view returns (uint[] memory){
        return IConnected(MinterAddress).getTokenId(to);
    }
    // ============ ListedId FUNCTIONS ============
    /*
        @dev ListedId fetch owner of Id, bool List Check and Price.
        @return Owner of Id, bool List Check and Price.
    */
    function ListedId(uint256 tokenId) public view returns(address seller,bool Listed,uint256 Price) {
        require(tokenId > 0 && tokenId <= tokenID.current(),"Token Id NOT Exist");
        if(!_idToNFT[tokenId].listed){
            return (_idToNFT[tokenId].seller,!_idToNFT[tokenId].listed,_idToNFT[tokenId].price);
        }else{
            return (_idToNFT[tokenId].seller,!_idToNFT[tokenId].listed,0);
        }     
    } 
}