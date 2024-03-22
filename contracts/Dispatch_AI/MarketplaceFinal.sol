// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IConnected {
    // struct Token {
    //     uint tokenId;
    //     string uri;
    //     uint capAmount;
    //     uint points;
    // }
    function updateTokenId(address _to,uint _tokenId,address seller,address marketPlace) external;
    // function getToken(address _to,uint _tokenId) external view returns(Token[] memory token);
}
/**
 * @title MarketPlace
*/
contract Marketplace is ReentrancyGuard , Ownable{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter public _nftCount;
    Counters.Counter public nftAuctionCount;
    //Address
    address tokenAddress;
    //Mapping
    mapping (address mintContractAddress=> mapping( uint256 tokenId => NFT)) public _idToNFT;
    mapping (uint => addressToken) public listCount;
    mapping (uint => uint ) public userListCount;
    //Struct
    struct NFT {
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        uint256 count;
        uint listTime;
        bool listed;
    }
    struct addressToken{
        address contractAddress;
        uint tokenId;
    }
    struct ListedNftTokenId{
        NFT listedData;
        uint listCount;
    }
    // Modifire
    modifier listedRequirements(address mintStoneAddress,address userAddress,uint tokenId,uint _price) {
        // IConnected.Token[] memory connectedNft = IConnected(mintStoneAddress).getToken(userAddress,tokenId);
        // require(connectedNft[0].capAmount == connectedNft[0].points,"First Fill Stone Cap!");
        require(!_idToNFT[mintStoneAddress][tokenId].listed,"Already Listed In Marketplace!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        _;
    }
    //Event
    event NFTListed(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTSold(uint256 tokenId,address seller,address owner,uint256 price);
    event NFTCancel(uint256 tokenId,address seller,address owner,uint256 price);
    //Constructor
    constructor(address initialOwner,address _tokenAddress)Ownable(initialOwner) {
        tokenAddress = _tokenAddress;
    }
    // ============ ListNft FUNCTIONS ============
    /*
        @dev listNft list NFTs in hestory with tokenid.
        @param _tokenId that are minted by the nftContract
        @param _price set price of NFT
    */
    function ListNft(address _mintContract,address userAddress,uint256 _price,uint256 _tokenId) public listedRequirements(_mintContract,userAddress,_tokenId,_price) nonReentrant{
        _nftCount.increment();
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,userAddress,address(this),_price,_nftCount.current(),block.timestamp,true);
        listCount[_nftCount.current()] = addressToken(_mintContract,_tokenId);
        ERC721(_mintContract).transferFrom(userAddress, address(this), _tokenId); 
        emit NFTListed(_tokenId, userAddress, address(this), _price);
    }
    // ============ BuyNFTs FUNCTIONS ============
    /*
        @dev BuyNft convert the ownership seller to the buyer
        @param _tokenId that are minted by the nftContract
    */
    function buyNft(uint listIndex,uint256 price) public nonReentrant {

        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price == _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        IConnected(listCount[listIndex].contractAddress).updateTokenId(msg.sender,listCount[listIndex].tokenId,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller,address(this));
        uint256 amount = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price;
        // if(typ == 1){ price
        //     payable(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller).transfer(amount);
        // }  
        // else if(typ == 2){  
        //     IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller,amount);
        // }
        // else{
        //     revert("Please Enter the correct payment Type");
        // }
        IERC20(tokenAddress).safeTransferFrom(msg.sender,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller,amount);
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTSold(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, price);
    }
    // ============ CancelOffer FUNCTIONS ============
    /*
        @dev CancelOffer cancel offer that is listed
        @param _tokenid identity of token
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
    // ============ GetListedNFTs FUNCTIONS ============
    /*
        @dev getListedNfts fetch all the NFTs that are listed
        @return array of NFTs that are listed
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
    function nftDetail(address mintContractAddress,uint tokenId) public view returns(bool onList){
        return _idToNFT[mintContractAddress][tokenId].listed;
    }

}