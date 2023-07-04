// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Multiart is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public _tokenIdCounter;
    struct TokenIdByCollection {
        uint256[] tokenIds;
    }
    mapping(address => mapping(uint256 => uint256)) public TokenId;
    mapping(address => uint256) public count;
    mapping(string => TokenIdByCollection) private tokenIdByCollection;
    address mintPriceReceiver;
    address transferFeeReceiver;

    constructor(address _mintPriceReceiver, address _transferFeeReceiver)
        ERC721("Multiart", "MAT")
    {
        mintPriceReceiver = _mintPriceReceiver;
        transferFeeReceiver = _transferFeeReceiver;
    }

    function safeMint(
        address to, 
        uint256 feePercentage,
        string memory uri,
        string memory collectionId
    ) external payable returns (uint256) {
        require(msg.value > 0, "Invalid Price");
        uint256 calculatedFeePrice = calculateReceiverPrice(
            feePercentage,
            msg.value
        );
        uint256 mintedPrice = msg.value - calculatedFeePrice;
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        TokenId[to][count[to] + 1] = tokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        count[to]++;
        payable(mintPriceReceiver).transfer(mintedPrice);
        payable(transferFeeReceiver).transfer(calculatedFeePrice);
        tokenIdByCollection[collectionId].tokenIds.push(tokenId);
        return tokenId;
    }

    function calculateReceiverPrice(uint256 _feePercentage, uint256 _TotalPrice)
        public
        pure
        returns (uint256)
    {
        return ((_TotalPrice * _feePercentage) / 1000);
    }

    function getTokenId(address to) public view returns (uint256[] memory) {
        uint256[] memory myArray = new uint256[](count[to]);
        for (uint256 i = 0; i < count[to]; i++) {
            myArray[i] = TokenId[to][i + 1];
        }
        return myArray;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getTokenIdsByCollection(string memory collectionId)
        public
        view
        returns (uint256[] memory)
    {
        return tokenIdByCollection[collectionId].tokenIds;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}