// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IConnected {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function safeMint(address _to,uint256 tokenID,string memory uri) external ;
        /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function getTokenId(address _to) external view returns(uint[] memory);
}