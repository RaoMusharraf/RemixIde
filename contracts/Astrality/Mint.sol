// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

/// @title Astrality
/// @author Astrality Team
/// @notice Contarct has fixed supply of tokens which is preminted
contract Astrality is ERC721, ERC721Pausable, Ownable, ERC721Burnable {
    constructor(address initialOwner)
        ERC721("Astrality", "Astrality")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    // ============ Mint FUNCTIONS ============
    /*
        @dev safeMint mint NFTs from User using id.
        @param to is the address of the active User and tokenId that are created by User when User enter data.
    */
    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}