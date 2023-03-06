// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/*
    @Title MetaPark Minting Contract
*/
contract MetaPark is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    Counters.Counter public PKGCounter; 

    using SafeERC20 for IERC20;
    address public mintAuthority;
    address public USDTToken;
    bool public transferNftsToWalletCheck;

    //Struct of packages
    struct Package {
        string PkgName;
        uint256 quantity;
        uint256 r_quantity; //remaining quantites
        uint256 pricePerNft;
        string folderURL;
        string thumbnail;
    }
    //Struct of package's buyer list
    struct PackageBuyersList {
        string nft_url;
        uint256 pricePerNft;
        uint256 timestamp;
        bool check;
    }
    mapping (address => mapping(uint => uint)) public Detail;
    mapping (address => mapping(uint => uint)) public TokenURIid;
    mapping (address => uint) public CountBuyerIds;
    mapping (address => uint) public NFTIds;
    mapping (uint => Package) public ViewPackage;    
    mapping (address => mapping(uint => PackageBuyersList)) public BuyPackage;

    constructor(address mintAuthority_address,address USDT) ERC721("MyToken", "MTK") {
        mintAuthority = mintAuthority_address;
        USDTToken = USDT;
    }
    // ============  EnterPackage FUNCTIONS ============
    /* 
        @param totalQuantity is the Total Amount Admin wants to Sale.
        @param price is the Amount per quantity.
        @dev EnterPackage in this function admin add package for Sale.
    */
    function EnterPackage(string memory name,uint256 totalQuantity,uint256 price,string memory folderURL,string memory thumbnail) public  {
        PKGCounter.increment();
        ViewPackage[PKGCounter.current()] = Package(name,totalQuantity,totalQuantity,price,folderURL,thumbnail);
    }
    // ============  DeletePackage FUNCTIONS ============
    /* 
        @param id is the Package Id that you want to delete.
        @dev DeletePackage in this function admin delete package from Sale.
    */
    function DeletePackage(uint id) public{
        require(ViewPackage[id].r_quantity == ViewPackage[id].quantity,"SORRY, User Buy Some Quantity!");
        delete ViewPackage[id];
    }
    // ============  BuyFromPackage FUNCTIONS ============
    /* 
        @param to is the address that wants to buy quantities of NFTs.
        @param id is the Admin Token Ids that admin wants to Sale.
        @dev buyFromPackage take all the argument related to the User and Allow user to get quantities of NFTs.
        @returns Token Ids that are minted by the address 
    */
    function buyFromPackage(address to,uint id,uint quantity,uint price,string memory URL) public payable{
        require(quantity == 1,"Quantity Must Be 1");
        require(ViewPackage[id].pricePerNft == price,"Insuficient Balance");
        require(ViewPackage[id].r_quantity >= quantity,"Select Right Quantity");
        Detail[to][CountBuyerIds[to]] = id; 
        ViewPackage[id].r_quantity = ViewPackage[id].r_quantity - quantity;
        BuyPackage[to][CountBuyerIds[to]] = PackageBuyersList(URL,price,block.timestamp,false);
        CountBuyerIds[to] += 1;  
        IERC20(USDTToken).safeTransferFrom(
            to,
            mintAuthority,
            price*1000000000000000000
        );
    }
    /* 
        @param _to is the address that give the Token Ids that are minted by this address
        @dev Check_TokenID get all the Ids that are mint by this address 
        @returns Token Ids that are minted by the address 
    */
    function getAllPkg(address _to) public view returns (PackageBuyersList[] memory)  {
        PackageBuyersList[] memory memoryArray = new PackageBuyersList[](CountBuyerIds[_to]);
        uint counter=0;
        for(uint i = 0; i < CountBuyerIds[_to]; i++) {
            memoryArray[counter] = BuyPackage[_to][i]; 
            counter +=1;  
        }
        return memoryArray;
    } 
    // ============  Check FUNCTIONS ============
    /* 
        @dev istransferNftsToWalletCheckSet in this function admin open the minting function for Users.
    */
    function istransferNftsToWalletCheckSet() public   {
        transferNftsToWalletCheck = !transferNftsToWalletCheck;
    }
    // ============ MINTING FUNCTIONS ============
    /* 
        @dev safeMintNFTs mint
    */
    function safeMint(address to,uint id) public {
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), BuyPackage[to][id].nft_url);
        TokenURIid[to][NFTIds[to]] = _tokenIdCounter.current();  
        BuyPackage[to][id].check = true;
        NFTIds[to] += 1;
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