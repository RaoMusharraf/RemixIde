// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/**
 * @dev Required interface of an ISwap compliant contract.
 */
interface ISwap {
    function swapExactInputSingle(uint24 poolFee,uint256 amountIn,address FROG,address WETH,address Receiver) external returns (uint256 amountOut);
}