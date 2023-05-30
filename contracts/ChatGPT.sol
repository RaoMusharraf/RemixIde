// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OctaERC721Token is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address private _admin;
    bool private _level1Open;
    bool private _level2Open;

    uint256 private constant MAX_NFTS = 12000;
    uint256 private constant MAX_NFTS_PER_TRANSACTION = 5;
    uint256 private constant LEVEL1_MAX_NFTS = 600;
    uint256 private constant LEVEL2_MAX_NFTS = 1200;
    uint256 private constant MINTING_FEE = 100 wei;

    constructor() ERC721("OctaERC721Token", "OCTA") {
        _admin = msg.sender;
        _level1Open = true;
        _level2Open = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can call this function");
        _;
    }

    modifier level1Open() {
        require(_level1Open, "Level 1 is not open");
        _;
    }

    modifier level2Open() {
        require(_level2Open, "Level 2 is not open");
        _;
    }

    function mintNFT(uint256 numNFTs) external payable level1Open {
        require(numNFTs <= MAX_NFTS_PER_TRANSACTION, "Exceeded maximum NFTs per transaction");
        // require(totalSupply() + numNFTs <= MAX_NFTS, "Exceeded maximum NFTs limit");
        require(msg.value == numNFTs * MINTING_FEE, "Incorrect amount sent");

        for (uint256 i = 0; i < numNFTs; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        if (_tokenIdCounter.current() == LEVEL1_MAX_NFTS) {
            _level1Open = false;
            _level2Open = true;
        }

        payable(_admin).transfer(numNFTs * MINTING_FEE);
    }

    function closeLevels() external onlyAdmin {
        _level1Open = false;
        _level2Open = false;
    }

    function openLevel2() external onlyAdmin {
        require(_tokenIdCounter.current() >= LEVEL1_MAX_NFTS, "Cannot open Level 2 yet");

        _level2Open = true;
    }

    function getMintedNFTs() external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_tokenIdCounter.current());

        for (uint256 i = 0; i < _tokenIdCounter.current(); i++) {
            tokenIds[i] = i;
        }

        return tokenIds;
    }
}
