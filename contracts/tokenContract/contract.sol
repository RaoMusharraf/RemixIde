// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDTTransferContract {
    IERC20 public usdtToken;
    mapping(address => uint256) public balances;

    constructor(address _usdtToken) {
        usdtToken = IERC20(_usdtToken);
    }

    function depositUSDT(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        usdtToken.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
    }

    function withdrawUSDT(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        usdtToken.transfer(msg.sender, amount);
    }
    function getContractUSDTBalance() external view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }
}
