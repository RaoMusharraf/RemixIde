// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IIERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function safeMint(address to, string memory uri) external view returns (uint256 balance);
}