// contracts/Token.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Migration is Ownable{

    using SafeERC20 for IERC20;
    address OLDERC20Address;
    address NEWERC20Address;

    mapping(address => uint256) public Tokens;
    constructor(address OLDERC20,address NEWERC20) {
        OLDERC20Address = OLDERC20;
        NEWERC20Address = NEWERC20;
    }
    function AdminAddToken(uint256 _amount) public onlyOwner {
        Tokens[msg.sender] += _amount;
        IERC20(NEWERC20Address).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }
    function MigrateTokens(uint256 amount) public {
        require(IERC20(OLDERC20Address).balanceOf(msg.sender) >= amount,"Insufficient Fund");
        IERC20(OLDERC20Address).safeTransferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            amount
        );
        IERC20(NEWERC20Address).transfer(
            msg.sender,
            amount
        );
    }
}