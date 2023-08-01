// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CallerContract {
    IERC20 public usdtToken;
    address public targetContract; // Address of the contract you want to approve (spender)

    constructor(address _usdtToken, address _targetContract) {
        usdtToken = IERC20(_usdtToken);
        targetContract = _targetContract;
    }

    function approveTargetContract(uint256 amount) external {
        // Call the approve function of the token contract
        usdtToken.approve(targetContract, amount);
    }
}