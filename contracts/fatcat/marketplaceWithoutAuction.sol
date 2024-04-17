// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts@4.9.0/utils/Counters.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.9.0/security/ReentrancyGuard.sol";

// Interface for connected contracts, defining required functions and structs for NFT metadata
interface IConnected {
    struct MyNft {
        uint256 tokenId;
        uint256 mintTime;
        address mintContract;
        address mintArtist;
        uint artistFeePerAge;
        string uri;
    }

    // Functions to be implemented by connected contracts for updating and retrieving NFT data
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    function update_TokenIdTime(uint _tokenId) external;
    function getTokenId(address _to) external view returns(MyNft[] memory);
    function getTokenUri(uint _tokenId) external view returns(string memory);

}
/// @title Marketplace  for the NFTS
/// @author FatCat Team
/// @notice Contarct is based on directly purchese or auction 
contract Marketplace is ReentrancyGuard , Ownable{
    //Counter
    using Counters for Counters.Counter;
    // State variables
    Counters.Counter public _nftCount;         // Counter for NFTs listed for direct sale
    Counters.Counter public nftAuctionCount;   // Counter for NFTs listed for auction
    address paymentToken;                      // ERC20 token used for payments
    address tokenAddress;                      // Address of the ERC721 token contract
    address public buyerFee;                   // Address to receive buyer fees
    address public sellerFee;                  // Address to receive seller fees
    uint public buyerFeePerAge;                // Fee percentage for buyers
    uint public sellerFeePerAge;               // Fee percentage for sellers;
   // Mappings
    mapping(address => mapping(uint256 => NFT)) public _idToNFT;                  // Maps contract addresses and token IDs to NFTs listed for direct sale
    mapping(uint => addressToken) public listCount;                               // Maps list indices to address and token ID pairs for direct sales
    mapping(address => mapping(uint => nftAuction)) public NftAuction;            // Maps contract addresses and token IDs to NFT auctions
    mapping(uint => uint) public userListCount;                                   // Helper mapping for user list counts
    mapping(uint => addressToken) public auctionListCount;                        // Maps auction indices to address and token ID pairs
    mapping(address => mapping(uint => mapping(uint => userDetail))) public Bidding; // Maps auction details to user bids
    mapping(uint => uint) public SelectedUser;                                    // Maps selected user for auction
    mapping(address => mapping(uint => mapping(address => mapping(uint => uint)))) public BiddingCount; // Helper mapping for bidding counts
    mapping(address => mapping(uint => mapping(address => uint))) public userBiddingCount; // Helper mapping for user bidding counts

    // Defines the structure for NFTs listed for sale in the marketplace.
    // This includes details like token ID, seller, current owner, price, and more.
    struct NFT {
        uint256 tokenId;        // Unique identifier for the NFT.
        address seller;         // Address of the seller listing the NFT.
        address owner;          // Current owner of the NFT.
        uint256 price;          // Sale price of the NFT.
        uint256 count;          // How many times this NFT has been listed/traded.
        uint listTime;          // Timestamp when the NFT was listed.
        bool listed;            // Flag to indicate if the NFT is currently listed.
        address artist;         // The original creator/artist of the NFT.
        uint artistFeePerAge;   // Artist's fee per age (possibly for royalty purposes).
    }

    // Defines the structure for auctions of NFTs in the marketplace.
    // Includes owner, token ID, minimum bid, artist, and other relevant details.
    struct nftAuction {
        address owner;          // Owner of the NFT being auctioned.
        uint tokenId;           // Unique identifier for the NFT.
        uint minimumBid;        // Minimum bid required to participate in the auction.
        address artist;         // The original creator/artist of the NFT.
        uint artistFeePerAge;   // Artist's fee per age, similar to the NFT struct.
        uint listTime;          // Timestamp when the NFT was listed for auction.
        bool isActive;          // Indicates if the auction is currently active.
    }

    // Stores details about a user's bid in an auction, including the bid amount and time.
    struct userDetail {
        address user;           // Address of the user making the bid.
        string userName;        // Optionally, a username or identifier for the bidder.
        uint price;             // The price of the bid.
        uint biddingTime;       // Timestamp when the bid was placed.
        uint bidCount;          // Number of bids placed by this user (for this auction?).
    }

    // A utility structure linking a contract address with a specific token ID.
    struct addressToken {
        address contractAddress; // The smart contract address of the NFT.
        uint tokenId;            // Unique identifier for the NFT.
    }

    // Contains information about a listed NFT in the auction, including its data and listing count.
    struct ListTokenId {
        nftAuction listedData;   // The auction data for the listed NFT.
        uint listCount;          // A count that could represent the number of times listed or an ID.
        string uriData;          // URI for the NFT metadata.
    }

    // Similar to `ListTokenId` but specifically for NFTs listed for direct sale.
    struct ListedNftTokenId {
        NFT listedData;          // The direct sale listing data for the NFT.
        uint listCount;          // A count or ID similar to `ListTokenId`.
        string uriData;          // URI for the NFT metadata.
    }
    struct MyNft {
    uint256 tokenId;       // Unique identifier for the NFT.
    uint256 mintTime;      // Timestamp when the NFT was minted.
    address mintContract;  // Address of the smart contract where the NFT was minted.
    address mintArtist;    // Address of the artist who created the NFT.
    uint artistFeePerAge;  // Artist's fee per age, indicating a royalty or fee structure over time.
    string uri;            // URI for the NFT's metadata, typically pointing to a JSON file with details like name, description, image, etc.
    }

    /*Event definitions below represent significant actions in the marketplace.*/

    // Emitted when an NFT is listed for sale.
    event NFTListed(uint256 tokenId, address seller, address owner, uint256 price);

    // Emitted when an NFT is sold.
    event NFTSold(uint256 tokenId, address seller, address owner, uint256 price, uint SoldTime);

    // Emitted when fees are paid to an artist.
    event Fee(address ArtistAddress, uint ArtistFee);

    // Emitted when a listed NFT sale is cancelled.
    event NFTCancel(uint256 tokenId, address seller, address owner, uint256 price);

    // Emitted when an NFT is claimed by the buyer.
    event Claim(uint256 tokenId, address buyer, uint ClaimTime);

    /* Constructor for initializing the Marketplace contract with fee details.
     `_buyer` and `_seller` are addresses to receive fees, and `_buyerFeePerAge` & `_sellerFeePerAge`
     are the fee percentages for buyer and seller, respectively.*/

    constructor(address _buyer, address _seller, uint _buyerFeePerAge, uint _sellerFeePerAge) {
        buyerFee = _buyer;                 // Address to collect fees from buyers.
        sellerFee = _seller;               // Address to collect fees from sellers.
        sellerFeePerAge = _sellerFeePerAge; // Fee percentage for sellers.
        buyerFeePerAge = _buyerFeePerAge;   // Fee percentage for buyers.
    }

    /**
    * @dev Lists an NFT on the marketplace for sale.
    * 
    * This function allows a user to list an NFT for sale in the marketplace. The function ensures that
    * the NFT is not already listed for sale or auction. It sets the sale price and records the listing
    * details in the marketplace's storage.
    * 
    * @param _mintContract The address of the NFT contract where the NFT was minted. This contract must
    *                      comply with the ERC721 standard.
    * @param _price The price at which the NFT is to be sold. This value must be non-negative.
    * @param _tokenId The unique identifier for the NFT being listed. This tokenId must have been minted
    *                 by the specified `_mintContract`.
    * @param artist The address of the artist or creator of the NFT. This is used for tracking and possibly
    *               distributing royalties or fees.
    * @param artistFeePerAge The fee or royalty amount that the artist is entitled to from the sale. The
    *                        specific usage of this parameter can vary, such as a percentage of the sale price.
    * 
    * Requirements:
    * - The NFT must not already be listed for sale in the marketplace.
    * - The NFT must not be active in any auction within this marketplace.
    * - The sale price `_price` must be at least 0 wei, allowing for free listings.
    * - The caller must own the NFT and approve the marketplace contract to transfer it.
    * 
    * On successful listing, the NFT is transferred from the seller to the marketplace contract, effectively
    * escrowing the NFT until the sale is complete or the listing is cancelled. The function emits an `NFTListed`
    * event detailing the tokenId, seller, marketplace address as the current owner, and the sale price.
    */
    function ListNft(address _mintContract,uint256 _price,uint256 _tokenId,address artist,uint artistFeePerAge) public nonReentrant {
        require(!_idToNFT[_mintContract][_tokenId].listed,"Already Listed In Marketplace!");
        require(_price >= 0, "Price Must Be At Least 0 Wei");
        _nftCount.increment();
        _idToNFT[_mintContract][_tokenId] = NFT(_tokenId,msg.sender,address(this),_price,_nftCount.current(),block.timestamp,true,artist,artistFeePerAge);
        listCount[_nftCount.current()] = addressToken(_mintContract,_tokenId);
        ERC721(_mintContract).transferFrom(msg.sender, address(this), _tokenId); 
        emit NFTListed(_tokenId, msg.sender, address(this), _price);
    }   
    /**
    * @dev Facilitates the purchase of an NFT listed on the marketplace.
    * 
    * This function allows a buyer to purchase an NFT that has been listed for sale on the marketplace.
    * It handles the transfer of ownership of the NFT, the distribution of funds including the sale price
    * to the seller, and any applicable fees to the marketplace and artist.
    * 
    * @param listIndex The index of the NFT in the marketplace's list of listed NFTs. This index is used
    *                  to retrieve the details of the NFT to be purchased.
    * @param price The price at which the buyer is willing to purchase the NFT. This is validated against
    *              the listing price of the NFT.
    * 
    * Requirements:
    * - The caller (buyer) must not be the seller of the NFT.
    * - The provided `price` must be at least equal to the asking price of the NFT.
    * - The caller must send enough ether to cover the asking price and any applicable fees.
    * 
    * The function performs the following operations:
    * 1. Transfers the NFT from the marketplace contract to the buyer.
    * 2. Updates the ownership and other relevant details of the NFT in the connected NFT contract.
    * 3. Calculates the fees to be distributed to the marketplace, artist, and any other parties.
    * 4. Distributes the sale proceeds and fees accordingly.
    * 5. Marks the NFT as no longer listed in the marketplace.
    * 6. Updates the marketplace's listing to reflect the sale and adjusts the list of available NFTs.
    * 
    * Emits a `Fee` event to log the distribution of fees to the artist and a `NFTSold` event to log the
    * sale of the NFT, including details such as the tokenId, seller, buyer, sale price, and timestamp.
    */
    function buyNft(uint listIndex,uint256 price) public payable nonReentrant { 
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller != msg.sender, "An offer cannot buy this Seller !!!");
        require(price == _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price , "Not enough ether to cover asking price !!!");
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        IConnected(listCount[listIndex].contractAddress).updateTokenId(msg.sender,listCount[listIndex].tokenId,_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller);
        uint buyerFeeCul =  (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * buyerFeePerAge) / 1000;
        uint sellerFeeCul = (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * sellerFeePerAge) / 1000;
        uint artistFeePerAge = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].artistFeePerAge;
        uint artistFee = (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price * artistFeePerAge) / 100;
        uint sellerAmount = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price - (artistFee + buyerFeeCul + sellerFeeCul);
        payable (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller).transfer(sellerAmount);
        payable (_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].artist).transfer(artistFee);
        payable (buyerFee).transfer(buyerFeeCul);
        payable (sellerFee).transfer(sellerFeeCul);
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        IConnected(listCount[listIndex].contractAddress).update_TokenIdTime(listCount[listIndex].tokenId);
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit Fee(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].artist,artistFee);
        emit NFTSold(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, msg.value,block.timestamp);
    }

    /**
    * @dev Allows a seller to cancel their listed NFT offer on the marketplace.
    *
    * This function is designed to cancel an active listing of an NFT on the marketplace, allowing the seller
    * to withdraw their offer. It handles the transfer of the NFT back to the seller and updates the listing
    * status accordingly.
    * 
    * @param listIndex The index of the listed NFT in the marketplace's tracking data structure. This index
    *                  is used to identify the specific NFT listing to be canceled.
    *
    * Requirements:
    * - The NFT identified by `listIndex` must currently be listed on the marketplace. The function checks
    *   for the `listed` status to ensure that only active listings can be canceled.
    * - The caller of this function should be the owner or have appropriate permissions to cancel the listing.
    * 
    * The function performs the following operations:
    * 1. Validates that the NFT is currently listed.
    * 2. Updates the owner of the NFT to be the original seller, effectively preparing for the transfer back.
    * 3. Transfers the NFT from the marketplace contract back to the original seller (now the owner).
    * 4. Marks the NFT as no longer listed by setting its `listed` status to false.
    * 5. Adjusts the marketplace's internal tracking of listed NFTs to reflect the removal of the listing.
    * 6. Decrements the counter tracking the total number of listed NFTs.
    * 
    * Emits an `NFTCancel` event to log the cancellation of the listing, including details such as the tokenId,
    * seller, the address who performed the cancellation, and the price at which the NFT was listed.
    */
     
    function CancelOffer(uint listIndex) public nonReentrant {
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed,"Please List First !!!");
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller == msg.sender,"You are not owner of this NFT");
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].owner = _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller;
        ERC721(listCount[listIndex].contractAddress).transferFrom(address(this), msg.sender, listCount[listIndex].tokenId);
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed=false;
        _idToNFT[listCount[_nftCount.current()].contractAddress][listCount[_nftCount.current()].tokenId].count = listIndex;
        listCount[listIndex] = listCount[_nftCount.current()];
        _nftCount.decrement();
        emit NFTCancel(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].tokenId, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller, msg.sender, _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price);
    }
    function editOffer(uint listIndex,uint price) public nonReentrant {
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].listed,"Please List First !!!");
        require(_idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].seller == msg.sender,"You are not owner of this NFT");
        _idToNFT[listCount[listIndex].contractAddress][listCount[listIndex].tokenId].price=price;
    }
    /**
    * @dev Retrieves details of NFTs owned by a specific address across multiple contracts.
    *
    * @param _to The owner address whose NFTs are being queried.
    * @param contractAddresses An array of contract addresses to query for NFT ownership.
    * @return MyNft[][] A two-dimensional array where each element represents an array of `MyNft` structs
    *         containing details of NFTs owned by `_to` in the corresponding contract.
    *
    * Operation:
    * 1. Initializes a two-dimensional array to hold NFT details from each contract.
    * 2. Iterates over each contract address, querying for NFTs owned by `_to`.
    * 3. Constructs an array of `MyNft` structs for each contract and fills it with the NFT details.
    * 4. Returns a two-dimensional array containing NFT details for each contract.
    */

    function getNFTDetail(address _to, address[] memory contractAddresses) external view returns (MyNft[][] memory) {
        MyNft[][] memory myNFT = new MyNft[][](contractAddresses.length);
        for (uint i = 0; i < contractAddresses.length; i++) {
            IConnected.MyNft[] memory connectedNft = IConnected(contractAddresses[i]).getTokenId(_to);
            myNFT[i] = new MyNft[](connectedNft.length);
            for(uint j = 0 ; j < connectedNft.length ; j++){
                myNFT[i][j] = MyNft(connectedNft[j].tokenId,connectedNft[j].mintTime,connectedNft[j].mintContract,connectedNft[j].mintArtist,connectedNft[j].artistFeePerAge,connectedNft[j].uri);
            }
        }
        return (myNFT);
    }

    /**
    * @dev Retrieves all NFTs currently listed in the marketplace, both for direct sale and auction.
    *
    * @return ListedNftTokenId[] An array of `ListedNftTokenId` structs containing details of NFTs listed for direct sale.
    * @return ListTokenId[] An array of `ListTokenId` structs containing details of NFTs listed for auction.
    *
    * Operation:
    * 1. Initializes two arrays to hold details of NFTs listed for sale and auction, respectively.
    * 2. Iterates over each listing and auction, adding their details to the respective arrays.
    * 3. Returns the two arrays, one for direct sale listings and the other for auctions.
    */
    function getAllListedNfts() public view returns (ListedNftTokenId[] memory,ListTokenId[] memory) {
        uint listNft = (_nftCount.current());
        ListedNftTokenId[] memory listedNFT = new ListedNftTokenId[](listNft);
        uint listedIndex = 0;
        for (uint i = 1; i <= _nftCount.current() ; i++) {
            if (_idToNFT[listCount[i].contractAddress][listCount[i].tokenId].listed) {
                listedNFT[listedIndex] = ListedNftTokenId(_idToNFT[listCount[i].contractAddress][listCount[i].tokenId],i,IConnected(listCount[i].contractAddress).getTokenUri(listCount[i].tokenId));
                listedIndex++;
            }
        }
        listNft = (nftAuctionCount.current());
        ListTokenId[] memory auctionListNFT = new ListTokenId[](listNft);
        uint listedIndexCount = 0;
        for (uint i = 1; i <= nftAuctionCount.current() ; i++) {
            if (NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId].isActive) {
                auctionListNFT[listedIndexCount] = ListTokenId(NftAuction[auctionListCount[i].contractAddress][auctionListCount[i].tokenId],i,IConnected(auctionListCount[i].contractAddress).getTokenUri(auctionListCount[i].tokenId));
                listedIndexCount++;
            }
        }
        return (listedNFT,auctionListNFT);
    }
    /**
    * @dev Sets the address to receive buyer fees from NFT sales.
    * Can only be called by the contract owner.
    *
    * @param _address The address to which buyer fees will be sent.
    */
    function setBuyerFeeAddress(address _address) public onlyOwner{
        buyerFee = _address;
    }

    /**
    * @dev Sets the address to receive seller fees from NFT sales.
    * Can only be called by the contract owner.
    *
    * @param _address The address to which seller fees will be sent.
    */
    function setSellerFeeAddress(address _address) public onlyOwner{
        sellerFee = _address;
    }

    /**
    * @dev Sets the percentage fee charged to buyers in NFT sales.
    * Can only be called by the contract owner.
    *
    * @param _setBuyerFee The fee percentage to be charged to buyers.
    */
    function setBuyerFee(uint _setBuyerFee) public onlyOwner{
        buyerFeePerAge = _setBuyerFee;
    }
    /**
    * @dev Sets the percentage fee charged to sellers in NFT sales.
    * Can only be called by the contract owner.
    *
    * @param _setSellerFee The fee percentage to be charged to sellers.
    */
    function setSellerFee(uint _setSellerFee) public onlyOwner{
        sellerFeePerAge = _setSellerFee;
    }
}