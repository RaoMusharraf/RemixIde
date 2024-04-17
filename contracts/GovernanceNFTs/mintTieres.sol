// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KavNFT is ERC721URIStorage, Ownable {
    uint256 public constant STARLIGHT_SUPPLY = 200;
    uint256 public constant METEOR_SUPPLY = 220;
    uint256 public constant STELLAR_SUPPLY = 48;
    uint256 public constant GALAXY_SUPPLY = 20;

    address public companyWallet;
    // mapping(address => bool) public whitelist;
    mapping(uint => string) public _KAVtokenURI;
    // mapping(uint => string) public _tokenURIs;
    mapping(uint => string) public _tokenURIsStarLight;
    mapping(uint => string) public _tokenURIsMeteor;
    mapping(uint => string) public _tokenURIsStellar;
    mapping(uint => string) public _tokenURIsGalaxy;

    mapping(address => bool) public _whitelistStarLight;
    mapping(address => bool) public _whitelistMeteor;
    mapping(address => bool) public _whitelistStellar;
    mapping(address => bool) public _whitelistGalaxy;

    
    uint256 uriCount;
    uint256 starlightMinted;
    uint256 meteorMinted;
    uint256 stellarMinted;
    uint256 galaxyMinted;

    constructor(address _companyWallet) Ownable(_companyWallet) ERC721("KavNFT", "KAV") {
        companyWallet = _companyWallet;
    }
    function add_URI_in_KAV_Wallet(string[] memory _tokenURI) public onlyOwner{
        for (uint i=0; i<_tokenURI.length; i++) 
        {
            _KAVtokenURI[uriCount] = _tokenURI[i];
            uriCount++;
        }
    }

    function mintStarlight(address to,uint _uriCount) external onlyOwner {
        require(_whitelistStarLight[to], "Address not whitelisted");
        require(starlightMinted < STARLIGHT_SUPPLY, "All Starlight NFTs minted");
        _safeMint(to, starlightMinted);
        _setTokenURI(starlightMinted, _KAVtokenURI[_uriCount]);
        // _tokenURIs[starlightMinted] = _KAVtokenURI[_uriCount];
        _tokenURIsStarLight[starlightMinted] = _KAVtokenURI[_uriCount];
        starlightMinted++;
    }


    function mintMeteor(address to,uint _uriCount) external onlyOwner {
        require(_whitelistMeteor[to], "Address not whitelisted");
        // require(starlightMinted == STARLIGHT_SUPPLY, "STARLIGHT Tire is Completed");
        require(meteorMinted < METEOR_SUPPLY, "All Meteor NFTs minted");
        _safeMint(to, STARLIGHT_SUPPLY + meteorMinted);
        _setTokenURI((STARLIGHT_SUPPLY + meteorMinted), _KAVtokenURI[_uriCount]);
        // _tokenURIs[STARLIGHT_SUPPLY + meteorMinted] = _KAVtokenURI[_uriCount];
        _tokenURIsMeteor[meteorMinted] =  _KAVtokenURI[_uriCount];
        meteorMinted++;
    }

    function mintStellar(address to,uint _uriCount) external onlyOwner {
        require(_whitelistStellar[to], "Address not whitelisted");
        // require((starlightMinted == STARLIGHT_SUPPLY) && (meteorMinted == METEOR_SUPPLY), "STARLIGHT and METEOR Tire are Completed");
        require(stellarMinted < STELLAR_SUPPLY, "All Stellar NFTs minted");
        _safeMint(to, STARLIGHT_SUPPLY + METEOR_SUPPLY + stellarMinted);
        _setTokenURI((STARLIGHT_SUPPLY + METEOR_SUPPLY + stellarMinted), _KAVtokenURI[_uriCount]);
        // _tokenURIs[STARLIGHT_SUPPLY + METEOR_SUPPLY + stellarMinted] = _KAVtokenURI[_uriCount];
        _tokenURIsStellar[stellarMinted] = _KAVtokenURI[_uriCount];
        stellarMinted++;
    }

    function mintGalaxy(address to,uint _uriCount) external onlyOwner {
        require(_whitelistGalaxy[to], "Address not whitelisted");
        // require((starlightMinted == STARLIGHT_SUPPLY) && (meteorMinted == METEOR_SUPPLY) && (stellarMinted == STARLIGHT_SUPPLY), "STARLIGHT, METEOR, STARLIGHT Tire are Completed");
        require(galaxyMinted < GALAXY_SUPPLY, "All Galaxy NFTs minted");
        _safeMint(to, STARLIGHT_SUPPLY + METEOR_SUPPLY + STELLAR_SUPPLY + galaxyMinted);
        _setTokenURI((STARLIGHT_SUPPLY + METEOR_SUPPLY + STELLAR_SUPPLY + galaxyMinted), _KAVtokenURI[_uriCount]);
        // _tokenURIs[STARLIGHT_SUPPLY + METEOR_SUPPLY + STELLAR_SUPPLY + galaxyMinted] = _KAVtokenURI[_uriCount];
        _tokenURIsGalaxy[galaxyMinted] = _KAVtokenURI[_uriCount];
        galaxyMinted++;
    }

    function addToWhitelistStarLight(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistStarLight[addresses[i]] = true;
        }
    }
    function addToWhitelistMeteor(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistMeteor[addresses[i]] = true;
        }
    }
    function addToWhitelistStellar(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistStellar[addresses[i]] = true;
        }
    }
    function addToWhitelistGalaxy(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelistGalaxy[addresses[i]] = true;
        }
    }
    function allStarlightMinted() public view returns(string[] memory NFTS){
        string[] memory  allURI = new string[](starlightMinted);
        for (uint i=0; i< starlightMinted ; i++) 
        {
            allURI[i] = _tokenURIsStarLight[i];
        }
        return allURI;
    }
    function allmeteor() public view returns(string[] memory NFTS){
        string[] memory  allURI = new string[](meteorMinted);
        for (uint i=0; i< meteorMinted ; i++) 
        {
            allURI[i] = _tokenURIsMeteor[i];
        }
        return allURI;
    }
    function allStellar() public view returns(string[] memory NFTS){
        string[] memory  allURI = new string[](stellarMinted);
        for (uint i=0; i< stellarMinted ; i++) 
        {
            allURI[i] = _tokenURIsStellar[i];
        }
        return allURI;
    }
    function allGalaxy() public view returns(string[] memory NFTS){
        string[] memory  allURI = new string[](galaxyMinted);
        for (uint i=0; i< galaxyMinted ; i++) 
        {
            allURI[i] = _tokenURIsGalaxy[i];
        }
        return allURI;
    }
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