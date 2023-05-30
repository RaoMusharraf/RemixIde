// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFTContract is ERC721, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 private constant MAX_NFT_SUPPLY = 12000;
    uint256 private constant MAX_NFT_SUPPLY_PER_LEVEL = 600;
    uint256 private constant MINT_PRICE = 100 wei;
    enum Level { None, One, Two }

    mapping(address => uint256[]) private _mintedNFTs;
    uint256 private _totalNFTSupply;
    Level private _currentLevel;
    bool private _levelTwoOpen;

    constructor() ERC721("MyNFT", "MNFT") {
        _totalNFTSupply = 0;
        _currentLevel = Level.One;
        _levelTwoOpen = false;
    }

    // Mint NFTs
    function mintNFTs(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= 5, "Cannot mint more than 5 NFTs at once");
        require(_totalNFTSupply + amount <= MAX_NFT_SUPPLY, "Exceeds total NFT supply");
        require(msg.value == amount * MINT_PRICE, "Insufficient funds");

        if (_currentLevel == Level.One) {
            require(_totalNFTSupply + amount <= MAX_NFT_SUPPLY_PER_LEVEL, "Exceeds Level 1 limit");
        } else if (_currentLevel == Level.Two) {
            require(_totalNFTSupply + amount <= MAX_NFT_SUPPLY, "Exceeds Level 2 limit");
        } else {
            revert("Both levels are closed");
        }

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _mintedNFTs[msg.sender].push(_tokenIdCounter.current());
            _tokenIdCounter.increment();
            _totalNFTSupply++;
        }

        payable(owner()).transfer(amount * MINT_PRICE);
    }

    // View minted NFTs by the caller
    function viewMintedNFTs() external view returns (uint256[] memory) {
        return _mintedNFTs[msg.sender];
    }

    // Open Level 2 (Only callable by the contract owner)
    function openLevel2() external onlyOwner {
        require(_totalNFTSupply >= MAX_NFT_SUPPLY_PER_LEVEL, "Cannot open Level 2 yet");
        _levelTwoOpen = true;
    }

    // Close Level 1 (Only callable by the contract owner)
    function closeLevel1() external onlyOwner {
        require(_totalNFTSupply >= MAX_NFT_SUPPLY_PER_LEVEL, "Cannot close Level 1 yet");
        _currentLevel = Level.Two;
    }

    // Close Level 2 (Only callable by the contract owner)
    function closeLevel2() external onlyOwner {
        require(_totalNFTSupply >= MAX_NFT_SUPPLY, "Cannot close Level 2 yet");
        _currentLevel = Level.None;
        _levelTwoOpen = false;
    }
        // Open Level 1 (Only callable by the contract owner)
    function openLevel1() external onlyOwner {
        require(_currentLevel == Level.None, "Level 1 is already open or Level 2 is open");

        _currentLevel = Level.One;
    }
}