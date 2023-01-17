// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IIERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function safeMint(address _to,uint256 tokenID,string memory uri) external ;
}