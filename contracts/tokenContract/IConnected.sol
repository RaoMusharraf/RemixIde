// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IConnected {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function approve(address spender,uint256 amount) external ;
    function increaseAllowance(address spender,uint256 amount) external;
}