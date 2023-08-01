// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyContract {
    IERC20 public tokenContract;
    address public owner;

    constructor(address _tokenContract) {
        tokenContract = IERC20(_tokenContract);
        owner = msg.sender;
    }

    // Function for the token holder to approve allowance for this contract
    function approveAllowance(uint256 amount) external {
        // Ensure only the token holder can approve allowance for their tokens
        require(msg.sender == owner, "Only the token holder can approve allowance");

        // Approve allowance for this contract to spend the specified amount of tokens
        tokenContract.approve(address(this), amount);
    }

    // Function to perform a transaction that requires allowance
    function performTransaction(uint256 amount) external {
        address tokenHolder = msg.sender;

        // Check if the contract has sufficient allowance
        require(tokenContract.allowance(tokenHolder, address(this)) >= amount, "Insufficient allowance");

        // Perform the transaction using the ERC20 token transferFrom function
        tokenContract.transferFrom(tokenHolder, owner, amount);

        // Perform other logic here
    }
}
