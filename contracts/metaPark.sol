// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/*
    @Title MetaPark Minting Contract
*/
contract MetaPark is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    Counters.Counter public PKGCounter; 
    address public mintAuthority;
    bool public transferNftsToWalletCheck;

    //Struct of packages
    struct Package {
        uint256 quantity;
        uint256 r_quantity; //remaining quantites
        uint256 pricePerNft;
        string json_url;
    }
    //Struct of package's buyer list
    struct PackageBuyersList {
        uint256 nft_quantity;
        string nft_url;
        uint256 pricePerNft;
        bool check;
    }
    mapping (address => mapping(uint => uint)) public Detail;
    mapping (address => mapping(uint => uint)) public TokenURIid;
    mapping (address => uint) public CountBuyerIds;
    mapping (address => uint) public NFTIds;
    mapping (uint => Package) public ViewPackage;
    
    mapping (address => mapping(uint => PackageBuyersList)) public BuyPackage;

    constructor(address mintAuthority_address) ERC721("MyToken", "MTK") {
        mintAuthority = mintAuthority_address;
    }
    // ============  EnterPackage FUNCTIONS ============
    /* 
        @param totalQuantity is the Total Amount Ammin wants to Sale.
        @param price is the Amount per quantity.
        @dev EnterPackage in this function admin add package for Sale.
    */
    function EnterPackage(uint256 totalQuantity,uint256 price,string memory uri) public onlyOwner {
        PKGCounter.increment();
        ViewPackage[PKGCounter.current()] = Package(totalQuantity,totalQuantity,price,uri);
    }
    // ============  BuyFromPackage FUNCTIONS ============
    /* 
        @param to is the address that wants to buy quantities of NFTs.
        @param id is the Admin Token Ids that admin wants to Sale.
        @dev buyFromPackage take all the argument related to the User and Allow user to get quantities of NFTs.
        @returns Token Ids that are minted by the address 
    */
    function buyFromPackage(address to,uint id,uint quantity,uint price) public payable{
        require(ViewPackage[id].pricePerNft*quantity == price,"Insuficient Balance");
        require(ViewPackage[id].r_quantity >= quantity,"Select Right Quantity");
        if(!BuyPackage[to][id].check){
            Detail[to][CountBuyerIds[to]] = id; 
            BuyPackage[to][id] = PackageBuyersList(quantity,ViewPackage[id].json_url,ViewPackage[id].pricePerNft,true);
            ViewPackage[id].r_quantity = ViewPackage[id].r_quantity - quantity;
            CountBuyerIds[to] += 1;
        }else{
            BuyPackage[to][id] = PackageBuyersList(BuyPackage[to][id].nft_quantity+quantity,ViewPackage[id].json_url,ViewPackage[id].pricePerNft,true);
        }   
        payable(mintAuthority).transfer(price);  
    }
    // ============  Check FUNCTIONS ============
    /* 
        @dev istransferNftsToWalletCheckSet in this function admin open the minting function for Users.
    */
    function istransferNftsToWalletCheckSet() public onlyOwner {
        transferNftsToWalletCheck = !transferNftsToWalletCheck;
    }
    // ============ MINTING FUNCTIONS ============
    /* 
        @dev safeMintNFTs mint
    */
    function safeMint(address to,uint id) public {
        require(BuyPackage[to][id].nft_quantity > 0 ,"Please First Buy Quantity.");
        for(uint i = 0; i < BuyPackage[to][id].nft_quantity ;i++){
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
            _setTokenURI(_tokenIdCounter.current(), ViewPackage[id].json_url);
            TokenURIid[to][NFTIds[to]] = _tokenIdCounter.current();
            NFTIds[to] += 1; 
        } 
        BuyPackage[to][id].nft_quantity = 0;  
    }
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}