// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20FT is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") {}

    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount *1000000000);
    }
}
