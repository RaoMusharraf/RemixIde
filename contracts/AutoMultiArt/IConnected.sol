// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IConnected {
    struct MyNft {
        uint256 tokenId;
        uint256 mintTime;
        address mintContract;
        string uri;
    }
    /**
     * @dev update Token Id in the minted contract.
     */
    function updateTokenId(address _to,uint _tokenId,address seller) external;
    function update_TokenIdTime(uint _tokenId) external;
    function getTokenId(address _to) external view returns(MyNft[] memory);
    function getTokenUri(uint _tokenId) external view returns(string memory);
}