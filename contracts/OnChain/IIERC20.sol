// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IIERC20 {

     /**
     * @dev Returns the name of token in existence.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of token in existence.
     */
    function symbol() external view returns (string memory);

}