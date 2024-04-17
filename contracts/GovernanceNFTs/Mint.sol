// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title KavNFT
 * @dev This contract implements an ERC721 compliant NFT (Non-Fungible Token) contract with multiple tiers: STARLIGHT, METEOR, STELLAR, and GALAXY.
 * Users can mint NFTs based on these tiers, and the contract owner can manage whitelists and metadata URIs.
 */
contract KNFT is ERC721URIStorage, Ownable {

    // Constants defining the total supply for each tier of NFTs
    uint256 public constant STARLIGHT_SUPPLY = 200;   // Total supply of STARLIGHT tier NFTs
    uint256 public constant METEOR_SUPPLY = 220;     // Total supply of METEOR tier NFTs
    uint256 public constant STELLAR_SUPPLY = 48;    // Total supply of STELLAR tier NFTs
    uint256 public constant GALAXY_SUPPLY = 20;     // Total supply of GALAXY tier NFTs
    address public companyWallet;                       // Address of the company wallet


    mapping(uint => string) public _KAVtokenURI;        // Mapping to store KAV token URIs
    mapping(uint => string) private  _tokenURIsStarLight; // Mapping to store STARLIGHT token URIs
    mapping(uint => string) private  _tokenURIsMeteor;    // Mapping to store METEOR token URIs
    mapping(uint => string) private  _tokenURIsStellar;   // Mapping to store STELLAR token URIs
    mapping(uint => string) private  _tokenURIsGalaxy;    // Mapping to store GALAXY token URIs
    mapping(address => bool) private _whitelistStarLight;  // Mapping to store whitelist addresses for StartLight
    mapping(address => bool) private _whitelistMeteor;     // Mapping to store whitelist addresses for Meteor
    mapping(address => bool) private _whitelistStellar;    // Mapping to store whitelist addresses for Stellar
    mapping(address => bool) private _whitelistGalaxy;     // Mapping to store whitelist addresses for Galaxy


    uint256 uriCount;           // Counter for the number of URIs
    uint256 tokenCount;           // Counter for the number of URIs
    uint256 starlightMinted;    // Counter for the number of STARLIGHT NFTs minted
    uint256 meteorMinted;       // Counter for the number of METEOR NFTs minted
    uint256 stellarMinted;      // Counter for the number of STELLAR NFTs minted
    uint256 galaxyMinted;       // Counter for the number of GALAXY NFTs minted
    /**
     * @dev Constructor to initialize the contract with the company wallet.
     * @param _companyWallet The address of the company wallet.
     */
    constructor(address _companyWallet) Ownable(_companyWallet) ERC721("Kav's Galactic NFTs", "KAV") {
        companyWallet = _companyWallet;
    }
    /**
     * @dev Function to add token URIs into KAV Wallet.
     * @param _tokenURI Array of token URIs to be added.
     */
    function add_URI_in_KAV_Wallet(string[] memory _tokenURI) public onlyOwner {
        for (uint i=0; i<_tokenURI.length; i++) {
            _KAVtokenURI[uriCount] = _tokenURI[i];
            uriCount++;
        }
    }
    /**
     * @dev Function to mint STARLIGHT tier NFTs.
     * @param to The address to mint the NFT to.
     * @param _uriCount The index of the URI in the KAV token URI array.
     */
    function mintStarlight(address to,uint _uriCount) external onlyOwner {
        require(_uriCount == 0,"Use URI 0 for Starlight");
        require(_whitelistStarLight[to], "Address not whitelisted");
        require(starlightMinted < STARLIGHT_SUPPLY, "All Starlight NFTs minted");
        _safeMint(to, tokenCount);
        _setTokenURI(tokenCount, _KAVtokenURI[_uriCount]);
        _tokenURIsStarLight[starlightMinted] = _KAVtokenURI[_uriCount];
        tokenCount++;
        starlightMinted++;
    }
    /**
     * @dev Function to mint METEOR tier NFTs.
     * @param to The address to mint the NFT to.
     * @param _uriCount The index of the URI in the KAV token URI array.
     */
    function mintMeteor(address to,uint _uriCount) external onlyOwner {
        require(_uriCount == 1,"Use URI 1 for Meteor");
        require(_whitelistMeteor[to], "Address not whitelisted");
        require(meteorMinted < METEOR_SUPPLY, "All Meteor NFTs minted");
        _safeMint(to, tokenCount);
        _setTokenURI(tokenCount, _KAVtokenURI[_uriCount]);
        _tokenURIsMeteor[meteorMinted] =  _KAVtokenURI[_uriCount];
        tokenCount++;
        meteorMinted++;
    }
    /**
     * @dev Function to mint STELLAR tier NFTs.
     * @param to The address to mint the NFT to.
     * @param _uriCount The index of the URI in the KAV token URI array.
     */
    function mintStellar(address to,uint _uriCount) external onlyOwner{
        require(_uriCount == 2,"Use URI 2 for Stellar");
        require(_whitelistStellar[to], "Address not whitelisted");
        require(stellarMinted < STELLAR_SUPPLY, "All Stellar NFTs minted");
        _safeMint(to,tokenCount);
        _setTokenURI(tokenCount, _KAVtokenURI[_uriCount]);
        _tokenURIsStellar[stellarMinted] = _KAVtokenURI[_uriCount];
        tokenCount++;
        stellarMinted++;
    }
    /**
     * @dev Function to mint GALAXY tier NFTs.
     * @param to The address to mint the NFT to.
     * @param _uriCount The index of the URI in the KAV token URI array.
     */
    function mintGalaxy(address to,uint _uriCount) external onlyOwner {
        require(_uriCount == 3,"Use URI 3 for Galaxy");
        require(_whitelistGalaxy[to], "Address not whitelisted");
        require(galaxyMinted < GALAXY_SUPPLY, "All Galaxy NFTs minted");
        _safeMint(to, tokenCount);
        _setTokenURI(tokenCount, _KAVtokenURI[_uriCount]);
        _tokenURIsGalaxy[galaxyMinted] = _KAVtokenURI[_uriCount];
        tokenCount++;
        galaxyMinted++;
    }
    /**
     * @dev Function to add addresses to the addToWhitelistStarLight.
     * @param addresses Array of addresses to be added to the whitelist.
     */
    function addToWhitelistStarLight(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistStarLight[addresses[i]] = true;
        }
    }
    /**
     * @dev Function to add addresses to the addToWhitelistMeteor.
     * @param addresses Array of addresses to be added to the whitelist.
     */
    function addToWhitelistMeteor(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistMeteor[addresses[i]] = true;
        }
    }
    /**
     * @dev Function to add addresses to the addToWhitelistStellar.
     * @param addresses Array of addresses to be added to the whitelist.
     */
    function addToWhitelistStellar(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistStellar[addresses[i]] = true;
        }
    }
    /**
     * @dev Function to add addresses to the addToWhitelistGalaxy.
     * @param addresses Array of addresses to be added to the whitelist.
     */
    function addToWhitelistGalaxy(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistGalaxy[addresses[i]] = true;
        }
    }
    /* @dev Function to get all Starlight NFTs.
     * @return An array of token URIs representing all Starlight NFTs minted.
     */
    function allStarlightMinted() public view returns(string[] memory NFTS) {
        string[] memory  allURI = new string[](starlightMinted);
        for (uint i=0; i< starlightMinted ; i++) {
            allURI[i] = _tokenURIsStarLight[i];
        }
        return allURI;
    }
    /* @dev Function to get all Meteor NFTs.
     * @return An array of token URIs representing all Meteor NFTs minted.
     */
    function allMeteorMinted() public view returns(string[] memory NFTS) {
        string[] memory  allURI = new string[](meteorMinted);
        for (uint i=0; i< meteorMinted ; i++) {
            allURI[i] = _tokenURIsMeteor[i];
        }
        return allURI;
    }
    /*@dev Function to get all Stellar NFTs.
     * @return An array of token URIs representing all Stellar NFTs minted.
     */
    function allStellarMinted() public view returns(string[] memory NFTS) {
        string[] memory  allURI = new string[](stellarMinted);
        for (uint i=0; i< stellarMinted ; i++) {
            allURI[i] = _tokenURIsStellar[i];
        }
        return allURI;
    }
    /* @dev Function to get all Galaxy NFTs.
     * @return An array of token URIs representing all Galaxy NFTs minted.
     */
    function allGalaxyMinted() public view returns(string[] memory NFTS) {
        string[] memory  allURI = new string[](galaxyMinted);
        for (uint i=0; i< galaxyMinted ; i++) {
            allURI[i] = _tokenURIsGalaxy[i];
        }
        return allURI;
    }
    /* @dev Function to get all NFTs.
     * @return An array of token URIs representing all NFTs minted.
     */
    function allNFT() public view returns(string[] memory NFTS){
        uint total =  starlightMinted + meteorMinted + stellarMinted + galaxyMinted;
        string[] memory  allURI = new string[](total);
        for (uint i=0; i< total ; i++) 
        {
            allURI[i] = super.tokenURI(i);
        }
        return allURI;
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}