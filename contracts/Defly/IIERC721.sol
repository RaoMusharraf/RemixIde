// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IIERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function safeMint(address to, string memory uri,uint256 price ,uint8 typ) external ;
}